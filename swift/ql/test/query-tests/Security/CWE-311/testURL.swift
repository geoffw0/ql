
// --- stubs ---

struct URL
{
	init?(string: String) {}
	init?(string: String, relativeTo: URL?) {}
}

// --- tests ---

var myString = ""
func setMyString(str: String) { myString = str }
func getMyString() -> String { return myString }

func test1(passwd : String, encrypted_passwd : String, account_no : String, credit_card_no : String) {
	let a = URL(string: "http://example.com/login?p=" + passwd); // BAD
	let b = URL(string: "http://example.com/login?p=" + encrypted_passwd); // GOOD (not sensitive)
	let c = URL(string: "http://example.com/login?ac=" + account_no); // BAD
	let d = URL(string: "http://example.com/login?cc=" + credit_card_no); // BAD

	let base = URL(string: "http://example.com/"); // GOOD (not sensitive)
	let e = URL(string: "abc", relativeTo: base); // GOOD (not sensitive)
	let f = URL(string: passwd, relativeTo: base); // BAD
	let g = URL(string: "abc", relativeTo: f); // BAD (reported on line above)

	let e_mail = myString
	let h = URL(string: "http://example.com/login?em=" + e_mail); // BAD
	var a_homeaddr_z = getMyString()
	let i = URL(string: "http://example.com/login?home=" + a_homeaddr_z); // BAD
	var resident_ID = getMyString()
	let j = URL(string: "http://example.com/login?id=" + resident_ID); // BAD
}

func get_private_key() -> String { return "" }
func get_aes_key() -> String { return "" }
func get_aws_key() -> String { return "" }
func get_access_key() -> String { return "" }
func get_secret_key() -> String { return "" }
func get_key_press() -> String { return "" }
func get_cert_string() -> String { return "" }
func get_certain() -> String { return "" }

func test2() {
	// more variants...

	let a = URL(string: "http://example.com/login?key=" + get_private_key()); // BAD
	let b = URL(string: "http://example.com/login?key=" + get_aes_key()); // BAD
	let c = URL(string: "http://example.com/login?key=" + get_aws_key()); // BAD
	let d = URL(string: "http://example.com/login?key=" + get_access_key()); // BAD
	let e = URL(string: "http://example.com/login?key=" + get_secret_key()); // BAD
	let f = URL(string: "http://example.com/login?key=" + get_key_press()); // GOOD (not sensitive)
	let g = URL(string: "http://example.com/login?cert=" + get_cert_string()); // BAD
	let g = URL(string: "http://example.com/login?cert=" + get_certain()); // GOOD (not sensitive)
}

func get_string() -> String { return "" }

func test3() {
	// more variants...

	let priv_key = get_string()
	let private_key = get_string()
	let pub_key = get_string()
	let certificate = get_string()
	let secure_token = get_string()
	let access_token = get_string()
	let auth_token = get_string()
	let next_token = get_string()

	let a = URL(string: "http://example.com/login?key=\(priv_key)"); // BAD
	let a = URL(string: "http://example.com/login?key=\(private_key)"); // BAD
	let a = URL(string: "http://example.com/login?key=\(pub_key)"); // GOOD (not sensitive)
	let b = URL(string: "http://example.com/login?cert=\(certificate)"); // BAD
	let d = URL(string: "http://example.com/login?tok=\(secure_token)"); // BAD
	let e = URL(string: "http://example.com/login?tok=\(access_token)"); // BAD
	let e = URL(string: "http://example.com/login?tok=\(auth_token)"); // BAD
	let f = URL(string: "http://example.com/login?tok=\(next_token)"); // GOOD (not sensitive)
}
