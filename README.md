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

## Step 02: Booleans
General purpose languages consists of primitive types, compound types and means of abstraction.For now we will just deal with one of the simples primitive types: `Booleans`. 
They are so simple because they just conists of 2 the states `true` and `false` and like all primitive types evaluate to themself which make evaluation just like before the identity function.

Also Parsing will be simple because we can just match the input string against `true` or `false` and convert that to a boolean type and treat all other input as unkown expressions.
Printing will equally be simple. Just print `true` for `true` booleans and `false` for `false` booleans.

So in conlusion the grammer for our boolean language is
```
Program -> Boolean
Boolean -> "true" | "false"
```
And the abstract expressions just consists of Booleans
```
Expression = Boolean
Boolean = true | false
```

## Step 03: PEG Recognizer
Our approach to parsing, evaluation und printing for the `Boolean` language is nice and simple. But even just adding integers to our `Boolean` language would need a more sophisticated parser than just the string matcher logic we have for now. So let's write a simple PEG (Parsing Expression Grammer) Recognizer for our `Boolean` language that for now will just recoginze literal string. In our case `true` and `false`

To do so we write a `match` function that takes a `Pattern`, an input string and an index where in the sring to start matching the against the pattern. The function will just return the index position after the matched `Pattern` or nothing.

For parsing `Boolean`s we just need 2 `Pattern`s:
* `Literal` will hold a string that will literaly be matched against the input string at the actual index position and returns the index + length of the matched string
* `OrderedChoice` will hold multiple `Pattern` in order and try to match them one at a time against the input string at the index position. The first `Pattern` that matches will be the result of the `OrderedChoice`

With just that 2 Patterns and the `match` functions we can implement out PEG recognizer for `Boolean`s that will return the index until it matched or nothing. If we matched nothing we just return nothing from the `parseExpr` function. If we matched something we will check if the index is after the last index of the input string. Later on we will properly improve the match function to support hole or nothing matches but for now that is enough.

For convenience we may use operator overloading and pattern constructing functions to make a small PEG dsl grammer that is better readable.

## Step 04: PEG Parser
