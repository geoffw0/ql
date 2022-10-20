
func sink<T>(_ arg: T) {}

func getConstant() -> Int {
	return 1
}

private var global : Int = 1

func getVariable() -> Int {
	global += 1
	return global
}

func identity(_ val: Int) -> Int {
	return val
}

struct MyStruct {
	var v1 = 1
	static let v2 = 2
}

func test(_ val: Int, _ cond: Bool, _ str: String, _ myStruct: MyStruct) {
	// direct literals
	sink(123) // $ constant=
	sink(1.23) // $ constant=
	sink(UInt32(123)) // $ constant=
	sink("abc") // $ constant=
	sink("a" as Character) // $ constant=
	sink(true) // $ constant=
	sink(nil as Int?) // $ constant=
	sink([1, 2, 3]) // $ MISSING: constant=
	sink(["a": 1, "b": 2, "c": 3]) // $ MISSING: constant=

	let a = 1
	sink(a) // $ constant=
	sink(a) // $ constant=
	sink(-a) // $ constant=
	sink(1 + 1) // $ constant=
	sink(a + 1) // $ constant=
	sink(1 + a) // $ constant=
	sink(a - 1) // $ constant=
	sink(1 - a) // $ constant=
	sink(a + a) // $ constant=
	sink(a + a + a) // $ constant=
	sink(getConstant()) // $ MISSING: constant=

	sink(val) // not constant
	sink(-val) // not constant
	sink(val + 1) // not constant
	sink(1 + val) // not constant
	sink(1 + val + 1) // not constant
	sink(getVariable()) // not constant

	sink(identity(1)); // $ MISSING: constant=
	sink(identity(val)); // not constant
	sink(identity(identity(1))); // $ MISSING: constant=
	sink(identity(identity(val))); // not constant

	var b = 1
	sink(b) // $ constant=
	b = a
	sink(b) // $ constant=
	b += 1
	sink(b) // $ constant=
	b += val
	sink(b) // $ SPURIOUS: constant=

	var c = 1
	sink(c) // $ constant=
	c = val
	sink(c) // not constant
	c += 1
	sink(c) // not constant

	var d = true
	sink(d) // $ constant=
	sink(!true) // $ constant=
	sink(!d) // $ constant=
	sink(cond) // not constant
	sink(!cond) // not constant

	sink(true && false) // $ MISSING: constant=
	sink(cond && true) // not constant
	sink(cond && false) // $ MISSING: constant=
	sink(true || true) // $ constant=
	sink(cond || true) // $ MISSING: constant=
	sink(cond || false) // not constant

	sink(true ? true : true) // $ constant=
	sink(true ? true : cond) // $ constant=
	sink(true ? cond : true) // not constant
	sink(cond ? true : true) // $ MISSING: constant=
	sink(cond ? true : false) // not constant

	sink(1 < 2) // $ constant=
	sink(1 < val) // not constant
	sink(1 == 2) // $ constant=
	sink(val == 2) // not constant

	var e = 1
	sink(e) // $ constant=
	if (cond) {
		e = 2
		sink(e) // $ constant=
	}
	sink(e) // not constant

	var f: Int
	if (cond) {
		f = 1
		sink(f) // $ constant=
	} else {
		f = 2
		sink(f) // $ constant=
	}
	sink(f) // not constant

	let g = "abc"
	sink(g) // $ constant=
	sink(str) // not constant
	sink(g + "def") // $ constant=
	sink(g + str) // not constant
	sink("\(g)") // $ constant=
	sink("\(str)") // $ SPURIOUS: constant=
	sink("\(g) \(str)") // $ SPURIOUS: constant=

	let (h, i) = (1, val)
	sink(h) // $ MISSING: constant=
	sink(i) // not constant
	sink((h, 1)) // $ MISSING: constant=
	sink((h, i)) // not constant

	var j: Int? = nil
	sink(j ?? 2) // $ MISSING: constant=
	j = 1
	sink(j ?? 2) // $ MISSING: constant=
	j = val
	sink(j ?? 2) // not constant

	sink(myStruct) // not constant
	sink(myStruct.v1) // not constant
	sink(MyStruct.v2) // $ MISSING: constant=
}
