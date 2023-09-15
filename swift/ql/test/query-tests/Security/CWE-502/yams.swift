// --- stubs ---

class NSObject {
}

struct URL
{
	init?(string: String) {}
}

struct Data {
	struct ReadingOptions : OptionSet { let rawValue: Int }

	init(contentsOf: URL, options: ReadingOptions) throws {}
	init<S>(_ elements: S) {}
}

extension String {
	struct Encoding {
		var rawValue: UInt

		static let utf8 = Encoding(rawValue: 1)
	}

	init(contentsOf: URL) throws {
		let data = ""
		self.init(data)
	}

	func data(using encoding: String.Encoding, allowLossyConversion: Bool = false) -> Data? { return nil }
}

class Resolver {
	internal init() { } // simplified
}

extension Resolver {
	static let `default` = Resolver()
}

class Constructor {
}

extension Constructor {
	static let `default` = Constructor()
}

class Parser {
	enum Encoding: String {
		case utf8
		static var `default`: Encoding = { .utf8 }() // simplified
	}
}

enum Node {
	case scalar(Scalar)
}

extension Node {
	struct Scalar {
	}
}

struct YamlSequence<T> : Sequence, IteratorProtocol {
	func next() -> T? { return nil }
}

class YAMLDecoder {
	typealias Input = Data

	init(encoding: Parser.Encoding = .default) { }

	// slightly simplified
	func decode<T>(_ type: T.Type = T.self, from node: Node, userInfo: [Int: Any] = [:]) throws -> T where T: Decodable { 0 as! T }
	func decode<T>(_ type: T.Type = T.self, from yaml: String, userInfo: [Int: Any] = [:]) throws -> T where T: Decodable { 0 as! T }
	func decode<T>(_ type: T.Type = T.self, from yamlData: Data, userInfo: [Int: Any] = [:]) throws -> T where T: Decodable { 0 as! T }
}

func load_all(
	yaml: String,
	_ resolver: Resolver = .default,
	_ constructor: Constructor = .default,
	_ encoding: Parser.Encoding = .default) throws -> YamlSequence<Any> { YamlSequence<Any>()}
func load(
	yaml: String, _ resolver:
	Resolver = .default,
	_ constructor: Constructor = .default,
	_ encoding: Parser.Encoding = .default) throws -> Any? { nil }
func compose_all(
	yaml: String,
	_ resolver: Resolver = .default,
	_ constructor: Constructor = .default,
	_ encoding: Parser.Encoding = .default) throws -> YamlSequence<Node> { YamlSequence<Node>()}
func compose(
	yaml: String, _ resolver:
	Resolver = .default,
	_ constructor: Constructor = .default,
	_ encoding: Parser.Encoding = .default) throws -> Node? { nil }

class JSONDecoder {
	func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable { return 0 as! T }
}

protocol TopLevelDecoder {
	associatedtype Input

	func decode<T>(_ type: T.Type, from: Self.Input) throws -> T where T: Decodable
}

extension YAMLDecoder : TopLevelDecoder {
	func decode<T>(_ type: T.Type, from: Data) throws -> T where T: Decodable { 0 as! T }
}

enum Publishers {
	struct Map<Upstream, Output> : Publisher where Upstream : Publisher {
		typealias Output = Data // simplified
		typealias Failure = URLError

		func map<T>(_ transform: @escaping (Self.Output) -> T) -> Publishers.Map<Self, T> { return Publishers.Map<Self, T>() }
		func decode<Item, Coder>(type: Item.Type, decoder: Coder) ->
			Publishers.Decode<Self, Item, Coder> where Item: Decodable, Coder: TopLevelDecoder, Self.Output == Coder.Input { return Publishers.Decode<Self, Item, Coder>() }
	}

	struct Decode<Upstream, Output, Coder> : Publisher where Upstream : Publisher, Output : Decodable, Coder : TopLevelDecoder, Upstream.Output == Coder.Input {
		typealias Output = Data // simplified
		typealias Failure = URLError

		func map<T>(_ transform: @escaping (Self.Output) -> T) -> Publishers.Map<Self, T> { return Publishers.Map<Self, T>() }
		func decode<Item, Coder>(type: Item.Type, decoder: Coder) ->
			Publishers.Decode<Self, Item, Coder> where Item: Decodable, Coder: TopLevelDecoder, Self.Output == Coder.Input { return Publishers.Decode<Self, Item, Coder>() }
	}
}

protocol Publisher<Output, Failure> {
	associatedtype Output
	associatedtype Failure

	func map<T>(_ transform: @escaping (Self.Output) -> T) -> Publishers.Map<Self, T>
	func decode<Item, Coder>(type: Item.Type, decoder: Coder) ->
		Publishers.Decode<Self, Item, Coder> where Item: Decodable, Coder: TopLevelDecoder, Self.Output == Coder.Input
	// ...
}

class URLResponse : NSObject {
}

struct URLError {
}

class URLSession {
	class var shared: URLSession { get { return URLSession() } }

	struct DataTaskPublisher : Publisher {
		typealias Output = (data: Data, response: URLResponse)
		typealias Failure = URLError

		func map<T>(_ transform: @escaping (Self.Output) -> T) -> Publishers.Map<Self, T> { return Publishers.Map() }
		func decode<Item, Coder>(type: Item.Type, decoder: Coder) ->
			Publishers.Decode<Self, Item, Coder> where Item: Decodable, Coder: TopLevelDecoder, Self.Output == Coder.Input { return Publishers.Decode() }
	}

	func dataTaskPublisher(for url: URL) -> URLSession.DataTaskPublisher { return DataTaskPublisher() }
}

// --- tests ---

class MyDecodable: Decodable {
	required init(from: Decoder) throws {
		// ... initialize trusting the data ...
	}
}

class MyDictInitializable {
	init?(dict: [String: Any]) {
		// ... initialize trusting the data ...
	}
}

class MyNodeInitializable {
	init?(node: Node) {
		// ... initialize trusting the data ...
	}
}

func testYAMSdecode() throws {
	let url = URL(string: "http://example.com/")!
	let remoteString = try String(contentsOf: url)
	let remoteData = try Data(contentsOf: url, options: [])
	let localString = ""
	let localData = Data(0)

	// YAMS YAMLDecoder

	let yamsDecoder = YAMLDecoder()

	_ = try yamsDecoder.decode(Int.self, from: remoteString) // good (decoded to harmless type) [FALSE POSITIVE]
	_ = try yamsDecoder.decode(Int.self, from: remoteData) // good (decoded to harmless type) [FALSE POSITIVE]
	_ = try yamsDecoder.decode(MyDecodable.self, from: remoteString) // BAD
	_ = try yamsDecoder.decode(MyDecodable.self, from: remoteData) // BAD
	_ = try yamsDecoder.decode(MyDecodable.self, from: localString) // good (input is local data)
	_ = try yamsDecoder.decode(MyDecodable.self, from: localData) // good (input is local data)

	// YAMS returning dict

	let a = try load(yaml: remoteString) as? [String: Any] // BAD [NOT DETECTED]
	if let _ = MyDictInitializable(dict: a!) {
		// ...
	}

	let bs = try load_all(yaml: remoteString) // BAD [NOT DETECTED]
	for b in bs {
		if let _ = MyDictInitializable(dict: b as! [String: Any]) {
			// ...
		}
	}

	// YAMS returning Node

	let c : Node? = try compose(yaml: remoteString) // BAD [NOT DETECTED]
	if let _ = MyNodeInitializable(node: c!) {
		// ...
	}

	let ds = try compose_all(yaml: remoteString) // BAD [NOT DETECTED]
	for d in ds {
		if let _ = MyNodeInitializable(node: d) {
			// ...
		}
	}

	let e : Node? = try compose(yaml: remoteString) // good (decoded to harmless type)
	_ = try yamsDecoder.decode(Int.self, from: e!)

	let f : Node? = try compose(yaml: remoteString) // BAD [NOT DETECTED]
	_ = try yamsDecoder.decode(MyDecodable.self, from: f!)

	// YAMS returning String + JSON

	let jsonDecoder = JSONDecoder()

	let gs = try load_all(yaml: remoteString) // BAD [NOT DETECTED]
	for g in gs {
		_ = try! jsonDecoder.decode(MyDecodable.self, from: (g as! String).data(using: .utf8)!)
	}

	// YAMS + Combine

	_ = URLSession.shared.dataTaskPublisher(for: url) // good (decoded to harmless type)
		.map(\.data)
		.decode(type: Int.self, decoder: YAMLDecoder())
	_ = URLSession.shared.dataTaskPublisher(for: url) // BAD [NOT DETECTED]
		.map(\.data)
		.decode(type: MyDecodable.self, decoder: YAMLDecoder())
}
