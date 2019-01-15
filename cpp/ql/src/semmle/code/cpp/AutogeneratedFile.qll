import semmle.code.cpp.Comments
import semmle.code.cpp.File
import semmle.code.cpp.Preprocessor

/**
 * Holds if comment `c` indicates that it might be in an auto-generated file, for
 * example because it contains the text "auto-generated by".
 */
private predicate autogeneratedComment(Comment c) {
  // ?s = include newlines in anything (`.`)
  // ?i = ignore case
  c.getContents().regexpMatch("(?si).*(" +

    // auto-generated, automatically generated etc.
    "(auto[\\w-]*\\s*?generated)|" +

    // generated by (at beginning of sentence)
    "([^a-z\\s\\*\\r\\n][\\s\\*\\r\\n]*(generated by)[^a-z])|" +

    // generated file
    "(generated file)|" +

    // file [is] generated
    "(file( is)? generated)|" +

    // changes made in this file will be lost
    "(changes made in this file will be lost)|" +
  
    // do not edit/modify
    "(do(n't|nt| not) (edit|modify))" +

  ").*")
}

/**
 * Holds if the file contains `#line` pragmas that refer to a different file.
 * For example, in `parser.c` a pragma `#line 1 "parser.rl"`.
 * Such pragmas usually indicate that the file was automatically generated.
 */
predicate hasPragmaDifferentFile(File f) {
  exists (PreprocessorLine pl, string s |
    pl.getFile() = f and
    pl.getHead().splitAt(" ", 1) = s and /* Zero index is line number, one index is file reference */
    not ("\"" + f.getAbsolutePath() + "\"" = s) and
    not ("\"" + f.getRelativePath() + "\"" = s) and
    not ("\"" + f.getBaseName() + "\"" = s)
  )
}

/**
 * The line where the first comment in file `f` begins (maximum of 5).  This allows
 * us to skip past any preprocessor logic or similar code before the first comment.
 */
private int fileFirstComment(File f) {
  result = min(int line |
    exists(Comment c |
      c.getFile() = f and
      c.getLocation().getStartLine() = line and
      line < 5
    )
  ).minimum(5)
}

/**
 * The line where the initial comments of file `f` end.  This is just before the
 * first bit of code, excluding anything skipped over by `fileFirstComment`.
 */
private int fileHeaderLimit(File f) {
  exists(int fc |
    fc = fileFirstComment(f) and
    result = min(int line |
      exists(DeclarationEntry de, Location l |
        l = de.getLocation() and
        l.getFile() = f and
        line = l.getStartLine() - 1 and
        line > fc
      ) or exists(PreprocessorDirective pd, Location l |
        l = pd.getLocation() and
        l.getFile() = f and
        line = l.getStartLine() - 1 and
        line > fc
      ) or exists(NamespaceDeclarationEntry nde, Location l |
        l = nde.getLocation() and
        l.getFile() = f and
        line = l.getStartLine() - 1 and
        line > fc
      ) or line = f.getMetrics().getNumberOfLines()
    )
  )
}

/**
 * Holds if the file is probably an autogenerated file.
 *
 * A file is probably autogenerated if either of the following heuristics
 * hold:
 *   1. There is a comment in the start of the file that matches
 *      'autogenerated', 'generated by', or a similar phrase.
 *   2. There is a `#line` directive referring to a different file.
 */
class AutogeneratedFile extends File {
  cached AutogeneratedFile() {
    autogeneratedComment(
      concat(Comment c |
        c.getFile() = this and
        c.getLocation().getStartLine() <= fileHeaderLimit(this) |
        c.getContents() order by c.getLocation().getStartLine()
      )
    ) or
    hasPragmaDifferentFile(this)
  }
}
