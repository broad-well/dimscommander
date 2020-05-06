import ./statictest
import ../src/dimscommander/dsl/[parser, model]
from options import some, none
import macros
from sequtils import mapIt
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

    test "reject call with unknown arguments":
      let ast = quote do:
        command("test", unknown=2, idk=1) as t:
          discard

      assertBadSyntax("Unknown named parameter: unknown"):
        discard parseCommand(ast)

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

    test "reject help table constructor and others":
      let nonconforming = [
        quote do: {"title": "title", "description": "descr"}
        ,quote do: 42
        ,quote do: 'x'
      ]
      for nonconform in nonconforming:
        let ast = quote do:
          command("test", help=`nonconform`) as c:
            discard c

        assertBadSyntax("Unsupported assignment target for help"):
          discard parseCommand(ast)

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

    test "reject args as string or boolean, etc.":
      let nonconforming = [
        quote do: "args are not strings"
        ,quote do: true
        ,quote do: [4, 1, 5]
      ]

      for nonconform in nonconforming:
        let ast = quote do:
          command("test", args=`nonconform`) as e:
            discard e

        assertBadSyntax("Unsupported assignment target for args"):
          discard parseCommand(ast)

    test "reject args as named tuple with specific error":
      let ast = quote do:
        command("test", args=(first: int, second: float)) as cmd:
          discard cmd

      assertBadSyntax("Args cannot be a named tuple"):
        discard parseCommand(ast)

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
        handler: Handler(body: StmtList(handler), paramIdent: "msg")
      )
      let actual = parseCommand(ast)

      # Miraculously "assert expected == actual" fails here. Probably because
      # we are comparing ref objects?
      assert expected.name == actual.name
      assert expected.help == actual.help
      assert expected.args == actual.args
      assert expected.handler == actual.handler

  block commandSetDefinition:
    test "accept empty commands block":
      let ast = quote do:
        commands("]"):
          discard

      let commands = parseCommands(ast)
      assert commands.len == 0

    test "commands block adds prefix to 1 subcommand":
      let ast = quote do:
        commands("]"):
          command("test") as msg:
            discard msg

      let commands = parseCommands(ast)
      assert commands[0].name == "]test"

    test "commands block adds prefix to many subcommands":
      let ast = quote do:
        commands(">"):
          command("make") as m:
            discard m
          command("gcc") as g:
            discard g
          command("clang") as c:
            discard c

      let commands = parseCommands(ast)
      assert commands.mapIt(it.name) == @[">make", ">gcc", ">clang"]

  block topLevelBlocks:
    test "extract setup block":
      let body = quote do:
        echo "hello bot!"

      let ast = quote do:
        setup:
          `body`

      let handler = parseSetupBlock(ast)
      assert handler == StmtList body

  block integrationTests:
    test "defineDiscordBot passes name and ident":
      let ast = quote do:
        defineDiscordBot(bot, "A test bot"):
          discard

      let bot = parseTopLevel(ast)
      assert bot.name == "A test bot"
      assert bot.clientIdent == "bot"
      assert bot.commands.len == 0
      assert bot.initializer == none(NimNode)

    test "defineDiscordBot dispatches commands block":
      let ast = quote do:
        defineDiscordBot(client, "A test client"):
          commands("&"):
            command("cmd") as cmd:
              discard cmd

      let bot = parseTopLevel(ast)
      assert bot.commands.len == 1
      assert bot.commands[0].name == "&cmd"

    test "defineDiscordBot dispatches command block":
      let ast = quote do:
        defineDiscordBot(client, "A test client"):
          command(">cmd") as cmd:
            discard

      let bot = parseTopLevel(ast)
      assert bot.commands.len == 1
      assert bot.commands[0].name == ">cmd"

    test "defineDiscordBot dispatches setup block":
      let setup = quote do: discard
      let ast = quote do:
        defineDiscordBot(client, "A test client"):
          setup:
            `setup`

      let bot = parseTopLevel(ast)
      assert bot.initializer == some(StmtList setup)
