import ./statictest
import options
import ../src/dimscommander/dsl/model
import ../src/dimscommander/runtime/argmatch
import macros, macroutils

# Explicit intent
template expectNoError(body: untyped) =
  try:
    body
  except Exception as exc:
    assert false, repr(exc)

template arg(tipe: InputType): Argument =
  Argument(limits: InputLimits(inputType: tipe))

template vararg(subtype: InputType): Argument =
  Argument(limits: InputLimits(inputType: Varargs, argType: subtype))

template expectMismatch(nthT: int, given: Option[InputType],
                        expected: Option[InputType], body: untyped) =
  try:
    body
    assert false, "ArgumentMismatch was not thrown"
  except ArgumentMismatch as exc:
    assert exc.nth == nthT
    assert exc.badType == given
    assert exc.expectedType == expected

static:
  block matchInts:
    test "Match one int":
      let
        tokens = @[">cmd", "14"]
      expectNoError:
        tokens.checkToken(0, Int)

    test "Reject one non-int when expecting int":
      let
        tokens = @[">cmd", "not int"]
      expectMismatch(0, given=some(String), expected=some(Int)):
        tokens.checkToken(0, Int)

    test "Match many kinds of valid ints":
      let
        validInts = ["0001", "-91455513", "+1331", "591000"]
      for validInt in validInts:
        let tokens = @[">cmd", validInt]
        expectNoError:
          tokens.checkToken(0, Int)

    test "Reject many kinds of invalid ints":
      let notInts = ["--41", "one", "-", "+"]
      for notInt in notInts:
        let tokens = @[">cmd", notInt]
        expectMismatch(0, given=some(String), expected=some(Int)):
          tokens.checkToken(0, Int)

    test "Reject many kinds of floats":
      let floats = ["0.0", "-9475e4", "1e3"]
      for flot in floats:
        let tokens = @[">cmd", flot]
        expectMismatch(0, given=some(Float), expected=some(Int)):
          tokens.checkToken(0, Int)

  block matchFloats:
    test "Accept single integer as float":
      let tokens = @[">cmd", "4"]
      expectNoError:
        tokens.checkToken(0, Float)

    test "Reject word as float":
      let tokens = @[">cmd", "one"]
      expectMismatch(0, given=some(String), expected=some(Float)):
        tokens.checkToken(0, Float)

    test "Accept float as float":
      let tokens = @[">cmd", "2.1"]
      expectNoError:
        tokens.checkToken(0, Float)

    test "Reject sign before decimal part":
      let tokens = @[">cmd", "-14.-21"]
      expectMismatch(0, given=some(String), expected=some(Float)):
        tokens.checkToken(0, Float)

    test "Accept many exotic floats":
      let floats = ["0.9E2", "9.141526412", ".8", "+1.0014e4", "-.2", "0e0"]
      for goodFloat in floats:
        let tokens = @[">cmd", goodFloat]
        expectNoError:
          tokens.checkToken(0, Float)

    test "Reject many exotic non-floats":
      let badFloats = ["1e4.2", "1e-", "-e2", "4.-0", "-0..0", "0.0.0"]
      for badFloat in badFloats:
        let tokens = @[">cmd", badFloat]
        expectMismatch(0, given=some(String), expected=some(Float)):
          tokens.checkToken(0, Float)

  block expectMinArgTypesProc:
    test "Accept minimum number of arguments":
      let tokens = @[">cmd", "1", "2"]
      expectNoError:
        tokens.expectMinArgTypes([Int, String])

    test "Reject less than minimum number of arguments":
      let tokens = @[">cmd", "1", "2"]
      expectMismatch(2, given=none(InputType), expected=some(Float)):
        tokens.expectMinArgTypes([String, String, Float])

    test "Reject no arguments given some types":
      let tokens = @[">cmd"]
      expectMismatch(0, given=none(InputType), expected=some(Float)):
        tokens.expectMinArgTypes([Float])

    test "Accept more number of arguments than given length":
      let tokens = @[">cmd", "1", "2", "3", "4"]
      expectNoError:
        tokens.expectMinArgTypes([String, String])

  block checkLeadingTrailingTypes:
    test "Accept matching leading types and no more":
      let tokens = @[">cmd", "1", "str", "2.7", "str"]
      expectNoError:
        tokens.checkLeadingTypes([Int, String, Float, String])

    test "Accept extraneous types":
      let tokens = @[">cmd", "1", "2.7", "extra 1", "extra 2"]
      expectNoError:
        tokens.checkLeadingTypes([Int, Float])

    test "Reject any bad leading type as string":
      let tokens = @[">cmd", "1", "str", "not int", "str"]
      expectMismatch(2, given=some(String), expected=some(Int)):
        tokens.checkLeadingTypes([Int, String, Int, String])

    test "Reject any bad leading float when expecting int":
      let tokens = @[">cmd", "1", "str", "2.4", "str"]
      expectMismatch(2, given=some(Float), expected=some(Int)):
        tokens.checkLeadingTypes([Int, String, Int, String])

    test "Reject first mismatch":
      let tokens = @[">cmd", "not float", "second mismatch", "2.2"]
      expectMismatch(0, given=some(String), expected=some(Float)):
        tokens.checkLeadingTypes([Float, Float, Int])

    test "Accept matching trailing types and no more":
      let tokens = @[">cmd", "str1", "2.2", "3"]
      expectNoError:
        tokens.checkTrailingTypes([String, Float, Int])

    test "Reject any bad trailing token":
      let tokens = @[">cmd", "2.2", "rr3", "test"]
      expectMismatch(1, given=some(String), expected=some(Int)):
        tokens.checkTrailingTypes([Float, Int, String])

    test "Accept extraneous tokens in trailing":
      let tokens = @[">cmd", "extra", "extra", "2.2", "3", "yes"]
      expectNoError:
        tokens.checkTrailingTypes([Float, Int, String])

    test "Reject first mismatch in trailing from front":
      let tokens = @[">cmd", "1", "first mismatch", "2.2", "second mismatch"]
      expectMismatch(1, given=some(String), expected=some(Float)):
        tokens.checkTrailingTypes([Int, Float, Float, Int])

  block checkVarargTypes:
    test "Accept no arguments given to vararg":
      let tokens = @[">cmd", "str", "1.4", "1.44"]
      expectNoError:
        tokens.checkVarargs(1, 2, Int)

    test "Accept one vararg argument only":
      let tokens = @[">cmd", "1.4"]
      expectNoError:
        tokens.checkVarargs(0, 0, Float)

    test "Reject one incorrect vararg argument only":
      let tokens = @[">cmd", "not int"]
      expectMismatch(0, given=some(String), expected=some(Int)):
        tokens.checkVarargs(0, 0, Int)

    test "Accept multiple vararg arguments":
      let tokens = @[">cmd", "begin 1", "begin 2", "1.2", "2.1", "end 1"]
      expectNoError:
        tokens.checkVarargs(2, 1, Float)

    test "Reject one incorrect vararg argument out of 4":
      let tokens = @[">cmd", "begin 1", "begin 2", "yes", "13", "14", "11"]
      expectMismatch(2, given=some(String), expected=some(Int)):
        tokens.checkVarargs(2, 0, Int)

    test "Reject first incorrect vararg argument":
      let tokens = @[">cmd", "begin 1", "12", "report this", "not this", "end 1"]
      expectMismatch(2, given=some(String), expected=some(Float)):
        tokens.checkVarargs(1, 1, Float)

  block integration_checkAllArgs:
    test "Reject first incorrect leading argument (no varargs)":
      let tokens = @[">cmd", "1", "2", "3", "4", "no", "6", "7"]
      expectMismatch(4, given=some(String), expected=some(Int)):
        tokens.checkAllArgs([Int, Int, Int, Int, Int, Int, Int], [])

    test "Reject first incorrect trailing argument (with varargs)":
      let tokens = @[">cmd", "str", "1.2", "1", "2", "2.3", "not int", "yes"]
      expectMismatch(5, given=some(String), expected=some(Int)):
        tokens.checkAllArgs([String, Float], [Int, String], some(Int))

    test "Reject first incorrect vararg":
      let tokens = @[">cmd", "1", "2.2", "9", "9.9", "9", "9.9", "end"]
      expectMismatch(3, given=some(Float), expected=some(Int)):
        tokens.checkAllArgs([Int, Float], [String], some(Int))

    test "Reject extraneous args (no varargs)":
      let tokens = @[">cmd", "1", "2.2", "3", "extra", "3", "2.2", "1"]
      expectMismatch(6, given=some(String), expected=none(InputType)):
        tokens.checkAllArgs([Int, Float, Int, String, Int, Float], [])

  block codeGen:
    test "Code to check zero arguments":
      let expected = quote do:
        t0k.expectMinArgTypes([])
        t0k.checkAllArgs([], [])

      doAssert codeToCheckTokens(@[], "t0k").sameTree(expected)

    test "Code to check multiple arguments and no varargs":
      # Would be nice if newLit actually finds the name of that enum
      # Int.newLit => Ident "Int"
      let expected = superQuote do:
        t0k.expectMinArgTypes([`Int.newLit`, `Float.newLit`, `Int.newLit`, `String.newLit`])
        t0k.checkAllArgs([`Int.newLit`, `Float.newLit`,
                          `Int.newLit`, `String.newLit`], [])

      doAssert codeToCheckTokens(@[arg(Int), arg(Float), arg(Int), arg(String)], "t0k")
        .sameTree(expected)

    test "Code to check multiple arguments and varargs at end":
      let expected = superQuote do:
        tokens.expectMinArgTypes([`Int.newLit`, `Float.newLit`])
        tokens.checkAllArgs([`Int.newLit`, `Float.newLit`],
                            [], some(`Int.newLit`))

      doAssert codeToCheckTokens(@[arg(Int), arg(Float), vararg(Int)], "tokens")
        .sameTree(expected)

    test "Code to check multiple arguments and varargs in middle":
      let expected = superQuote do:
        tokens.expectMinArgTypes([`Float.newLit`, `Int.newLit`])
        tokens.checkAllArgs([`Float.newLit`], [`Int.newLit`], some(`String.newLit`))

      doAssert codeToCheckTokens(@[arg(Float), vararg(String), arg(Int)], "tokens")
        .sameTree(expected)