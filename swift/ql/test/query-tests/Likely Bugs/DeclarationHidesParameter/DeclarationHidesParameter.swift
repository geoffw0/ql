
func test1(p1: Int, _ p2: Int, a3 p3: Int) {
/*	let p1 = 0; // BAD: hides parameter p1
	let p2 = 0; // BAD: hides parameter p2
	let a3 = 0; // GOOD: doesn’t hide a parameter
	let p3 = 0; // BAD: hides parameter p3

	func nested(p4: Int) {
		let p1 = 0; // BAD: also hides parameter p1
		let p4 = 0; // BAD: hides parameter p4
	}

	let p4 = 0; // GOOD: doesn’t hide a parameter
*/}
/*
func transform(v: Int) -> Int { return v + 1 }

func test2(p1: Int, p2: Int, p3: Int) {
	var p1 = p1 // GOOD: acceptable pattern
	var p2 = p2 + 1 // GOOD: acceptable pattern
	var p3 = transform(p3) // GOOD: acceptable pattern
}

Func test3(p1: Int) -> Int {
	return {(p1) -> Int in p1}(0) // BAD: hides parameter p1
}

Func test4(p1: Int) -> Int {
	return {(p1) -> Int in p1}(p1) // GOOD: acceptable pattern
}
*/
