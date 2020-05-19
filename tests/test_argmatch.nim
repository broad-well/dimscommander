import ./statictest
import options
import ../src/dimscommander/dsl/model
import ../src/dimscommander/runtime/argmatch

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
        tokens.expectMinArgTypes(@[Int, String])

    test "Reject less than minimum number of arguments":
      let tokens = @[">cmd", "1", "2"]
      expectMismatch(2, given=none(InputType), expected=some(Float)):
        tokens.expectMinArgTypes(@[String, String, Float])

    test "Reject no arguments given some types":
      let tokens = @[">cmd"]
      expectMismatch(0, given=none(InputType), expected=some(Float)):
        tokens.expectMinArgTypes(@[Float])

    test "Accept more number of arguments than given length":
      let tokens = @[">cmd", "1", "2", "3", "4"]
      expectNoError:
        tokens.expectMinArgTypes(@[String, String])

  block checkLeadingTrailingTypes:
    test "Accept matching leading types and no more":
      let tokens = @[">cmd", "1", "str", "2.7", "str"]
      expectNoError:
        tokens.checkLeadingTypes(@[Int, String, Float, String])

    test "Accept extraneous types":
      let tokens = @[">cmd", "1", "2.7", "extra 1", "extra 2"]
      expectNoError:
        tokens.checkLeadingTypes(@[Int, Float])

    test "Reject any bad leading type as string":
      let tokens = @[">cmd", "1", "str", "not int", "str"]
      expectMismatch(2, given=some(String), expected=some(Int)):
        tokens.checkLeadingTypes(@[Int, String, Int, String])

    test "Reject any bad leading float when expecting int":
      let tokens = @[">cmd", "1", "str", "2.4", "str"]
      expectMismatch(2, given=some(Float), expected=some(Int)):
        tokens.checkLeadingTypes(@[Int, String, Int, String])

    test "Reject first mismatch":
      let tokens = @[">cmd", "not float", "second mismatch", "2.2"]
      expectMismatch(0, given=some(String), expected=some(Float)):
        tokens.checkLeadingTypes(@[Float, Float, Int])

    test "Accept matching trailing types and no more":
      let tokens = @[">cmd", "str1", "2.2", "3"]
      expectNoError:
        tokens.checkTrailingTypes(@[String, Float, Int])

    test "Reject any bad trailing token":
      let tokens = @[">cmd", "2.2", "rr3", "test"]
      expectMismatch(1, given=some(String), expected=some(Int)):
        tokens.checkTrailingTypes(@[Float, Int, String])

    test "Accept extraneous tokens in trailing":
      let tokens = @[">cmd", "extra", "extra", "2.2", "3", "yes"]
      expectNoError:
        tokens.checkTrailingTypes(@[Float, Int, String])

    test "Reject first mismatch in trailing from front":
      let tokens = @[">cmd", "1", "first mismatch", "2.2", "second mismatch"]
      expectMismatch(1, given=some(String), expected=some(Float)):
        tokens.checkTrailingTypes(@[Int, Float, Float, Int])