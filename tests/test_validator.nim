import options, macros
import ./statictest
import ../src/dimscommander/dsl/[model, validator]

static:
  block validateSurfaceMetadata:
    test "Rejects empty name":
      let bot = CommandBot(
          commands: @[],
          initializer: none(NimNode),
          name: "")
      assertError(InvalidSemantics, "Bot name cannot be empty"):
        bot.validate()

    test "Rejects name with only whitespace":
      let bot = CommandBot(
          commands: @[],
          initializer: none(NimNode),
          name: "  \t\t\n\r")
      assertError(InvalidSemantics, "Bot name cannot be empty"):
        bot.validate()

    test "Rejects wrong initializer kind":
      let bot = CommandBot(
          commands: @[],
          initializer: some(newIdentNode("idk")),
          name: "testbot")
      assertError(BadSyntax, "Bot initializer must be a StmtList"):
        bot.validate()

  block validateCommands:
    test "Rejects duplicate commands with same name":
      let bot = CommandBot(
          commands: @[CommandDef(name: "?test"), CommandDef(name: "?test")],
          name: "TestBot")
      assertError(InvalidSemantics, "2 commands with name \"?test\" found!"):
        bot.validate()

    test "Rejects varargs[varargs] in InputLimits":
      let bot = CommandBot(
        commands: @[CommandDef(
          name: "!test",
          args: some(@[Argument(
            limits: InputLimits(inputType: Varargs, argType: Varargs))]))],
        name: "VarargsBot")

      assertError(InvalidSemantics, "Cannot have input type varargs[varargs]"):
        bot.validate()
