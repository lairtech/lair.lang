# Lair Language
The breeding ground for incrementaly building a language from scratch step by step. The implementation language for the reference implementation will be Julia for now. Others may follow.

# Incremental Steps
Each of the steps for building up a language will be small and incrementally build on the previous steps. Each of those steps will deal with one concept or a few cut down concepts needed to solve the actual problem. Some steps will generalize the problems that where solved in previous steps to make the implementation and/or the language more flexible.

Also after each step we have a working interpreter for build up language so far.

Each julia implemenation for the step can be found under `julia/<step-numer>.lair.jl`

If you just use the step descriptions to build up your own implementation it's properly wise to follow the rought order but feel free to skip around as you please.

## Step 01: The REPL
To get something simple up and running as fast as possible we will start with a interactive skeleton echo interpreter that just read a line from the input just echo it back to the user. 

Really nothing fancy but it already consists of the 3 dummy functions that will later be modified/extended:
* parseExp: Parses the given input string
* evalExp: Evaluates the the parsed expression
* printExp: Just print the given expression

The `lairRepl` function for the interactive skeleton interpreter itself do the following steps in a infinite loop for now:
   * print the prompt `lair>`
   * read a line from input
   * if the input is `exit` abort the endless loop
   * create a expression by parsing the input with `parseExp`
   * evaluates the parsed expression with `evalExp`
   * print the evaluated expression with `printExp`
   * repeat from beginnig

