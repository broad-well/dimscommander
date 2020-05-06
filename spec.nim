import macros

dumpTree:
  defineDiscordBot(bot, name="A test bot"):
    # This specifies a set of commands whose prefix is "*"
    commands("*"):
      # This specifies a command invoked via "*test <int> <string>"
      command("test",
              help=(title: "a test command",
                    description: "allow the author to test this command."),
              args={"number of elements": int,
                    "check limits": string}) as msg:
        msg.reply("hello!")

      command("test alt",
              help="alternative help syntax with brief title only",
              args=(int, varargs[string])) as msg:
        msg.react("😁")
        msg.author.dm("hello alt user")

    setup:
      # Specify custom event handlers here
      bot.events.message_create = proc (s: Shard, m: Message) =
        discard
