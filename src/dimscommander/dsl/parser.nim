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
    error("Unsupported assignment target for help." &
          " Try a string literal (\"...\") or a named tuple (title: ..., description: ...)", target)

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
    this.parseCommandArgsTuple(target)
  of nnkTableConstr:
    this.parseCommandArgsTable(target)
  else:
    error("Unsupported assignment target for args." &
          " Try a tuple (int, int, float) or a table constructor ({\"first param\": int})", target)
  
func parseCallAssign(this: var CommandDef, attribute: string, target: NimNode) =
  case attribute
  of "help":
    this.parseHelp(target)
  of "args":
    this.parseCommandArgs(target)
  else:
    error("Unknown named parameter: " & attribute &
          "; available parameters are 'help' and 'args'", target)


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
  result.handler = handler
  result.handlerParamIdent = handlerInput.strVal
