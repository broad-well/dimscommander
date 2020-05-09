import ../src/dimscommander/dsl/model

# For now, we just unwrap the block

template test*(name: string, body: untyped): untyped =
  try:
    block:
      body
    echo "[PASS] \"" & name & "\" :D"
  except AssertionError as err:
    echo "\u001b[31m[FAIL] \"" & name & "\"\n ↳ " & err.msg & "\u001b[0m"
    quit(QuitFailure)

template assertError*(errtype: typedesc, prob: string, body: untyped): untyped =
  block:
    try:
      body
      assert false, $errtype & " error was not thrown"
    except errtype as exc:
      assert exc.msg == prob, $errtype & " problem mismatch"
