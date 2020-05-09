import unittest
import options
import ../src/dimscommander/dsl/model
import ../src/dimscommander/runtime/argmatch

# Explicit intent
template expectNoError(body: untyped) =
  body

template singleArg(strLabel: string, itype: InputType): untyped =
  Argument(label: some(strLabel), limits: InputLimits(inputType: itype))

template expectMismatch(nthT: int, given: Option[InputType],
                        expected: Option[InputType], body: untyped) =
  try:
    body
    checkpoint("ArgumentMismatch was not thrown")
    fail()
  except ArgumentMismatch as exc:
    check exc.nth == nthT
    check exc.badType == given
    check exc.expectedType == expected

suite "Match strings only":
  test "Match one correct string":
    let tokens = @[">cmd", "I am string"]
    let args = [String]
    expectNoError:
      args.matchTokens(tokens)

  test "Reject missing one string":
    let
      tokens = @[">cmd"]
      args = [String]
    expectMismatch(0, given=none(InputType), expected=some(String)):
      args.matchTokens(tokens)

  test "Reject missing two strings and reports first missing":
    let
      tokens = @[">cmd"]
      args = [String, Int]
    expectMismatch(0, given=none(InputType), expected=some(String)):
      args.matchTokens(tokens)

  test "Reject extra strings":
    let
      tokens = @[">cmd", "first", "second"]
      args = [String]
    expectMismatch(1, given=some(String), expected=none(InputType)):
      args.matchTokens(tokens)

  test "Match many strings":
    let
      tokens = @[">cmd", "1", "2", "3", "4", "5"]
      args = [String, String, String, String, String]
    expectNoError:
      args.matchTokens(tokens)

suite "Match ints and floats":
  test "Match one int":
    let
      tokens = @[">cmd", "14"]
      args = [Int]
    expectNoError:
      args.matchTokens(tokens)

  test "Reject one non-int when expecting int":
    let
      tokens = @[">cmd", "not int"]
      args = [Int]
    expectMismatch(0, given=some(String), expected=some(Int)):
      args.matchTokens(tokens)

  test "Match many kinds of valid ints":
    let validInts = ["0001", "-91455513", "+1331", "591000"]
    for validInt in validInts:
      expectNoError:
        [Int].matchTokens(@[">cmd", validInt])

  test "Reject many kinds of invalid ints":
    let notInts = ["--41", "0.0", "-9475e4", "one", "1e3"]
    for notInt in notInts:
      expectMismatch(0, given=some(String), expected=some(Int)):
        [Int].matchTokens(@[">cmd", notInt])

