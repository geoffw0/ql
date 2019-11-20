import semmle.code.cpp.models.interfaces.ArrayFunction
import semmle.code.cpp.models.interfaces.DataFlow
import semmle.code.cpp.models.interfaces.Taint

/**
 * The standard function `strcmp` and its wide and Microsoft variants.
 */
class StrcmpFunction extends ArrayFunction {
  StrcmpFunction() {
    exists(string name | hasGlobalOrStdName(name) |
      name = "strcmp" or  // strcmp(str1, str2)
      name = "wcscmp" or  // wcscmp(str1, str2)
      name = "_mbscmp" or // _mbscmp(str1, str2)
      name = "_mbscmp_l"  // _mbscmp_l(str1, str2, locale)
    )
  }

  override predicate hasArrayInput(int param) {
    param = 0 or
    param = 1
  }

  override predicate hasArrayWithNullTerminator(int param) {
    param = 0 or
    param = 1
  }
}
