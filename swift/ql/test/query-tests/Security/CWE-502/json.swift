// --- stubs ---

class NSObject {
}

class Stream : NSObject {
}

class InputStream : Stream {
}

struct URL
{
	init?(string: String) {}
}

struct Data {
    struct ReadingOptions : OptionSet { let rawValue: Int }
	init(contentsOf: URL, options: ReadingOptions) throws {}
}

extension String {
	struct Encoding {
		var rawValue: UInt

		static let utf8 = Encoding(rawValue: 1)
	}

	func data(using encoding: String.Encoding, allowLossyConversion: Bool = false) -> Data? { return nil }
}

protocol DecodableWithConfiguration {
	associatedtype DecodingConfiguration

	init(from decoder: Decoder, configuration: Self.DecodingConfiguration) throws
}

class JSONDecoder {
	func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable { return 0 as! T }
	func decode<T>(_ type: T.Type, from data: Data, configuration: T.DecodingConfiguration) throws -> T where T : DecodableWithConfiguration { return 0 as! T }
}

class JSONSerialization {
	struct ReadingOptions : OptionSet {
		var rawValue: UInt
	}

	class func jsonObject(with data: Data, options opt: JSONSerialization.ReadingOptions = []) throws -> Any { return "" }
	class func jsonObject(with stream: InputStream, options opt: JSONSerialization.ReadingOptions = []) throws -> Any { return "" }
}

// --- tests ---

class MyDecodable : Decodable {
	required init(from: Decoder) throws {
		// ... initialize trusting the data ...
	}
}

class MyDecodableWithConfiguration : DecodableWithConfiguration {
	typealias DecodingConfiguration = String

	required init(from: Decoder, configuration: String) throws {
		// ... initialize trusting the data ...
	}
}

class MyDictInitializable {
	init?(dict: [String: Any]) {
		// ... initialize trusting the data ...
	}
}

func testJSONdecode(inputStream: InputStream) throws {
	let url = URL(string: "http://example.com/")!
	let remoteData = try Data(contentsOf: url, options: [])
	let jsonString = #"{ "val" : "foo" }"#
	let localData = jsonString.data(using: .utf8)!

	// JSONDecoder

	let jsonDecoder = JSONDecoder()

	_ = try! jsonDecoder.decode(MyDecodable.self, from: remoteData) // BAD
	_ = try! jsonDecoder.decode(MyDecodable.self, from: localData) // good (input is local data)
	_ = try! JSONDecoder().decode(MyDecodable.self, from: remoteData) // BAD
	_ = try! jsonDecoder.decode([MyDecodable].self, from: remoteData) // BAD
	_ = try! jsonDecoder.decode(MyDecodableWithConfiguration.self, from: remoteData, configuration: "") // BAD

	// JSONSerialization

	let a = try? JSONSerialization.jsonObject(with: remoteData, options: []) as? [String: Any] // BAD [NOT DETECTED]
	if let _ = MyDictInitializable(dict: a!) {
		// ...
	}

	let b = try? JSONSerialization.jsonObject(with: inputStream, options: []) as? [String: Any] // BAD [NOT DETECTED]
	if let _ = MyDictInitializable(dict: b!) {
		// ...
	}

	let cs = try? JSONSerialization.jsonObject(with: remoteData, options: []) as? [[String: Any]] // BAD [NOT DETECTED]
	for c in cs! {
		if let _ = MyDictInitializable(dict: c) {
			// ...
		}
	}
}
