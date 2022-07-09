# Lair Language
The breeding ground for incrementally building a language from scratch step by step implemented in Julia.

# Incremental Steps
Each of the steps for building up a language will be small and incrementally build on the previous steps. Each of those steps will deal with one concept or a few cut down concepts needed to solve the actual problem. Some steps will generalize the problems that where solved in previous steps to make the implementation and/or the language more flexible.

Also after each step we have a working interpreter for the language build up so far.

Each julia implemenation for the steps can be found under `julia/<chapter>/<step-number>.lair.jl`

If you just use the step descriptions to build up your own implementation it's properly wise to follow the rought order but feel free to skip around as you please.

## 01 - Skeleton Interpreter
To get something simple up and running as fast as possible we will start with a interactive skeleton echo interpreter that just read a line from the input and just echo it back to the user. 

### Step 01: The REPL
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

## 02 - Selfevaluating Primitive Types & Simple PEG Parser
General purpose languages consists of primitive types, compound/composite types and means of abstraction. To keep things as simple as possible for now we will first implement all the basic selfevaluation primitive types. That way we don't need to deal with different evaluation rules and can just pass through the types in the eval function (identity function) and only need to touch the parsing and printing functions. If the implementation language you are using don't support the type, it may not be a bad idea to just follow along the parsing stuff and later on when we handle types more thoughfully revisit that step. 

While we add more and more primitive types we will also develop a simple PEG parser along it that we extend bit by bit to match the needed parsing features we need. At the end of it all the parsing we should have a PEG parser, that is basically just a configureable recrusive decent parser that could also be used, extendend or improved for other needs besides this project.

### Step 02: Booleans
The first primitive type we will implement is the `Boolean` type because it's one of the simplest ones from a parsing and printing perspective. Because they just conists of 2 the states `true` and `false` the parsing boils down to match against the strings `true` or `false` and convert that to a boolean type and treat all other input as unkown expressions.
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

### Step 03: PEG Recognizer
Our approach to parsing, evaluation und printing for the `Boolean` language is nice and simple. But even just adding integers to our `Boolean` language would need a more sophisticated parser than just the string matcher logic we have for now. So let's write a simple PEG (Parsing Expression Grammer) Recognizer for our `Boolean` language that for now will just recoginze literal string. In our case `true` and `false`

To do so we write a `match` function that takes a `Pattern`, an input string and an index where in the sring to start matching the against the pattern. The function will just return the index position after the matched `Pattern` or nothing.

For parsing `Boolean`s we just need 2 `Pattern`s:
* `Literal` will hold a string that will literaly be matched against the input string at the actual index position and returns the index + length of the matched string
* `OrderedChoice` will hold multiple `Pattern` in order and try to match them one at a time against the input string at the index position. The first `Pattern` that matches will be the result of the `OrderedChoice`

With just that 2 Patterns and the `match` functions we can implement out PEG recognizer for `Boolean`s that will return the index until it matched or nothing. If we matched nothing we just return nothing from the `parseExpr` function. If we matched something we will check if the index is after the last index of the input string. Later on we will properly improve the match function to support hole or nothing matches but for now that is enough.

For convenience we may use operator overloading and pattern constructing functions to make a small PEG dsl grammer that is better readable. 

PEG dsl grammer for the language up so far:
```julia
booleanPattern = "true" + "false"
```

### Step 04: PEG Parser
Until now we just had developed a small PEG regonizer but what we actually want is parser that will return an abstract synatx tree with the right datatypes instead of just the matched index. So we first extend our results of the match functions to return 2 things, the index as before and the new capture. 

Then we introduce a `Capture` pattern that just hold a pattern. The match function for the `Capture` just remembers the start index and then matches the pattern and when it's a successful match it will return the index and the actual matched String from the start index until the end index (that it also will return).

So now we have the possiblity to extract the relevant text for our parser with the `Capture` patterns. But they are still just strings so let's add another pattern `Transform` that holds a pattern and a tranformation function. The match function for the transform pattern just matchs the pattern and if it matches and also have a caputre it will apply the transformation function to the capture.

We can now rewrite our `booleanPattern = "true" + "false"` to a pattern that capture the true/false and then transform it into a boolean value with the following pattern `booleanPattern = c("true" + "false") / m -> m == "true"` and reduce the `parseExp` function just to a call to match function and return the capture if there is a match otherwise we return nothing.

PEG dsl grammer for the language up so far:
```julia
booleanPattern = c("true" + "false") / m -> m == "true"
```

### Step 05: Integers
The next primitive type we will add are 64 bit integers. For that we need to extend our PEG Parser to support character ranges, repeat/optional and sequence patterns. 

Implementing the `CharRange` Pattern is easy. It just hold the min char and the max char. The match function just checks if the text length is still in range of the actual index and then checks if the char at that index is >= min char and <= max char. If so it returns the actual index + 1 otherwise `nothing` as usual.

Implementing the `Repeat` patterns are a bit harder. It holds a count and the pattern that will be checked for the repeats. Counts >= 0 must match the pattern repeatendly at least the count times but can match arbitary more times the pattern. While counts < 0 will optionally match the pattern up to the negativ count. Regex whise is a `count = 0` = `pattern*`, `count > 0` = `pattern^count*pattern*` and `count < 0` = `(pattern?)^count`.

The last bit we need is a `Sequence` pattern that allowes us to make a sequential list of patterns that must match one after the other. The `Sequence`pattern hold just that sequential list and test one pattern after the other, only if all match it will return a match. Otherwise `nothing`.

With that 3 additional pattern we can now express integers with or without a leading sign and convert the caputed integer string to and `Int64` with some operator overloading like:
`integerPattern = c(("-" + "+") ^ -1 * range('0', '9') ^ 1) / i -> parse(Int64, i)`

The last bit of changes to support also integers in the interpreter is to combine the `booleanPattern` and `integerPattern` with an `OrderedChoice` like `primitivePattern = booleanPattern + integerPattern` and use that now in the `parsingExp`. We may also need to change the `printExp` to handle integer printing.

PEG dsl grammer for the language up so far:
```julia
booleanPattern = c("true" + "false") / m -> m == "true"
integerPattern = c(("-" + "+") ^ -1 * range('0', '9') ^ 1) / i -> parse(Int64, i)
primitivePattern = booleanPattern + integerPattern
```

### Step 06 - Strings
String will be represented with `"` as delimiter and also have the usual escapes sequences like `\"`, `\n` etc. So we use an PEG sequence to match the beginning and ending `"`. But the string content in between can be any char except `"` or `\` or the escape sequences `\n`, `\r`, `\t`, `\\` and `\"` with is the escaped `"` and will not be confused with the string ending.

To do that we extend our PEG parser with an `AnyChar` pattern that will hold the count of the characters to match. If positive we match the exact count of any character otherwise we return `nothing`. If the count is negative we match only there are -count character left.
We also will introduce a `Negate` pattern that holds a pattern and only matches if the pattern doesn't match. It will not consume any input on a match. For convenience we will overload overload the `pattern1 - pattern2` that will be translated to a `Sequence` with a `Negate` with pattern2 followed by pattern1.

Also enabled simple capture transfering support in the sequence. Need to improve and generalize that later on.

And of course to support the printing of the strings we extended the `printExp` with string support.

PEG dsl grammer for the language up so far:
```julia
booleanPattern = c("true" + "false") / m -> m == "true"
integerPattern = c(("-" + "+") ^ -1 * range('0', '9') ^ 1) / i -> parse(Int64, i) 
stringEscapePattern = p("\\\"") + p("\\\\") + p("\\n") + p("\\r") + p("\\t")
stringPattern = "\"" * c((stringEscapePattern + (1 - (p("\"") + p("\\")))) ^ 0) * "\""
primitivePattern = booleanPattern + integerPattern + stringPattern
```
