import ../dsl/model
import options

type ArgumentMismatch* = ref object of CatchableError
  nth*: int # starts from 0
  badType*: Option[InputType]
  expectedType*: Option[InputType]

template isSign(ch: char): bool = ch in {'+', '-'}
template isJustSign(str: string): bool = str.len == 1 and str[0].isSign
template partitionAt(str: string, i: int): (string, string) =
  (str[0..<i], str[(i+1)..^1])

func findOneOf(str: string, chars: set[char]): int {.inline.} =
  for i in 0..high(str):
    if str[i] in chars:
      return i
  return -1

# through an informal benchmark, I have found that
# this manual solution is about 7x faster than matching
# a pre-compiled regex pattern
func isInt(str: string): bool {.inline.} =
  var i = if str[0].isSign: 1 else: 0
  if i == str.len: return false
  while i < str.len:
    if str[i] notin '0'..'9':
      return false
    i += 1
  return true

func isFloat(str: string): bool {.inline.} =
  let eIndex = str.findOneOf {'e', 'E'}
  if eIndex != -1:
    let (beforeE, afterE) = str.partitionAt(eIndex)
    return beforeE.isFloat and afterE.isInt

  let dotIndex = str.find('.')
  if dotIndex != -1:
    let
      (beforeDot, afterDot) = str.partitionAt(dotIndex)
      beforeDecimalGood = (dotIndex == 0 or beforeDot.isJustSign or beforeDot.isInt)
      afterDecimalGood = ("+" & afterDot).isInt
    return beforeDecimalGood and afterDecimalGood
  return isInt(str)

func checkToken*(tokens: seq[string], i: int,
                expected: InputType) =

  template require(token: string, checkFunc: typed) =
    if not checkFunc(token):
      let givenType = if token.isFloat: Float else: String
      raise ArgumentMismatch(nth: i, badType: some(givenType),
                             expectedType: some(expected))
  case expected
  of Int: tokens[i + 1].require(isInt)
  of Float: tokens[i + 1].require(isFloat)
  else: discard

func expectMinArgTypes*(tokens: seq[string], types: seq[InputType]) =
  let numArgsGiven = tokens.len - 1
  if numArgsGiven < types.len:
    raise ArgumentMismatch(nth: numArgsGiven, badType: none(InputType),
                           expectedType: some(types[numArgsGiven]))

func checkLeadingTypes*(tokens: seq[string], types: seq[InputType]) =
  for i in 0..high(types):
    tokens.checkToken(i, types[i])

func checkTrailingTypes*(tokens: seq[string], types: seq[InputType]) =
  for i in 0..high(types):
    tokens.checkToken(tokens.len - types.len + i - 1, types[i])

func codeToCheckTokens*(args: seq[Argument], tokenIdent: string): NimNode =
  # TODO
  discard

# to be generated from codeToCheckTokens
when false:
  dumpTree:
    tokens.expectMinArgLen(4)
    const beginTypes = [Int, String, Float]
    tokens.checkToken(0, Int)
    const endTypes = [Int, String, String]
    for i in 5..<(tokens.len - 3):
      tokens.checkToken(i, String)