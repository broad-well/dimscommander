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
            "; available values are 'title' and 'description'")

func parseHelp(this: var CommandDef, target: NimNode) =
  case target.kind
  of nnkPar: this.parseHelpTextTuple(target)
  of nnkStrLit: this.help.title = some(target.strVal)
  else:
    error("Unsupported assignment target for help." &
          " Try a string literal (\"...\") or a named tuple (title: ..., description: ...)")

func typedescToInputLimits(desc: NimNode): InputLimits
func varargsToInputLimits(call: NimNode): InputLimits =
  expectIdent(call[1], "varargs")
  let argType = typedescToInputLimits(call[2])
  return InputLimits(inputType: Varargs, argType: argType.inputType)

func typedescToInputLimits(desc: NimNode): InputLimits =
  if desc.kind == nnkCall:
    return varargsToInputLimits(desc)

  expectKind(desc, {nnkSym})
  result.inputType = case desc.strVal
  of "int": Int
  of "float": Float
  of "string": String
  else:
    error("Invalid argument type: " & desc.strVal & ". Possible values are int, float, string")
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
          " Try a tuple (int, int, float) or a table constructor ({\"first param\": int})")
  
func parseCallAssign(this: var CommandDef, attribute: string, target: NimNode) =
  case attribute
  of "help":
    this.parseHelp(target)
  of "args":
    this.parseCommandArgs(target)
  else:
    error("Unknown named parameter: " & attribute &
          "; available parameters are 'help' and 'args'")


func parseCallParams(this: var CommandDef, call: seq[NimNode]) =
  this.name = call[0].strVal
  
  for assignIndex in 1 ..< call.len:
    let assign = call[assignIndex]
    let attribute = assign[0].strVal
    let attrValue = assign[1]
    
    this.parseCallAssign(attribute, attrValue)
    

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
