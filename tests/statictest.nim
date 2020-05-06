import ../src/dimscommander/dsl/model

# For now, we just unwrap the block

template test*(name: string, body: untyped): untyped =
  block:
    body

template assertBadSyntax*(prob: string, body: untyped): untyped =
  block:
    try:
      body
      assert false, "BadSyntax error was not thrown"
    except BadSyntax as exc:
      assert exc.problem == prob, "BadSyntax problem mismatch"
      assert exc.node != nil