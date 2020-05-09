import ../dsl/model
import options

type ArgumentMismatch* = ref object of CatchableError
  nth*: int # starts from 0
  badType*: Option[InputType]
  expectedType*: Option[InputType]

# through an informal benchmark, I have found that
# this manual solution is about 7x faster than matching
# a pre-compiled regex pattern
func isInt(str: string): bool {.inline.} =
  var i = if str[0] in {'+', '-'}: 1 else: 0
  while i < str.len:
    if str[i] notin '0'..'9':
      return false
    i += 1
  return true

func checkToken(tokens: seq[string], i: int,
                expected: InputType) =

  template require(token: string, checkFunc: typed) =
    if not checkFunc(token):
      raise ArgumentMismatch(nth: i, badType: some(String),
                             expectedType: some(expected))
  case expected
  of Int: tokens[i + 1].require(isInt)
  else: discard

func matchTokens*(args: openArray[InputType], tokens: seq[string]): void =
  let givenArgCount = tokens.len - 1

  if givenArgCount < args.len:
    raise ArgumentMismatch(
      nth: givenArgCount, badType: none(InputType),
      expectedType: some(args[givenArgCount]))
  elif givenArgCount > args.len:
    raise ArgumentMismatch(
      nth: args.len, badType: some(String),
      expectedType: none(InputType))

  for (i, arg) in args.pairs():
    tokens.checkToken(i, arg)