import options

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
    
  CommandDef* = ref object
    name*: string
    help*: tuple[title: ?string, description: ?string]
    args*: ?seq[Argument]
    handler*: NimNode
    handlerParamIdent*: string
