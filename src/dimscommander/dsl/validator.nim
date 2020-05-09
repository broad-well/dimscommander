import ./model
import options, macros, tables
from strutils import isEmptyOrWhitespace
from strformat import `&`
from sequtils import mapIt, filterIt

type InvalidSemantics* = ref object of CatchableError
  suggestion*: Option[string]

func validateArgument(arg: Argument) =
  if arg.limits.inputType == Varargs and arg.limits.argType == Varargs:
    raise InvalidSemantics(
      msg: "Cannot have input type varargs[varargs]",
      suggestion: some("If you wish to have no type restraints on each argument, use 'string'."))

template `:=`(varIdent: typed, value: typed): bool =
  if value.isSome:
    varIdent = value.unsafeGet
    true
  else:
    false

func validate*(bot: CommandBot) =
  if bot.name.isEmptyOrWhitespace:
    raise InvalidSemantics(
      msg: "Bot name cannot be empty",
      suggestion: some("Give your bot a name, like 'BobTheBot'."))

  var init: NimNode
  if (init := bot.initializer) and init.kind != nnkStmtList:
    raise BadSyntax(
      node: init,
      msg: "Bot initializer must be a StmtList",
      suggestion: some("This is most likely a macro parser problem. Please let the author know!"))

  let commandNameTable = toCountTable(bot.commands.mapIt(it.name))
  for (name, occur) in commandNameTable.pairs():
    if occur > 1:
      raise InvalidSemantics(
        msg: &"{occur} commands with name \"{name}\" found!",
        suggestion: some(&"Each command must have a unique name. " &
                    &"Remove {occur-1} declaration(s) with name \"{name}\" to fix this problem"))

  for cmd in bot.commands:
    for arg in cmd.args.get(@[]):
      validateArgument(arg)