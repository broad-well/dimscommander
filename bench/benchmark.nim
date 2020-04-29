const
  BENCH_TRIALS = 10
  VERBOSE = true
  FAIL = false
  NS_PER_MS = 1e6

import logging, std/monotimes, stats
from strformat import `&`
let logger = ConsoleLogger(levelThreshold: lvlInfo)

when VERBOSE:
  logger.levelThreshold = lvlAll

proc bench*(name: string, timeLimitPerAttemptNs = high(float), attempts = 10000, body: proc()) =
  logger.log(lvlInfo, &"benchmarking {name} ({BENCH_TRIALS}x{attempts}) with time limit {timeLimitPerAttemptNs} ns...")
  
  var trialResults: array[1..BENCH_TRIALS, float]

  for trial in 1..BENCH_TRIALS:
    logger.log(lvlDebug, &"{name}: running trial {trial} of {BENCH_TRIALS}")

    # yes, there's user time and sys time, but I'm not making a full performance benchmark library.
    # the cross-platform complication of user & sys time makes it difficult.
    # also, nimble can't do devDependencies
    let start = getMonoTime().ticks
    for attempt in 1..attempts:
      body()
    let finish = getMonoTime().ticks

    let nsSpent = finish - start
    let meanNsPerAttempt = nsSpent.float64 / attempts.float64
    logger.log(lvlDebug, &"{name}: trial {trial}: {nsSpent.float64 / NS_PER_MS}ms in {attempts} => mean = {meanNsPerAttempt}ns per attempt")
    
    trialResults[trial] = meanNsPerAttempt
  
  var trialStats: RunningStat
  trialStats.push(trialResults)
  logger.log(lvlInfo, &"{name} results per attempt: {trialStats.mean():.1f} ns ± {trialStats.standardDeviation():.1f} ns")

  if trialStats.mean() > timeLimitPerAttemptNs and FAIL:
    logger.log(lvlError, &"FAIL: benchmark {name} mean ({trialStats.max:.1f} ns) above limit ({timeLimitPerAttemptNs:.1f} ns)")
    quit(1)