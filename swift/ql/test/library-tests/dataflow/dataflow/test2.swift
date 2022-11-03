func source() -> String { return ""; }
func sink(arg: String) {}

func testDicts() {
    let d1 = ["a": "apple", "b": "banana", "c": source()]
    let strA = "a"
    let strB = "b"
    let strC = "c"

    sink(arg: d1["a"]!)
    sink(arg: d1["b"]!)
    sink(arg: d1["c"]!) // $ flow=5

    sink(arg: d1[strA]!)
    sink(arg: d1[strB]!)
    sink(arg: d1[strC]!) // $ MISSING: flow=5

    for key in d1.keys {
        sink(arg: key)
        sink(arg: d1[key]!) // $ MISSING: flow=5
    }
    for value in d1.values {
        sink(arg: value) // $ MISSING: flow=5
    }
    for (key, value) in d1 {
        sink(arg: key)
        sink(arg: value) // $ MISSING: flow=5
    }
}

func testDicts2() {
    let d2 = [1: "one", 2: source(), 3: "three"]

    sink(arg: d2[1]!)
    sink(arg: d2[2]!) // $ MISSING: flow=32
    sink(arg: d2[3]!)

    sink(arg: d2[1 + 1]!) // $ MISSING: flow=32
}

func testDicts3() {
    var d3: [String: String] = [:]

    sink(arg: d3["val"] ?? "default")

    d3["val"] = source()

    sink(arg: d3["val"] ?? "default") // $ MISSING: flow=46
    sink(arg: d3["val"]!) // $ MISSING: flow=46

    d3["val"] = nil

    sink(arg: d3["val"] ?? "default")
    sink(arg: d3["val"]!)
}

func testDicts4() {
    var d4: [String: String] = [:]

    d4[source()] = "value"

    for key in d4.keys {
        sink(arg: key) // $ MISSING: flow=60
        sink(arg: d4[key]!)
    }
    for value in d4.values {
        sink(arg: value)
    }
    for (key, value) in d4 {
        sink(arg: key) // $ MISSING: flow=60
        sink(arg: value)
    }
}
