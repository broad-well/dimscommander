# Package

version       = "0.1.0"
author        = "broad-well"
description   = "Command abstraction and DSL on top of dimscord"
license       = "MIT"
srcDir        = "src"

task bench, "Runs benchmark tests":
  exec "nim c -r bench/bench_*.nim"

# Dependencies

requires "nim >= 1.2.0", "dimscord >= 0.0.9"
