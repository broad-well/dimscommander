import macros

dumpTree:
  commands("*"):
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
      
  on_message_create as evt:
    discard
