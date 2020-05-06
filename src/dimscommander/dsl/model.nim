import options
import macros

# V-style
template `?`(T: typedesc): typedesc = Option[T]

type
  InputType* = enum
    Int, Float, String, Varargs

  InputLimits* = object
    case inputType*: InputType
    of Int, Float:
      min*, max*: ?float
    of String:
      minLength*, maxLength*: ?uint
    of Varargs:
      argType*: InputType

  Argument* = object
    label*: ?string
    limits*: InputLimits

  Handler* = object
    body*: NimNode
    paramIdent*: string

  CommandDef* = ref object
    name*: string
    help*: tuple[title: ?string, description: ?string]
    args*: ?seq[Argument]
    handler*: Handler

  CommandBot* = ref object
    commands*: seq[CommandDef]
    initializer*: ?Handler
    name*: string

  BadSyntax* = ref object of CatchableError
    node*: NimNode
    problem*: string
    suggestion*: ?string

  # Begin component concepts

  CodeParser* = concept parser
    parser.name is string
    parser.parse(NimNode) is CommandBot
  
  CodeGenerator* = concept gen
    gen.name is string
    gen.generate(CommandBot) is NimNode
    gen.generate(CommandBot).kind == nnkStmtList
