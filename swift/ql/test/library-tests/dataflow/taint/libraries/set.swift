
// --- stubs ---

// --- tests ---

func source() -> Int { return 0; }
func sink(arg: Any) {}

func testSet(ix: Int) {
  let goodSet = Set([1, 2, 3])
  sink(arg: goodSet)
  sink(arg: goodSet.randomElement()!)
  sink(arg: goodSet.min()!)
  sink(arg: goodSet.max()!)
  sink(arg: goodSet[goodSet.firstIndex(of: 1)!])
  sink(arg: goodSet.first!)
  for elem in goodSet {
    sink(arg: elem)
  }

  let taintedSet = Set([1, 2, source()])
  sink(arg: taintedSet)
  sink(arg: taintedSet.randomElement()!) // $ tainted=21
  sink(arg: taintedSet.min()!) // $ MISSING: tainted=
  sink(arg: taintedSet.max()!) // $ MISSING: tainted=
  sink(arg: taintedSet[taintedSet.firstIndex(of: source())!]) // $ tainted=21
  sink(arg: taintedSet.first!) // $ MISSING: tainted=
  for elem in taintedSet {
    sink(arg: elem) // $ tainted=21
  }
  for (ix, elem) in taintedSet.enumerated() {
    sink(arg: ix)
    sink(arg: elem) // $ MISSING: tainted=
  }
  taintedSet.forEach {
    elem in
    sink(arg: elem) // $ MISSING: tainted=
  }

  var set1 = Set<Int>()
  set1.insert(1)
  sink(arg: set1.randomElement()!)
  set1.insert(source())
  sink(arg: set1.randomElement()!) // $ tainted=43
  set1.insert(2)
  sink(arg: set1.randomElement()!) // $ tainted=43
  set1.removeAll()
  sink(arg: set1.randomElement()!) // $ SPURIOUS: tainted=43

  var set2 = Set<Int>()
  set2.update(with: source())
  sink(arg: set2.randomElement()!) // $ MISSING: tainted=

  var set3 = Set([source()])
  sink(arg: set3.randomElement()!) // $ tainted=54
  let (inserted, previous) = set3.insert(source())
  sink(arg: inserted)
  sink(arg: previous) // $ tainted=54 tainted=56
  let previous2 = set3.update(with: source())
  sink(arg: previous2!) // $ MISSING: tainted=
  let previous3 = set3.remove(source())
  sink(arg: previous3!) // $ MISSING: tainted=
  let previous4 = set3.removeFirst()
  sink(arg: previous4) // $ MISSING: tainted=
  let previous5 = set3.remove(at: set3.firstIndex(of: 1)!)
  sink(arg: previous5) // $ MISSING: tainted=

  sink(arg: goodSet.union(goodSet).randomElement()!)
  sink(arg: goodSet.union(taintedSet).randomElement()!) // $ MISSING: tainted=
  sink(arg: taintedSet.union(goodSet).randomElement()!) // $ MISSING: tainted=
  sink(arg: taintedSet.union(taintedSet).randomElement()!) // $ MISSING: tainted=

  var set4 = Set<Int>()
  set4.formUnion(goodSet)
  sink(arg: set4.randomElement()!) // $ MISSING: tainted=
  set4.formUnion(taintedSet)
  sink(arg: set4.randomElement()!) // $ MISSING: tainted=
  set4.formUnion(goodSet)
  sink(arg: set4.randomElement()!) // $ MISSING: tainted=

  sink(arg: goodSet.intersection(goodSet).randomElement()!)
  sink(arg: goodSet.intersection(taintedSet).randomElement()!)
  sink(arg: taintedSet.intersection(goodSet).randomElement()!)
  sink(arg: taintedSet.intersection(taintedSet).randomElement()!) // $ MISSING: tainted=

  sink(arg: goodSet.symmetricDifference(goodSet).randomElement()!)
  sink(arg: goodSet.symmetricDifference(taintedSet).randomElement()!) // $ MISSING: tainted=
  sink(arg: taintedSet.symmetricDifference(goodSet).randomElement()!) // $ MISSING: tainted=
  sink(arg: taintedSet.symmetricDifference(taintedSet).randomElement()!) // $ MISSING: tainted=

  sink(arg: goodSet.subtracting(goodSet).randomElement()!)
  sink(arg: goodSet.subtracting(taintedSet).randomElement()!)
  sink(arg: taintedSet.subtracting(goodSet).randomElement()!) // $ MISSING: tainted=
  sink(arg: taintedSet.subtracting(taintedSet).randomElement()!) // $ MISSING: tainted=

  sink(arg: taintedSet.sorted().randomElement()!) // $ MISSING: tainted=
  sink(arg: taintedSet.shuffled().randomElement()!) // $ MISSING: tainted=

  sink(arg: taintedSet.lazy[taintedSet.firstIndex(of: source())!]) // $ MISSING: tainted=

  var it = taintedSet.makeIterator()
  sink(arg: it.next()!) // $ tainted=21
}
