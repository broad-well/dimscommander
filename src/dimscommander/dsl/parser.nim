import ./model
import macros
import macroutils
import options

func parseHelpTextTuple(this: var CommandDef, target: NimNode) =
  for asgn in target.children():
    case asgn[0].strVal
    of "title":
      this.help.title = some(asgn[1].strVal)
    of "description":
      this.help.description = some(asgn[1].strVal)
    else:
      error("Unknown named tuple item in help definition: " & asgn[0].strVal &
            "; available values are 'title' and 'description'", asgn[0])

func parseHelp(this: var CommandDef, target: NimNode) =
  case target.kind
  of nnkPar: this.parseHelpTextTuple(target)
  of nnkStrLit: this.help.title = some(target.strVal)
  else:
    raise BadSyntax(
      node: target,
      msg: "Unsupported assignment target for help",
      suggestion: some("Try a string literal (\"...\") or " &
                       "a named tuple (title: ..., description: ...)"))

func singleArgToInputLimits(desc: NimNode): InputLimits =
  result.inputType = case desc.strVal
  of "int": Int
  of "float": Float
  of "string": String
  else:
    error("Invalid argument type: " & desc.strVal & ". Possible values are int, float, string", desc)
    return

func varargsToInputLimits(call: NimNode): InputLimits =
  expectIdent(call[1], "varargs")
  let argType = singleArgToInputLimits(call[2])
  return InputLimits(inputType: Varargs, argType: argType.inputType)

func typedescToInputLimits(desc: NimNode): InputLimits =
  result = case desc.kind
  of nnkCall: varargsToInputLimits(desc)
  of nnkSym: singleArgToInputLimits(desc)
  else:
    error("Invalid input limit. Must be Call (varargs) or Sym (a single type)", desc)
    return

func parseCommandArgsTable(this: var CommandDef, table: NimNode) =
  var args = newSeqOfCap[Argument](table.len)
  for colonExpr in table:
    colonExpr.expectKind nnkExprColonExpr
    colonExpr.expectLen 2
    let
      label = colonExpr[0].strVal
      typeDesc = colonExpr[1]
    args.add Argument(label: some(label), limits: typedescToInputLimits(typeDesc))

  this.args = some(args)

func parseCommandArgsTuple(this: var CommandDef, target: NimNode) =
  var args = newSeqOfCap[Argument](target.len)
  for arg in target.children():
    args.add Argument(limits: typedescToInputLimits(arg))
  this.args = some(args)

func parseCommandArgs(this: var CommandDef, target: NimNode) =
  case target.kind
  of nnkPar:
    if target.len > 0 and target[0].kind == nnkExprColonExpr:
      raise BadSyntax(
        node: target,
        msg: "Args cannot be a named tuple",
        suggestion: some("Try an unnamed tuple (int, float) or a table constructor" &
                         "({\"param\": int})"))
    this.parseCommandArgsTuple(target)
  of nnkTableConstr:
    this.parseCommandArgsTable(target)
  else:
    raise BadSyntax(
      node: target,
      msg: "Unsupported assignment target for args",
      suggestion: some("Try a tuple (int, int, float) or a " &
                       "table constructor ({\"first param\": int})"))

func parseCallAssign(this: var CommandDef, attribute: string, target: NimNode) =
  case attribute
  of "help":
    this.parseHelp(target)
  of "args":
    this.parseCommandArgs(target)
  else:
    raise BadSyntax(
      node: target,
      msg: "Unknown named parameter: " & attribute,
      suggestion: some("Available parameters are 'help' and 'args'"))


func parseCallParams(this: var CommandDef, call: seq[NimNode]) =
  this.name = call[0].strVal

  for assignIndex in 1 ..< call.len:
    let
      assign = call[assignIndex] # "help=(...)"
      attribute = assign[0].strVal
      target = assign[1]
    this.parseCallAssign(attribute, target)


func parseCommand*(ast: NimNode): CommandDef =
  var callArgs = newSeq[NimNode]()
  var handlerInput, handler: NimNode

  StmtList(ast).extract do:
    command(`callArgs*`) as `handlerInput`:
      `handler`

  new(result)
  result.parseCallParams(callArgs)
  result.handler = Handler(body: handler, paramIdent: handlerInput.strVal)


func parseCommands*(ast: NimNode): seq[CommandDef] =
  ast.expectKind nnkCall
  ast[0].expectIdent "commands"
  ast[1].expectKind nnkStrLit
  ast[2].expectKind nnkStmtList
  let
    prefix = ast[1].strVal
    children = ast[2]

  for child in children:
    if child.kind != nnkDiscardStmt:
      var command = parseCommand(child)
      command.name = prefix & command.name
      result.add command

func parseSetupBlock*(ast: NimNode): NimNode =
  ast.expectKind nnkCall
  ast.expectLen 2
  ast[0].expectIdent "setup"
  ast[1].expectKind nnkStmtList

  return ast[1]

func dispatchDefCall(bot: var CommandBot, call: NimNode) =
  call.expectMinLen 2

  case call[0].strVal
  of "commands":
    bot.commands.add(parseCommands(call))
  of "setup":
    bot.initializer = some(parseSetupBlock(call))
  else:
    if call.kind == nnkInfix and call[1][0].strVal == "command":
      bot.commands.add(parseCommand(call))
    else:
      error("unknown directive", call)

func parseTopLevel*(defBody: NimNode): CommandBot =
  defBody.expectKind nnkStmtList
  new(result)
  for call in defBody:
    if call.kind != nnkDiscardStmt:
      result.dispatchDefCall(call)
