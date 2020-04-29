import ../src/dimscommander/command
import ./benchmark

bench("tokenization", timeLimitPerAttemptNs=1500, attempts=40000) do:
    discard commandCallTokens("""!test 5&2*4^1_4\5\a "st2 1m 55a')" "man"""")

var table = CommandHandlerTable()
table.addHandler("test") do (c: CommandCall):
    discard
table.addHandler("exam") do (c: CommandCall):
    discard

bench("handler table", timeLimitPerAttemptNs=800, attempts=15000) do:
    for cmd in ["test", "a", "b", "long string", "exam"]:
        discard table.handle(@[cmd], nil)