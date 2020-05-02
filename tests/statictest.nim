# For now, we just unwrap the block

template test*(name: string, body: untyped): untyped =
  block:
    body
