import * as ts from "./typescript";

interface AugmentedSymbol extends ts.Symbol {
  parent?: AugmentedSymbol;

  /** Cache of our own symbol ID. */
  $id?: number;
}

interface AugmentedType extends ts.Type {
  /**
   * An internal property for predefined types, such as "true", "false", and "object".
   */
  intrinsicName?: string;
}

function isTypeReference(type: ts.Type): type is ts.TypeReference {
  return (type.flags & ts.TypeFlags.Object) !== 0 &&
      ((type as ts.ObjectType).objectFlags & ts.ObjectFlags.Reference) !== 0;
}

function isTypeVariable(type: ts.Type): type is ts.TypeVariable {
  return (type.flags & ts.TypeFlags.TypeVariable) !== 0;
}

/**
 * Returns `true` if the properties of the given type can safely be extracted
 * without restricting expansion depth.
 *
 * This predicate is very approximate, and considers all unions, intersections,
 * named types, and mapped types as potentially unsafe.
 */
function isTypeAlwaysSafeToExpand(type: ts.Type): boolean {
  let flags = type.flags;
  if (flags & ts.TypeFlags.UnionOrIntersection) {
    return false;
  }
  if (flags & ts.TypeFlags.Object) {
    let objectType = type as ts.ObjectType;
    let objectFlags = objectType.objectFlags;
    if (objectFlags & (ts.ObjectFlags.Reference | ts.ObjectFlags.Mapped)) {
      return false;
    }
  }
  return true;
}

/**
 * If `type` is a `this` type, returns the enclosing type.
 * Otherwise returns `null`.
 */
function getEnclosingTypeOfThisType(type: ts.TypeVariable): ts.TypeReference {
  // A 'this' type is an implicit type parameter to a class or interface.
  // The type parameter itself doesn't have any good indicator of being a 'this' type,
  // but we can get it like this:
  // - the upper bound of the 'this' type parameter is always the enclosing type
  // - the enclosing type knows its own 'this' type.
  let bound = type.getConstraint();
  if (bound == null) return null;
  let target = (bound as ts.TypeReference).target; // undefined if not a TypeReference
  if (target == null) return null;
  return (target.thisType === type) ? target : null;
}

const typeDefinitionSymbols = ts.SymbolFlags.Class | ts.SymbolFlags.Interface |
      ts.SymbolFlags.TypeAlias | ts.SymbolFlags.EnumMember | ts.SymbolFlags.Enum;

/** Returns true if the given symbol refers to a type definition. */
function isTypeDefinitionSymbol(symbol: ts.Symbol) {
  return (symbol.flags & typeDefinitionSymbols) !== 0;
}

/** Gets the nearest enclosing block statement, function body, module body, or top-level. */
function getEnclosingBlock(node: ts.Node) {
  while (true) {
    if (node == null) return null;
    if (ts.isSourceFile(node) || ts.isFunctionLike(node) || ts.isBlock(node) || ts.isModuleBlock(node)) return node;
    node = node.parent;
  }
}

const typeofSymbols = ts.SymbolFlags.Class | ts.SymbolFlags.Namespace |
  ts.SymbolFlags.Module | ts.SymbolFlags.Enum | ts.SymbolFlags.EnumMember;

/**
 * Returns true if the given symbol refers to a value that we consider
 * a valid target for a `typeof` type.
 */
function isTypeofCandidateSymbol(symbol: ts.Symbol) {
  return (symbol.flags & typeofSymbols) !== 0;
}

const signatureKinds = [ts.SignatureKind.Call, ts.SignatureKind.Construct];

/**
 * Encodes property lookup tuples `(baseType, name, property)` as three
 * staggered arrays.
 */
interface PropertyLookupTable {
  baseTypes: number[];
  names: string[];
  propertyTypes: number[];
}

/**
 * Encodes type signature tuples `(baseType, kind, index, signature)` as four
 * staggered arrays.
 */
interface SignatureTable {
  baseTypes: number[];
  kinds: ts.SignatureKind[];
  indices: number[];
  signatures: number[];
}

/**
 * Enodes `(baseType, propertyType)` tuples as two staggered arrays.
 *
 * The index key type is not stored in the table - there are separate tables
 * for number and string index signatures.
 *
 * For example, the `(Foo, T)` tuple would be extracted from this sample:
 * ```
 * interface Foo {
 *   [x: string]: T;
 * }
 * ```
 */
interface IndexerTable {
  baseTypes: number[];
  propertyTypes: number[];
}

/**
 * Encodes `(symbol, name)` pairs as two staggered arrays.
 *
 * In general, a table may associate multiple names with a given symbol.
 */
interface SymbolNameTable {
  symbols: number[];
  names: string[];
}

/**
 * Encodes `(symbol, baseTypeSymbol)` pairs as two staggered arrays.
 *
 * Such a pair associates the canonical name of a type with the canonical name
 * of one of its base types.
 */
interface BaseTypeTable {
  symbols: number[];
  baseTypeSymbols: number[];
}

/**
 * Encodes `(symbol, selfType)` pairs as two staggered arrays.
 *
 * Such a pair associates the canonical name of a type with the self-type of
 * that type definition. (e.g `Array` with `Array<T>`).
 */
interface SelfTypeTable {
  symbols: number[];
  selfTypes: number[];
}

/**
 * Denotes whether a type is currently in the worklist ("pending") and whether
 * it was discovered in shallow or full context.
 *
 * Types can be discovered in one of two different contexts:
 * - Full context:
 *   Any type that is the type of an AST node, or is reachable through members of
 *   such a type, without going through an expansive type.
 * - Shallow context:
 *   Any type that is reachable through the members of an expansive type,
 *   without following any type references after that.
 *
 * For example:
 * ```
 * interface Expansive<T> {
 *   expand: Expansive<{x: T}>;
 *   foo: { bar: T };
 * }
 * let instance: Expansive<number>;
 * ```
 * The type `Expansive<number>` is discovered in full context, but as it is expansive,
 * its members are only discovered in shallow context.
 *
 * This means `Expansive<{x: number}>` becomes a stub type, a type that has an entity in
 * the database, but appears to have no members.
 *
 * The type `{ bar: number }` is also discovered in shallow context, but because it is
 * an "inline type" (not a reference) its members are extracted anyway (in shallow context),
 * and will thus appear to have the `bar` property of type `number`.
 */
const enum TypeExtractionState {
  /**
   * The type is in the worklist and was discovered in shallow context.
   */
  PendingShallow,

  /**
   * The type has been extracted as a shallow type.
   *
   * It may later transition to `PendingFull` if it is found that full extraction is warranted.
   */
  DoneShallow,

  /**
   * The type is in the worklist and is pending full extraction.
   */
  PendingFull,

  /**
   * The type has been fully extracted.
   */
  DoneFull,
}

/**
 * Generates canonical IDs and serialized representations of types.
 */
export class TypeTable {
  /**
   * Maps type strings to type IDs. The types must be inserted in order,
   * so the `n`th type has ID `n`.
   *
   * A type string is a `;`-separated string consisting of:
   * - a tag string such as `union` or `reference`,
   * - optionally a symbol ID or kind-specific data (depends on the tag),
   * - IDs of child types.
   *
   * Type strings serve a dual purpose:
   * - Canonicalizing types. Two type objects with the same type string are considered identical.
   * - Extracting types. The Java-part of the extractor parses type strings to extract data about the type.
   */
  private typeIds: Map<string, number> = new Map();
  private typeToStringValues: string[] = [];
  private typeChecker: ts.TypeChecker = null;

  /**
   * Needed for TypeChecker.getTypeOfSymbolAtLocation when we don't care about the location.
   * There is no way to get the type of a symbol without providing a location, though.
   */
  private arbitraryAstNode: ts.Node = null;

  /**
   * Maps symbol strings to to symbol IDs. The symbols must be inserted in order,
   * so the `n`th symbol has ID `n`.
   *
   * A symbol string is a `;`-separated string consisting of:
   * - a tag string, `root`, `member`, or `other`,
   * - an empty string or a `file:pos` string to distinguish this from symbols with other lexical roots,
   * - the ID of the parent symbol, or an empty string if this is a root symbol,
   * - the unqualified name of the symbol.
   *
   * Symbol strings serve the same dual purpose as type strings (see `typeIds`).
   */
  private symbolIds: Map<string, number> = new Map();

  /**
   * Maps file names to IDs unique for that file name.
   *
   * Used to generate short `file:pos` strings in symbol strings.
   */
  private fileIds: Map<String, number> = new Map();

  /**
   * Maps signature strings to signature IDs. The signatures must be inserted in order,
   * so the `n`th signature has ID `n`.
   *
   * A signature string is a `;`-separated string consisting of:
   * - a `ts.SignatureKind` value (i.e. the value 0 or 1)
   * - number of type parameters
   * - number of required parameters
   * - ID of the return type
   * - interleaved names and bounds (type IDs) of type parameters
   * - interleaved names and type IDs of parameters
   */
  private signatureIds: Map<String, number> = new Map();

  private signatureToStringValues: string[] = [];

  private propertyLookups: PropertyLookupTable = {
    baseTypes: [],
    names: [],
    propertyTypes: [],
  };

  private signatureMappings: SignatureTable = {
    baseTypes: [],
    kinds: [],
    indices: [],
    signatures: []
  };

  private numberIndexTypes: IndexerTable = {
    baseTypes: [],
    propertyTypes: [],
  };

  private stringIndexTypes: IndexerTable = {
    baseTypes: [],
    propertyTypes: [],
  };

  private buildTypeWorklist: [ts.Type, number][] = [];

  private expansiveTypes: Map<number, boolean> = new Map();

  private moduleMappings: SymbolNameTable = {
    symbols: [],
    names: [],
  };
  private globalMappings: SymbolNameTable = {
    symbols: [],
    names: [],
  };

  private baseTypes: BaseTypeTable = {
    symbols: [],
    baseTypeSymbols: [],
  };

  private selfTypes: SelfTypeTable = {
    symbols: [],
    selfTypes: [],
  };

  /**
   * When true, newly discovered types should be extracted as "shallow" types in order
   * to prevent expansive types from unfolding into infinitely many types.
   *
   * @see TypeExtractionState
   */
  private isInShallowTypeContext = false;

  /**
   * Maps a type ID to the extraction state of that type.
   */
  private typeExtractionState: TypeExtractionState[] = [];

  /**
   * Number of types we are currently in the process of flattening to a type string.
   */
  private typeRecursionDepth = 0;

  /**
   * If set to true, all types are considered expansive.
   */
  public restrictedExpansion = false;

  /**
   * Called when a new compiler instance has started.
   */
  public setProgram(program: ts.Program) {
    this.typeChecker = program.getTypeChecker();
    this.arbitraryAstNode = program.getSourceFiles()[0];
  }

  /**
   * Called when the compiler instance should be relased from memory.
   *
   * This can happen because we are done with a project, or because the
   * compiler instance needs to be rebooted.
   */
  public releaseProgram() {
    this.typeChecker = null;
    this.arbitraryAstNode = null;
  }

  /**
   * Gets the canonical ID for the given type, generating a fresh ID if necessary.
   */
  public buildType(type: ts.Type): number | null {
    this.isInShallowTypeContext = false;
    let id = this.getId(type);
    this.iterateBuildTypeWorklist();
    if (id == null) return null;
    return id;
  }

  /**
   * Gets the canonical ID for the given type, generating a fresh ID if necessary.
   *
   * Returns `null` if we do not support extraction of this type.
   */
  public getId(type: ts.Type): number | null {
    if (this.typeRecursionDepth > 100) {
      // Ignore infinitely nested anonymous types, such as `{x: {x: {x: ... }}}`.
      // Such a type can't be written directly with TypeScript syntax (as it would need to be named),
      // but it can occur rarely as a result of type inference.
      return null;
    }
    // Replace very long string literal types with `string`.
    if ((type.flags & ts.TypeFlags.StringLiteral) && ((type as ts.LiteralType).value as string).length > 30) {
      type = this.typeChecker.getBaseTypeOfLiteralType(type);
    }
    ++this.typeRecursionDepth;
    let content = this.getTypeString(type);
    --this.typeRecursionDepth;
    if (content == null) return null; // Type not supported.
    let id = this.typeIds.get(content);
    if (id == null) {
      let stringValue = this.stringifyType(type);
      if (stringValue == null) {
        return null; // Type not supported.
      }
      id = this.typeIds.size;
      this.typeIds.set(content, id);
      this.typeToStringValues.push(stringValue);
      this.buildTypeWorklist.push([type, id]);
      this.typeExtractionState.push(
        this.isInShallowTypeContext ? TypeExtractionState.PendingShallow : TypeExtractionState.PendingFull);
      // If the type is the self-type for a named type (not a generic instantiation of it),
      // emit the self-type binding for that type.
      if (content.startsWith("reference;") && !(isTypeReference(type) && type.target !== type)) {
        this.selfTypes.symbols.push(this.getSymbolId(type.aliasSymbol || type.symbol));
        this.selfTypes.selfTypes.push(id);
      }
    } else if (!this.isInShallowTypeContext) {
      // If the type was previously marked as shallow, promote it to full,
      // and put it back in the worklist if necessary.
      let state = this.typeExtractionState[id];
      if (state === TypeExtractionState.PendingShallow) {
        this.typeExtractionState[id] = TypeExtractionState.PendingFull;
      } else if (state === TypeExtractionState.DoneShallow) {
        this.typeExtractionState[id] = TypeExtractionState.PendingFull;
        this.buildTypeWorklist.push([type, id]);
      }
    }
    return id;
  }

  private stringifyType(type: ts.Type): string {
    let toStringValue: string;
    // Some types can't be stringified. Just discard the type if we can't stringify it.
    try {
      toStringValue = this.typeChecker.typeToString(type);
    } catch (e) {
      console.warn("Recovered from a compiler crash while stringifying a type. Discarding the type.");
      console.warn(e.stack);
      return null;
    }
    if (toStringValue.length > 50) {
      return toStringValue.substring(0, 47) + "...";
    } else {
      return toStringValue;
    }
  }

  private stringifySignature(signature: ts.Signature, kind: ts.SignatureKind) {
    let toStringValue: string;
    // Some types can't be stringified. Just discard the type if we can't stringify it.
    try {
      toStringValue =
          this.typeChecker.signatureToString(signature, signature.declaration, ts.TypeFormatFlags.None, kind);
    } catch (e) {
      console.warn("Recovered from a compiler crash while stringifying a signature. Discarding the signature.");
      console.warn(e.stack);
      return null;
    }
    if (toStringValue.length > 70) {
      return toStringValue.substring(0, 69) + "...";
    } else {
      return toStringValue;
    }
  }

  /**
   * Gets a string representing the kind and contents of the given type.
   */
  private getTypeString(type: AugmentedType): string | null {
    // Reference to a type alias.
    if (type.aliasSymbol != null) {
      let tag = "reference;" + this.getSymbolId(type.aliasSymbol);
      return type.aliasTypeArguments == null
          ? tag
          : this.makeTypeStringVector(tag, type.aliasTypeArguments);
    }
    let flags = type.flags;
    let objectFlags = (flags & ts.TypeFlags.Object) && (type as ts.ObjectType).objectFlags;
    let symbol: AugmentedSymbol = type.symbol;
    // Type that contains a reference to something.
    if (symbol != null) {
      // Possibly parameterized type.
      if (isTypeReference(type)) {
        let tag = "reference;" + this.getSymbolId(symbol);
        return this.makeTypeStringVectorFromTypeReferenceArguments(tag, type);
      }
      // Reference to a type variable.
      if (flags & ts.TypeFlags.TypeVariable) {
        let enclosingType = getEnclosingTypeOfThisType(type);
        if (enclosingType != null) {
          return "this;" + this.getId(enclosingType);
        } else if (symbol.parent == null) {
          // The type variable is bound on a call signature. Only extract it by name.
          return "lextypevar;" + symbol.name;
        } else {
          return "typevar;" + this.getSymbolId(symbol);
        }
      }
      // Recognize types of form `typeof X` where `X` is a class, namespace, module, or enum.
      // The TypeScript API has no explicit tag for `typeof` types. They can be recognized
      // as anonymous object types that have a symbol (i.e. a "named anonymous type").
      if ((objectFlags & ts.ObjectFlags.Anonymous) && isTypeofCandidateSymbol(symbol)) {
        return "typeof;" + this.getSymbolId(symbol);
      }
      // Reference to a named type.
      // Must occur after the `typeof` case to avoid matching `typeof C` as the type `C`.
      if (isTypeDefinitionSymbol(symbol)) {
        return "reference;" + this.getSymbolId(type.symbol);
      }
    }
    if (flags === ts.TypeFlags.Any) {
      return "any";
    }
    if (flags === ts.TypeFlags.String) {
      return "string";
    }
    if (flags === ts.TypeFlags.Number) {
      return "number";
    }
    if (flags === ts.TypeFlags.Void) {
      return "void";
    }
    if (flags === ts.TypeFlags.Never) {
      return "never";
    }
    if (flags === ts.TypeFlags.BigInt) {
      return "bigint";
    }
    if (flags & ts.TypeFlags.Null) {
      return "null";
    }
    if (flags & ts.TypeFlags.Undefined) {
      return "undefined";
    }
    if (flags === ts.TypeFlags.ESSymbol) {
      return "plainsymbol";
    }
    if (flags & ts.TypeFlags.Unknown) {
      return "unknown";
    }
    if (flags === ts.TypeFlags.UniqueESSymbol) {
      return "uniquesymbol;" + this.getSymbolId((type as ts.UniqueESSymbolType).symbol);
    }
    if (flags === ts.TypeFlags.NonPrimitive && type.intrinsicName === "object") {
      return "objectkeyword";
    }
    // Note that TypeScript represents the `boolean` type as `true|false`.
    if (flags === ts.TypeFlags.BooleanLiteral) {
      // There is no public API to distinguish true and false.
      // We rely on the internal property `intrinsicName`, which
      // should be either "true" or "false" here.
      return type.intrinsicName;
    }
    if (flags & ts.TypeFlags.NumberLiteral) {
      return "numlit;" + (type as ts.LiteralType).value;
    }
    if (flags & ts.TypeFlags.StringLiteral) {
      return "strlit;" + (type as ts.LiteralType).value;
    }
    if (flags & ts.TypeFlags.BigIntLiteral) {
      let literalType = type as ts.LiteralType;
      let value = literalType.value as ts.PseudoBigInt;
      return "bigintlit;" + (value.negative ? "-" : "") + value.base10Value;
    }
    if (flags & ts.TypeFlags.Union) {
      let unionType = type as ts.UnionType;
      if (unionType.types.length === 0) {
        // We ignore malformed types like unions and intersections without any operands.
        // These trigger an assertion failure in `typeToString` - presumably because they
        // cannot be written using TypeScript syntax - so we ignore them entirely.
        return null;
      }
      return this.makeTypeStringVector("union", unionType.types);
    }
    if (flags & ts.TypeFlags.Intersection) {
      let intersectionType = type as ts.IntersectionType;
      if (intersectionType.types.length === 0) {
        return null; // Ignore malformed type.
      }
      return this.makeTypeStringVector("intersection", intersectionType.types);
    }
    if (isTypeReference(type) && (type.target.objectFlags & ts.ObjectFlags.Tuple)) {
      // Encode the minimum length and presence of rest element in the first two parts of the type string.
      // Handle the absence of `minLength` and `hasRestElement` to be compatible with pre-3.0 compiler versions.
      let tupleReference = type as ts.TupleTypeReference;
      let tupleType = tupleReference.target;
      let minLength = tupleType.minLength != null
          ? tupleType.minLength
          : tupleReference.typeArguments.length;
      let hasRestElement = tupleType.hasRestElement ? 't' : 'f';
      let prefix = `tuple;${minLength};${hasRestElement}`;
      return this.makeTypeStringVectorFromTypeReferenceArguments(prefix, type);
    }
    if (objectFlags & ts.ObjectFlags.Anonymous) {
      return this.makeStructuralTypeVector("object;", type as ts.ObjectType);
    }
    return null;
  }

  /**
   * Gets the canonical ID for the given symbol.
   *
   * Note that this may be called with symbols from different compiler instantiations,
   * and it should return the same ID for symbols that logically refer to the same thing.
   */
  public getSymbolId(symbol: AugmentedSymbol): number {
    if (symbol.flags & ts.SymbolFlags.Alias) {
      symbol = this.typeChecker.getAliasedSymbol(symbol);
    }
    // We cache the symbol ID to avoid rebuilding long symbol strings.
    let id = symbol.$id;
    if (id != null) return id;
    let content = this.getSymbolString(symbol);
    id = this.symbolIds.get(content);
    if (id != null) {
      // The ID was determined in a previous compiler instantiation.
      return symbol.$id = id;
    }
    if (id == null) {
      id = this.symbolIds.size;
      this.symbolIds.set(content, id);
      symbol.$id = id;

      // Associate names with global symbols.
      if (this.isGlobalSymbol(symbol)) {
        this.addGlobalMapping(id, symbol.name);
      }

      // Associate type names with their base type names.
      this.extractSymbolBaseTypes(symbol, id);
    }
    return id;
  }

  /** Returns true if the given symbol represents a name in the global scope. */
  private isGlobalSymbol(symbol: AugmentedSymbol): boolean {
    let parent = symbol.parent;
    if (parent != null) {
      if (parent.escapedName === ts.InternalSymbolName.Global) {
        return true; // Symbol declared in a global augmentation block.
      }
      return false; // Symbol is not a root.
    }
    if (symbol.declarations == null || symbol.declarations.length === 0) return false;
    let declaration = symbol.declarations[0];
    let block = getEnclosingBlock(declaration);
    if (ts.isSourceFile(block) && !this.isModuleSourceFile(block)) {
      return true; // Symbol is declared at the top-level of a non-module file.
    }
    return false;
  }

  /** Returns true if the given source file defines a module. */
  private isModuleSourceFile(file: ts.SourceFile) {
    // This is not directly exposed, but a reliable indicator seems to be whether
    // the file has a symbol.
    return this.typeChecker.getSymbolAtLocation(file) != null;
  }

  /**
   * Gets a unique string for the given symbol.
   */
  private getSymbolString(symbol: AugmentedSymbol): string {
    let parent = symbol.parent;
    if (parent == null || parent.escapedName === ts.InternalSymbolName.Global) {
      return "root;" + this.getSymbolDeclarationString(symbol) + ";;" + symbol.name;
    } else if (parent.exports != null && parent.exports.get(symbol.escapedName) === symbol) {
      return "member;;" + this.getSymbolId(parent) + ";" + symbol.name;
    } else {
      return "other;" + this.getSymbolDeclarationString(symbol) + ";" + this.getSymbolId(parent) + ";" + symbol.name;
    }
  }

  /**
   * Gets a string that distinguishes the given symbol from symbols with different
   * lexical roots, or an empty string if the symbol is not a lexical root.
   */
  private getSymbolDeclarationString(symbol: AugmentedSymbol): string {
    if (symbol.declarations == null || symbol.declarations.length === 0) {
      return "";
    }
    let decl = symbol.declarations[0];
    if (ts.isSourceFile(decl)) return "";
    return this.getFileId(decl.getSourceFile().fileName) + ":" + decl.pos;
  }

  /**
   * Gets a number unique for the given filename.
   */
  private getFileId(fileName: string): number {
    let id = this.fileIds.get(fileName);
    if (id == null) {
      id = this.fileIds.size;
      this.fileIds.set(fileName, id);
    }
    return id;
  }

  /**
   * Like `makeTypeStringVector` using the type arguments in the given type reference.
   */
  private makeTypeStringVectorFromTypeReferenceArguments(tag: string, type: ts.TypeReference) {
    // There can be an extra type argument at the end, denoting an explicit 'this' type argument.
    // We discard the extra argument in our model.
    let target = type.target;
    if (type.typeArguments == null) return tag;
    if (target.typeParameters != null) {
      return this.makeTypeStringVector(tag, type.typeArguments, target.typeParameters.length);
    } else {
      return this.makeTypeStringVector(tag, type.typeArguments);
    }
  }

  /**
   * Returns the given string with the IDs of the given types appended,
   * each separated by `;`.
   */
  private makeTypeStringVector(tag: string, types: ReadonlyArray<ts.Type>, length = types.length): string | null {
    let hash = tag;
    for (let i = 0; i < length; ++i) {
      let id = this.getId(types[i]);
      if (id == null) return null;
      hash += ";" + id;
    }
    return hash;
  }

  /**
   * Returns a type string consisting of all the members of the given type.
   *
   * This must only be called for anonymous object types, as the type string for this
   * type could otherwise depend on itself recursively.
   */
  private makeStructuralTypeVector(tag: string, type: ts.ObjectType): string | null {
    let hash = tag;
    for (let property of type.getProperties()) {
      let propertyType = this.typeChecker.getTypeOfSymbolAtLocation(property, this.arbitraryAstNode);
      if (propertyType == null) return null;
      let propertyTypeId = this.getId(propertyType);
      if (propertyTypeId == null) return null;
      hash += ";p" + this.getSymbolId(property) + ';' + propertyTypeId;
    }
    for (let kind of signatureKinds) {
      for (let signature of this.typeChecker.getSignaturesOfType(type, kind)) {
        let id = this.getSignatureId(kind, signature);
        if (id == null) return null;
        hash += ";c" + id;
      }
    }
    let indexType = type.getStringIndexType();
    if (indexType != null) {
      let indexTypeId = this.getId(indexType);
      if (indexTypeId == null) return null;
      hash += ";s" + indexTypeId;
    }
    indexType = type.getNumberIndexType();
    if (indexType != null) {
      let indexTypeId = this.getId(indexType);
      if (indexTypeId == null) return null;
      hash += ";i" + indexTypeId;
    }
    return hash;
  }

  public addModuleMapping(symbolId: number, moduleName: string) {
    this.moduleMappings.symbols.push(symbolId);
    this.moduleMappings.names.push(moduleName);
  }

  public addGlobalMapping(symbolId: number, globalName: string) {
    this.globalMappings.symbols.push(symbolId);
    this.globalMappings.names.push(globalName);
  }

  public getTypeTableJson(): object {
    return {
      typeStrings: Array.from(this.typeIds.keys()),
      typeToStringValues: this.typeToStringValues,
      propertyLookups: this.propertyLookups,
      symbolStrings: Array.from(this.symbolIds.keys()),
      moduleMappings: this.moduleMappings,
      globalMappings: this.globalMappings,
      signatureStrings: Array.from(this.signatureIds.keys()),
      signatureMappings: this.signatureMappings,
      signatureToStringValues: this.signatureToStringValues,
      numberIndexTypes: this.numberIndexTypes,
      stringIndexTypes: this.stringIndexTypes,
      baseTypes: this.baseTypes,
      selfTypes: this.selfTypes,
    };
  }

  /**
   * Extracts the deep property and signature graph of recently discovered types.
   *
   * Types are added to the worklist when they are first assigned an ID,
   * which happen transparently during property extraction and expansiveness checks.
   */
  private iterateBuildTypeWorklist() {
    let worklist = this.buildTypeWorklist;
    let typeExtractionState = this.typeExtractionState;
    while (worklist.length > 0) {
      let [type, id] = worklist.pop();
      let isShallowContext = typeExtractionState[id] === TypeExtractionState.PendingShallow;
      if (isShallowContext && !isTypeAlwaysSafeToExpand(type)) {
        typeExtractionState[id] = TypeExtractionState.DoneShallow;
      } else {
        typeExtractionState[id] = TypeExtractionState.DoneFull;
        this.isInShallowTypeContext = isShallowContext || this.isExpansiveTypeReference(type);
        this.extractProperties(type, id);
        this.extractSignatures(type, id);
        this.extractIndexers(type, id);
      }
    }
    this.isInShallowTypeContext = false;
  }

  private extractProperties(type: ts.Type, id: number) {
    for (let symbol of type.getProperties()) {
      let propertyType = this.typeChecker.getTypeOfSymbolAtLocation(symbol, this.arbitraryAstNode);
      if (propertyType == null) continue;
      let propertyTypeId = this.getId(propertyType);
      if (propertyTypeId == null) continue;
      this.propertyLookups.baseTypes.push(id);
      this.propertyLookups.names.push(symbol.name);
      this.propertyLookups.propertyTypes.push(propertyTypeId);
    }
  }

  /**
   * Returns a unique ID for the given call/construct signature.
   */
  public getSignatureId(kind: ts.SignatureKind, signature: ts.Signature): number {
    let content = this.getSignatureString(kind, signature);
    if (content == null) {
      return null;
    }
    let id = this.signatureIds.get(content);
    if (id == null) {
      let stringValue = this.stringifySignature(signature, kind);
      if (stringValue == null) {
        return null; // Not supported.
      }
      id = this.signatureIds.size;
      this.signatureIds.set(content, id);
      this.signatureToStringValues.push(stringValue);
    }
    return id;
  }

  /**
   * Returns a unique string for the given call/constructor signature.
   */
  private getSignatureString(kind: ts.SignatureKind, signature: ts.Signature): string {
    let parameters = signature.getParameters();
    let numberOfTypeParameters = signature.typeParameters == null
        ? 0
        : signature.typeParameters.length;
    // Count the number of required parameters.
    let requiredParameters = parameters.length;
    for (let i = 0; i < parameters.length; ++i) {
      if (parameters[i].flags & ts.SymbolFlags.Optional) {
        requiredParameters = i;
        break;
      }
    }
    let returnTypeId = this.getId(signature.getReturnType());
    if (returnTypeId == null) {
      return null;
    }
    let tag = `${kind};${numberOfTypeParameters};${requiredParameters};${returnTypeId}`;
    for (let typeParameter of signature.typeParameters || []) {
      tag += ";" + typeParameter.symbol.name;
      let constraint = typeParameter.getConstraint();
      let constraintId: number;
      if (constraint == null || (constraintId = this.getId(constraint)) == null) {
        tag += ";";
      } else {
        tag += ";" + constraintId;
      }
    }
    for (let parameter of parameters) {
      let parameterType = this.typeChecker.getTypeOfSymbolAtLocation(parameter, this.arbitraryAstNode);
      if (parameterType == null) {
        return null;
      }
      let parameterTypeId = this.getId(parameterType);
      if (parameterTypeId == null) {
        return null;
      }
      tag += ';' + parameter.name + ';' + parameterTypeId;
    }
    return tag;
  }

  private extractSignatures(type: ts.Type, id: number) {
    this.extractSignatureList(type, id, ts.SignatureKind.Call, type.getCallSignatures());
    this.extractSignatureList(type, id, ts.SignatureKind.Construct, type.getConstructSignatures());
  }

  private extractSignatureList(type: ts.Type, id: number, kind: ts.SignatureKind, list: ReadonlyArray<ts.Signature>) {
    let index = -1;
    for (let signature of list) {
      ++index;
      let signatureId = this.getSignatureId(kind, signature);
      if (signatureId == null) continue;
      this.signatureMappings.baseTypes.push(id);
      this.signatureMappings.kinds.push(kind);
      this.signatureMappings.indices.push(index);
      this.signatureMappings.signatures.push(signatureId);
    }
  }

  private extractIndexers(type: ts.Type, id: number) {
    this.extractIndexer(id, type.getStringIndexType(), this.stringIndexTypes);
    this.extractIndexer(id, type.getNumberIndexType(), this.numberIndexTypes);
  }

  private extractIndexer(baseType: number, indexType: ts.Type, table: IndexerTable) {
    if (indexType == null) return;
    let indexTypeId = this.getId(indexType);
    if (indexTypeId == null) return;
    table.baseTypes.push(baseType);
    table.propertyTypes.push(indexTypeId);
  }

  /**
   * If the given symbol represents a type name, extracts its base type names.
   *
   * Base types are only extracted at the level of names, since the type arguments
   * of a base type are not generally made available by the TypeScript API.
   *
   * For example, given these interfaces:
   * ```
   * interface Base<T> { x: T }
   * interface Sub<S> extends Base<S[]> {}
   * ```
   * a true base type of `Sub<number>` would be `Base<number[]>`, but all we can
   * get from the compiler is just `Base<S[]>` with no indication of what `S` should be.
   */
  private extractSymbolBaseTypes(symbol: ts.Symbol, symbolId: number) {
    for (let decl of symbol.declarations || []) {
      if (ts.isClassLike(decl) || ts.isInterfaceDeclaration(decl)) {
        for (let heritage of decl.heritageClauses || []) {
          for (let typeExpr of heritage.types) {
            let superType = this.typeChecker.getTypeFromTypeNode(typeExpr);
            if (superType == null) continue;
            let baseTypeSymbol = superType.symbol;
            if (baseTypeSymbol == null) continue;
            this.baseTypes.symbols.push(symbolId);
            this.baseTypes.baseTypeSymbols.push(this.getSymbolId(baseTypeSymbol));
          }
        }
      }
    }
  }

  /**
   * If `type` is a generic instantiation of a type, returns the
   * generic self-type for that type, otherwise `null`.
   *
   * For example, `Promise<string>` maps to `Promise<T>`, where
   * `T` is the type parameter declared on the `Promise` interface.
   */
  private getSelfType(type: ts.Type): ts.TypeReference {
    if (isTypeReference(type) && type.typeArguments != null && type.typeArguments.length > 0) {
      return type.target;
    }
    return null;
  }

  /**
   * True if the given type is a reference to a type that is part of an expansive cycle, which
   * we simply call "expansive types".
   *
   * Non-expansive types may still lead into an expansive type, as long as it's not part of
   * the cycle.
   *
   * It is guaranteed that any sequence of property reads on a type will loop back to a previously
   * seen type or a reach a type that is marked as expansive.  That is, this is sufficient to
   * guarantee termination of recursive property traversal.
   */
  private isExpansiveTypeReference(type: ts.Type): boolean {
    if (this.restrictedExpansion) {
      return true;
    }
    let selfType = this.getSelfType(type);
    if (selfType != null) {
      this.checkExpansiveness(selfType);
      let id = this.getId(selfType);
      return this.expansiveTypes.get(id);
    }
    return false;
  }

  /**
   * Checks if the given self-type is an expansive type. The result is stored in `expansiveTypes`.
   *
   * This follows a variant of Tarjan's SCC algorithm on a graph derived from the properties of types.
   *
   * The vertices of the graph are generic "self types", that is, types like `Foo<T>` but not `Foo<number>`.
   * Types without type arguments are not vertices either, as such types can't be part of an expansive cycle.
   *
   * A property S.x with type T implies an edge from S to the self-type of every type referenced in T, whose
   * type arguments contain a type parameter of S.  Moreover, if such a reference contains a deeply nested
   * occurence of a type parameter, e.g. `Foo<Bar<T>>` it is classified as an "expanding" edge
   *
   * For example, this interface:
   *
   *     interface Foo<T> {
   *       x: Bar<Baz<T>>
   *     }
   *
   * implies the following edges:
   *
   *   Foo ==> Bar    (expanding edge)
   *   Foo --> Baz    (neutral edge)
   *
   * If an SCC contains an expanding edge, all its members are classified as expansive types.
   *
   * Suppose we extend the example with the interfaces:
   *
   *     interface Bar<T> {
   *       x: T;
   *     }
   *
   *     interface Baz<T> {
   *       x: Foo<T[]>
   *     }
   *
   * The `Bar` interface implies no edges and the `Baz` interface implies the edge:
   *
   *   Baz ==> Foo    (expanding edge)
   *
   * This creates an expanding cycle, Foo --> Baz ==> Foo, so Foo and Baz are considered
   * expansive, whereas Bar is not.
   */
  private checkExpansiveness(type: ts.TypeReference) {
    // `index`, `lowlink` and `stack` are from Tarjan's algorithm.
    // Note that the type ID cannot be used as `index` because the index must be
    // increasing with the order in which nodes are discovered in the traversal.
    let indexTable = new Map<number, number>();
    let lowlinkTable = new Map<number, number>();
    let indexCounter = 0;
    let stack: number[] = []; // IDs of types on the stack.

    // The expansion depth is the number of expanding edges that were used to
    // reach the given node when it was first discovered.  It is used to detect
    // if the SCC contains an expanding edge.
    // We also abuse this to track whether a node is currently on the stack;
    // as long as the value is non-null, the node is on the stack.
    let expansionDepthTable = new Map<number, number>();

    let typeTable = this;

    search(type, 0);

    function search(type: ts.TypeReference, expansionDepth: number): number | null {
      let id = typeTable.getId(type);
      if (id == null) return null;

      let index = indexTable.get(id);
      if (index != null) { // Seen this node before?
        let initialExpansionDepth = expansionDepthTable.get(id);
        if (initialExpansionDepth == null) {
          return null; // Not on the stack anymore.  Its SCC is already complete.
        }
        if (expansionDepth > initialExpansionDepth) {
          // The type has reached itself using an expansive edge.
          // Mark is at expansive.  The rest of the SCC will be marked when the SCC is complete.
          typeTable.expansiveTypes.set(id, true);
        }
        return index;
      }

      let previousResult = typeTable.expansiveTypes.get(id);
      if (previousResult != null) {
        // This node was classified by a previous call to checkExpansiveness.
        return null;
      }

      index = ++indexCounter;
      indexTable.set(id, index);
      lowlinkTable.set(id, index);
      expansionDepthTable.set(id, expansionDepth);
      let indexOnStack = stack.length;
      stack.push(id);

      for (let symbol of type.getProperties()) {
        let propertyType: ts.Type = typeTable.typeChecker.getTypeOfSymbolAtLocation(symbol, typeTable.arbitraryAstNode);
        if (propertyType == null) continue;
        traverseType(propertyType);
      }

      if (lowlinkTable.get(id) === index) {
        // We have finished an SCC.
        // If any type was marked as expansive, propagate this to the entire SCC.
        let isExpansive = false;
        for (let i = indexOnStack; i < stack.length; ++i) {
          let memberId = stack[i];
          if (typeTable.expansiveTypes.get(memberId) === true) {
            isExpansive = true;
            break;
          }
        }
        for (let i = indexOnStack; i < stack.length; ++i) {
          let memberId = stack[i];
          typeTable.expansiveTypes.set(memberId, isExpansive);
          expansionDepthTable.set(memberId, null); // Mark as not on stack anymore.
        }
        stack.length = indexOnStack; // Pop all SCC nodes from stack.
      }

      return lowlinkTable.get(id);

      /** Indicates if a type contains no type variables, is a type variable, or strictly contains type variables. */
      const enum TypeVarDepth {
        noTypeVar = 0,
        isTypeVar = 1,
        containsTypeVar = 2,
      }

      function traverseType(type: ts.Type): TypeVarDepth {
        if (isTypeVariable(type)) return TypeVarDepth.isTypeVar;
        let depth = TypeVarDepth.noTypeVar;
        typeTable.forEachChildType(type, child => {
          depth = Math.max(depth, traverseType(child));
        });
        if (depth === TypeVarDepth.noTypeVar) {
          // No need to recurse into types that do not reference a type variable.
          return TypeVarDepth.noTypeVar;
        }
        let selfType = typeTable.getSelfType(type);
        if (selfType != null) {
          // A non-expanding reference such as `Foo<T>` should preserve expansion depth,
          // whereas an expanding reference `Foo<T[]>` should increment it.
          visitEdge(selfType, (depth === TypeVarDepth.isTypeVar) ? 0 : 1);
        }
        return TypeVarDepth.containsTypeVar;
      }

      function visitEdge(successor: ts.TypeReference, weight: number) {
        let result = search(successor, expansionDepth + weight);
        if (result == null) return;
        lowlinkTable.set(id, Math.min(lowlinkTable.get(id), result));
      }
    }
  }

  private forEachChildType(type: ts.Type, callback: (type: ts.Type) => void): void {
    // Note: we deliberately do not traverse type aliases here, but the underlying type.
    if (isTypeReference(type)) {
      // Note that this case also handles tuple types, since a tuple type is represented as
      // a reference to a synthetic generic interface.
      if (type.typeArguments != null) {
        type.typeArguments.forEach(callback);
      }
    } else if (type.flags & ts.TypeFlags.UnionOrIntersection) {
      (type as ts.UnionOrIntersectionType).types.forEach(callback);
    } else if (type.flags & ts.TypeFlags.Object) {
      let objectType = type as ts.ObjectType;
      let objectFlags = objectType.objectFlags;
      if (objectFlags & ts.ObjectFlags.Anonymous) {
        // Anonymous interface type like `{ x: number }`.
        for (let symbol of type.getProperties()) {
          let propertyType = this.typeChecker.getTypeOfSymbolAtLocation(symbol, this.arbitraryAstNode);
          if (propertyType == null) continue;
          callback(propertyType);
        }
        for (let signature of type.getCallSignatures()) {
          this.forEachChildTypeOfSignature(signature, callback);
        }
        for (let signature of type.getConstructSignatures()) {
          this.forEachChildTypeOfSignature(signature, callback);
        }
        let stringIndexType = type.getStringIndexType();
        if (stringIndexType != null) {
          callback(stringIndexType);
        }
        let numberIndexType = type.getNumberIndexType();
        if (numberIndexType != null) {
          callback(numberIndexType);
        }
      }
    }
  }

  private forEachChildTypeOfSignature(signature: ts.Signature, callback: (type: ts.Type) => void): void {
    callback(signature.getReturnType());
    for (let parameter of signature.getParameters()) {
      let paramType = this.typeChecker.getTypeOfSymbolAtLocation(parameter, this.arbitraryAstNode);
      if (paramType == null) continue;
      callback(paramType);
    }
    let typeParameters = signature.getTypeParameters();
    if (typeParameters != null) {
      for (let typeParameter of typeParameters) {
        let constraint = typeParameter.getConstraint();
        if (constraint == null) continue;
        callback(constraint);
      }
    }
  }
}
