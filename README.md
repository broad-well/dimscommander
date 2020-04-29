# Dimscommander
Abstractions and tools for quickly building command-based Discord chatbots. Depends on KrispPurg's [Dimscord](https://github.com/krisppurg/dimscord).

## Philosophies (in this order)
* **Elegance**: The code you write using this library should be intuitively readable, utterly boring, and stylistically satisfying. In pursuit of this goal, I will have to inevitably make this library a little opinionated when it comes to macro syntax.
* **Efficiency**: Take the modern multi-core CPU's structure into consideration. Use empirical benchmarks and compiled assembly introspection to determine the most efficient implementation variant that accomplishes a certain task. Let the compiler generate optimized code from user macro declarations as much as possible.
* **Robustness**: Chatbots deal with dirty inputs. Aim for 100% test coverage of key processing logic, and include as many edge cases as necessary.

## Are We Still Fast?

**Benchmark name**|**Time per attempt**
:-----:|:-----:
tokenization|1008.9 ns
handler table|570.7 ns

_Last updated: 2020-04-29_