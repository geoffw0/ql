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

class NSString : NSObject {
}

protocol DecodableWithConfiguration {
	associatedtype DecodingConfiguration

	init(from decoder: Decoder, configuration: Self.DecodingConfiguration) throws
}

class PropertyListDecoder {
	func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable { return 0 as! T }
	func decode<T>(_ type: T.Type, from data: Data, format: inout PropertyListSerialization.PropertyListFormat) throws -> T where T : Decodable { return 0 as! T }
	func decode<T>(_ type: T.Type, from data: Data, configuration: T.DecodingConfiguration) throws -> T where T : DecodableWithConfiguration { return 0 as! T }
	func decode<T>(_ type: T.Type, from data: Data, format: inout PropertyListSerialization.PropertyListFormat, configuration: T.DecodingConfiguration) throws -> T where T : DecodableWithConfiguration { return 0 as! T }
}

class PropertyListSerialization : NSObject {
	struct MutabilityOptions : OptionSet {
		var rawValue: UInt
	}

	enum PropertyListFormat: UInt {
		case binary = 1
	}

	typealias ReadOptions = PropertyListSerialization.MutabilityOptions

	class func propertyList(from data: Data, options opt: PropertyListSerialization.ReadOptions = [], format: UnsafeMutablePointer<PropertyListSerialization.PropertyListFormat>?) throws -> Any { return "" }
	class func propertyList(with stream: InputStream, options opt: PropertyListSerialization.ReadOptions = [], format: UnsafeMutablePointer<PropertyListSerialization.PropertyListFormat>?) throws -> Any { return "" }
	class func propertyListFromData(
		_ data: Data, mutabilityOption opt: PropertyListSerialization.MutabilityOptions = [],
		format: UnsafeMutablePointer<PropertyListSerialization.PropertyListFormat>?,
		errorDescription errorString: UnsafeMutablePointer<NSString?>?) -> Any? { return "" }
}

// --- tests ---

class MyDecodable : Decodable {
	required init(from: Decoder) throws {
		// ... initialize trusting the data ...
	}
}

class MyDecodableWithConfiguration : DecodableWithConfiguration {
	required init(from: Decoder, configuration: String) throws {
		// ... initialize trusting the data ...
	}
}

class MyDictInitializable {
	init?(dict: [String: Any]) {
		// ... initialize trusting the data ...
	}
}

func testplistdecode(inputStream: InputStream) throws {
	let url = URL(string: "http://example.com/")!
	let remoteData = try Data(contentsOf: url, options: [])
	let plistString = #"<plist><dict><key>val</key><string>foo</string></dict></plist>"#
	let localData = plistString.data(using: .utf8)!

	// PropertyListDecoder

	let plistDecoder = PropertyListDecoder()
	var fmt = PropertyListSerialization.PropertyListFormat.binary

	_ = try! plistDecoder.decode(MyDecodable.self, from: remoteData) // BAD [NOT DETECTED]
	_ = try! plistDecoder.decode(MyDecodable.self, from: localData) // good (input is local data)
	_ = try! plistDecoder.decode([MyDecodable].self, from: remoteData) // BAD [NOT DETECTED]
	_ = try! plistDecoder.decode(MyDecodable.self, from: remoteData, format: &fmt) // BAD [NOT DETECTED]
	_ = try! plistDecoder.decode(MyDecodableWithConfiguration.self, from: remoteData, configuration: "") // BAD [NOT DETECTED]
	_ = try! plistDecoder.decode(MyDecodableWithConfiguration.self, from: remoteData, format: &fmt, configuration: "") // BAD [NOT DETECTED]

	// PropertyListSerialization

	let a = try PropertyListSerialization.propertyList(from: remoteData, options: [], format: nil) as! [String: Any] // BAD
	if let _ = MyDictInitializable(dict: a) {
		// ...
	}

	let b = try PropertyListSerialization.propertyList(with: inputStream, options: [], format: nil) as! [String: Any] // BAD [NOT DETECTED]
	if let _ = MyDictInitializable(dict: b) {
		// ...
	}

	let c = PropertyListSerialization.propertyListFromData(remoteData, mutabilityOption: [], format: nil, errorDescription: nil) as! [String: Any] // BAD [NOT DETECTED]
	if let _ = MyDictInitializable(dict: c) {
		// ...
	}

	let ds = try PropertyListSerialization.propertyList(from: remoteData, options: [], format: nil) as! [[String: Any]] // BAD
	for d in ds {
		if let _ = MyDictInitializable(dict: d) {
			// ...
		}
	}
}
