<div align="center">
<img src="img/dimscommander.png" height="80">
<h1>Dimscommander</h1>
Abstractions and tools for quickly building command-based Discord chatbots.
Depends on KrispPurg's <a href="https://github.com/krisppurg/dimscord">Dimscord</a>.
</div>

## Philosophies (in this order)

* **Elegance**: The code you write using this library should be intuitively **readable**, utterly **boring**, and stylistically **satisfying**. In pursuit of this goal, I will have to inevitably make this library a little opinionated when it comes to macro syntax.
* **Efficiency**: Take the modern multi-core CPU's structure into consideration. Use empirical benchmarks and compiled assembly introspection to determine the most efficient implementation variant that accomplishes a certain task. Let the compiler generate optimized code from user macro declarations as much as possible.
* **Robustness**: Chatbots deal with dirty inputs. Aim for 100% test coverage of key processing logic, and include as many edge cases as necessary.

## Overview of Process

For maximum flexibility, the Dimscommander operational process is split into two components: **Parsing macro syntax** and **generating code for Dimscord**. A relatively stable intermediate representation is stored as [objects](src/dimscommander/dsl/model.nim) in the Nim compiler VM. An optimal implementation is included for each component, and these implementations are independently developed and tested.

### Included Implementations

* **Parsing macro syntax**: Standard

* **Generating code for Dimscord**: CaseBrancher [WIP], HandlerTable [WIP]

## Are We Still Fast?

| **Benchmark name** | **Time per attempt** |
|:------------------ |:-------------------- |
| tokenization       | 2018.2 ns            |
| handler table      | 782.2 ns             |
