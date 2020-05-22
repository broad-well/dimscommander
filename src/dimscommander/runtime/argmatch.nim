import ../dsl/model
import options
from sequtils import toSeq, map
import sugar
import macros
import macroutils

type ArgumentMismatch* = ref object of CatchableError
  nth*: int # starts from 0
  badType*: Option[InputType]
  expectedType*: Option[InputType]

template isSign(ch: char): bool = ch in {'+', '-'}
template isJustSign(str: string): bool = str.len == 1 and str[0].isSign
template partitionAt[T](str: T, i: int): (T, T) =
  (str[0..<i], str[(i+1)..^1])

func search[T](s: seq[T]; pred: proc (t: T): bool): Option[int] {.inline.} =
  for (index, item) in s.pairs():
    if pred(item):
      return some(index)
  return none(int)

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

func expectMinArgTypes*(tokens: seq[string], types: openArray[InputType]) =
  let numArgsGiven = tokens.len - 1
  if numArgsGiven < types.len:
    raise ArgumentMismatch(nth: numArgsGiven, badType: none(InputType),
                           expectedType: some(types[numArgsGiven]))

func checkLeadingTypes*(tokens: seq[string], types: openArray[InputType]) =
  for i in 0..high(types):
    tokens.checkToken(i, types[i])

func checkTrailingTypes*(tokens: seq[string], types: openArray[InputType]) =
  for i in 0..high(types):
    tokens.checkToken(tokens.len - types.len + i - 1, types[i])

func checkVarargs*(tokens: seq[string], leadLen: int,
                   trailLen: int, argType: InputType) =
  for i in leadLen..<(tokens.len - trailLen - 1):
    tokens.checkToken(i, argType)

func checkAllArgs*(tokens: seq[string];
                   leading, trailing: openArray[InputType];
                   varargType: Option[InputType] = none(InputType)) {.inline.} =
  tokens.checkLeadingTypes(leading)
  tokens.checkTrailingTypes(trailing)
  if varargType.isSome:
    tokens.checkVarargs(leading.len, trailing.len, varargType.get)
  elif tokens.len - 1 > leading.len + trailing.len:
    raise ArgumentMismatch(nth: tokens.len - 2,
                           badType: some(String),
                           expectedType: none(InputType))

func codeToCheckTokens*(args: seq[Argument], tokenIdent: string): NimNode =
  let
    toArrayLit = (s: seq[InputType]) => Bracket s.map(it => it.newLit)
    types = args.map(arg => arg.limits.inputType)
    varargIndex = types.find(Varargs)
    hasVarargs = varargIndex != -1
    (leadTypes, trailTypes) = if hasVarargs: types.partitionAt(varargIndex)
                              else: (types, @[])
    (lead, trail) = (leadTypes.toArrayLit, trailTypes.toArrayLit)
    minArgs = (leadTypes & trailTypes).toArrayLit
    token = Ident tokenIdent

  result = if hasVarargs:
    superQuote do:
      `token`.expectMinArgTypes(`minArgs`)
      `token`.checkAllArgs(`lead`, `trail`, some(`types[varargIndex].newLit`))
  else:
    superQuote do:
      `token`.expectMinArgTypes(`minArgs`)
      `token`.checkAllArgs(`lead`, `trail`)