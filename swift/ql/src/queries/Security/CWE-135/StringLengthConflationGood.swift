
func myFunction(s: String) {
	let ns = NSString(string: s)
	let range = NSMakeRange(0, ns.length) // Fixed: NSString length used in NSMakeRange

	// ... use range to process ns
}
