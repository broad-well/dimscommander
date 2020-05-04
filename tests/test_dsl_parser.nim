import ./statictest
import ../src/dimscommander/dsl/[parser, model]
from options import some
import macros
from macroutils import StmtList

template dump(t: untyped): untyped =
  debugEcho repr(t)
  t

# Nim needs to implement equality on case objects
func `==`(a, b: InputLimits): bool =
  if a.inputType != b.inputType: return false
  if a.inputType == Varargs:
    return a.argType == b.argType
  return true

static:
  block commandDefinition:
    test "accept first unnamed argument as name":
      let ast = quote do:
        command("name") as _:
          discard

      assert parseCommand(ast).name == "name"

    # I can't verify errors...

    test "accept help string literal as name only":
      let ast = quote do:
        command("exam", help="Examine the macro's implementation") as _:
          discard

      assert parseCommand(ast).help.title ==
          some("Examine the macro's implementation")

    test "accept help string literal as named tuple":
      let ast = quote do:
        command("exam", help=(title: "title help",
                              description: "title description")) as _:
          discard
          
      assert parseCommand(ast).help == (title: some("title help"),
                                        description: some("title description"))

    test "accept args as unnamed tuple of typedescs":
      let ast = quote do:
        command("typer", args=(int, float, string, varargs[int])) as _:
          discard
      
      assert parseCommand(ast).args == some(@[
        Argument(limits: InputLimits(inputType: Int)),
        Argument(limits: InputLimits(inputType: Float)),
        Argument(limits: InputLimits(inputType: String)),
        Argument(limits: InputLimits(inputType: Varargs, argType: Int))
      ])

    test "accept args as mapping array from string to typedescs":
      let ast = quote do:
        command("namedtypes", args={"first arg": int,
                                    "second arg": float,
                                    "third arg": string}) as _:
          discard
    
      assert parseCommand(ast).args == some(@[
        Argument(label: some("first arg"), limits: InputLimits(inputType: Int)),
        Argument(label: some("second arg"), limits: InputLimits(inputType: Float)),
        Argument(label: some("third arg"), limits: InputLimits(inputType: String))
      ])

    test "accept code from spec":
      let handler = quote do:
        msg.reply("hello!")
        
      let ast = quote do:
        command("test",
                help=(title: "a test command",
                      description: "allow the author to test this command."),
                args={"number of elements": int,
                      "check limits": string}) as msg:
          `handler`
      
      let expected = CommandDef(
        name: "test",
        help: (title: some("a test command"),
               description: some("allow the author to test this command.")),
        args: some(@[
          Argument(label: some("number of elements"), limits: InputLimits(inputType: Int)),
          Argument(label: some("check limits"), limits: InputLimits(inputType: String))
        ]),
        handler: StmtList(handler),
        handlerParamIdent: "msg"
      )
      let actual = parseCommand(ast)
      
      # Miraculously "assert expected == actual" fails here. Idk why.
      assert expected.name == actual.name
      assert expected.help == actual.help
      assert expected.args == actual.args
      assert expected.handler == actual.handler
      assert expected.handlerParamIdent == actual.handlerParamIdent
