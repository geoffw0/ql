
func myFunction(s: String) {
	let ns = NSString(string: s)
	let range = NSMakeRange(0, s.count) // BAD: String length used in NSMakeRange

	// ... use range to process ns
}
