# Lair Language
The breeding ground for incrementally building a language from scratch step by step implemented in Julia.

# Incremental Steps
Each of the steps for building up a language will be small and incrementally build on the previous steps. Each of those steps will deal with one concept or a few cut down concepts needed to solve the actual problem. Some steps will generalize the problems that where solved in previous steps to make the implementation and/or the language more flexible.

Also after each step we have a working interpreter for the language build up so far.

Each Julia implementation for the steps can be found under `julia/<chapter-number>/<step-number>`. The interpreter can be found there under `lair.jl` and it's support files like `peg.jl`.

To start the REPL load the `lair.jl` file of interest and start the REPL with `Lair.repl()`.

If you just use the step descriptions to build up your own implementation it's properly wise to follow the rough order but feel free to skip around as you please.

Chapter's and Step's so far:
- [01 - Skeleton Interpreter](#01---skeleton-interpreter)
   - [01.01 - The REPL](#0101---the-repl)
- [02 - Self Evaluating Primitive Types & Simple PEG Parser](#02---self-evaluating-primitive-types--simple-peg-parser)
   - [02.01 - Booleans](#0201---booleans)
   - [02.02 - PEG Recognizer](#0202---peg-recognizer)
   - [02.03 - PEG Parser](#0203---peg-parser)
   - [02.04 - Integers](#0204---integers)
   - [02.05 - Strings](#0205---strings)
- [03 - Generic Interpreter](#03---generic-interpreter)
   - [03.01 - Type Directed Interpreter](#0301---type-directed-interpreter)
   - [03.02 - PEG Parser Dynamic Grammar Support](#0302---peg-parser-dynamic-grammar-support)
   - [03.03 - Arrays & Multiple PEG Captures](#0303---arrays--multiple-peg-captures)

## 01 - Skeleton Interpreter
To get something simple up and running as fast as possible we will start with a interactive skeleton echo interpreter that just read a line from the input and just echo it back to the user. 

### 01.01 - The REPL
Really nothing fancy but it already consists of the 3 dummy functions that will later be modified/extended:
* `Lair.parse`: Parses the given input string
* `Lair.eval`: Evaluates the the parsed expression
* `Lair.print`: Just print the given expression

The `Lair.repl` function for the interactive skeleton interpreter itself do the following steps in a infinite loop for now:
   * print the prompt `lair>`
   * read a line from input
   * if the input is `exit` abort the endless loop
   * create a expression by parsing the input with `Lair.parse`
   * evaluates the parsed expression with `Lair.eval`
   * print the evaluated expression with `Lair.print`
   * repeat from beginning

## 02 - Self Evaluating Primitive Types & Simple PEG Parser
General purpose languages consists of primitive types, compound/composite types and means of abstraction. To keep things as simple as possible for now we will first implement all the basic self evaluation primitive types. That way we don't need to deal with different evaluation rules and can just pass through the types in the eval function (identity function) and only need to touch the parsing and printing functions. If the implementation language you are using don't support the type, it may not be a bad idea to just follow along the parsing stuff and later on when we handle types more thoughtfully revisit that step. 

While we add more and more primitive types we will also develop a simple PEG parser along it that we extend bit by bit to match the needed parsing features we need. At the end of it all the parsing we should have a PEG parser, that is basically just a configurable recursive decent parser that could also be used, extended or improved for other needs besides this project.

### 02.01 - Booleans
The first primitive type we will implement is the `Boolean` type because it's one of the simplest ones from a parsing and printing perspective. Because they just consists of 2 the states `true` and `false` the parsing boils down to match against the strings `true` or `false` and convert that to a Boolean type and treat all other input as unknown expressions.
Printing will equally be simple. Just print `true` for `true` Booleans and `false` for `false` Booleans.

So in conclusion the grammar for our Boolean language is
```
Program -> Boolean
Boolean -> "true" | "false"
```
And the abstract expressions just consists of Booleans
```
Expression = Boolean
Boolean = true | false
```

### 02.02 - PEG Recognizer
Our approach to parsing, evaluation und printing for the `Boolean` language is nice and simple. But even just adding integers to our `Boolean` language would need a more sophisticated parser than just the string matcher logic we have for now. So let's write a simple PEG (Parsing Expression Grammar) Recognizer for our `Boolean` language that for now will just recognize literal string. In our case `true` and `false`

To do so we write a `match` function that takes a `Pattern`, an input string and an index where in the string to start matching the against the pattern. The function will just return the index position after the matched `Pattern` or nothing.

For parsing `Boolean`s we just need 2 `Pattern`s:
* `Literal` will hold a string that will literally be matched against the input string at the actual index position and returns the index + length of the matched string
* `OrderedChoice` will hold multiple `Pattern` in order and try to match them one at a time against the input string at the index position. The first `Pattern` that matches will be the result of the `OrderedChoice`

With just that 2 Patterns and the `match` functions we can implement out PEG recognizer for `Boolean`s that will return the index until it matched or nothing. If we matched nothing we just return nothing from the `Lair.parse` function. If we matched something we will check if the index is after the last index of the input string. Later on we will properly improve the match function to support hole or nothing matches but for now that is enough.

For convenience we may use operator overloading and pattern constructing functions to make a small PEG domain specific language grammar that is better readable. 

PEG DSL grammar for the language up so far:
```julia
booleanPattern = "true" + "false"
```

### 02.03 - PEG Parser
Until now we just had developed a small PEG recognizer but what we actually want is parser that will return an abstract syntax tree with the right datatypes instead of just the matched index. So we first extend our results of the match functions to return 2 things, the index as before and the new capture. 

Then we introduce a `Capture` pattern that just hold a pattern. The match function for the `Capture` just remembers the start index and then matches the pattern and when it's a successful match it will return the index and the actual matched String from the start index until the end index (that it also will return).

So now we have the possibility to extract the relevant text for our parser with the `Capture` patterns. But they are still just strings so let's add another pattern `Transform` that holds a pattern and a transformation function. The match function for the transform pattern just matches the pattern and if it matches and also have a capture it will apply the transformation function to the capture.

We can now rewrite our `booleanPattern = "true" + "false"` to a pattern that capture the true/false and then transform it into a Boolean value with the following pattern `booleanPattern = c("true" + "false") / m -> m == "true"` and reduce the `parse` function just to a call to match function and return the capture if there is a match otherwise we return nothing.

PEG DSL grammar for the language up so far:
```julia
booleanPattern = c("true" + "false") / m -> m == "true"
```

### 02.04 - Integers
The next primitive type we will add are 64 bit integers. For that we need to extend our PEG Parser to support character ranges, repeat/optional and sequence patterns. 

Implementing the `CharRange` Pattern is easy. It just hold the min char and the max char. The match function just checks if the text length is still in range of the actual index and then checks if the char at that index is >= min char and <= max char. If so it returns the actual index + 1 otherwise `nothing` as usual.

Implementing the `Repeat` patterns are a bit harder. It holds a count and the pattern that will be checked for the repeats. Counts >= 0 must match the pattern repeatedly at least the count times but can match arbitrary more times the pattern. While counts < 0 will optionally match the pattern up to the negative count. Regex wise is a `count = 0` = `pattern*`, `count > 0` = `pattern^count*pattern*` and `count < 0` = `(pattern?)^count`.

The last bit we need is a `Sequence` pattern that allows us to make a sequential list of patterns that must match one after the other. The `Sequence`pattern hold just that sequential list and test one pattern after the other, only if all match it will return a match. Otherwise `nothing`.

With that 3 additional pattern we can now express integers with or without a leading sign and convert the captured integer string to and `Int64` with some operator overloading like:
`integerPattern = c(("-" + "+") ^ -1 * range('0', '9') ^ 1) / i -> Base.parse(Int64, i)`

The last bit of changes to support also integers in the interpreter is to combine the `booleanPattern` and `integerPattern` with an `OrderedChoice` like `primitivePattern = booleanPattern + integerPattern` and use that now in the `Lair.parse`. We may also need to change the `Lair.print` to handle integer printing.

PEG DSL grammar for the language up so far:
```julia
booleanPattern = c("true" + "false") / m -> m == "true"
integerPattern = c(("-" + "+") ^ -1 * range('0', '9') ^ 1) / i -> Base.parse(Int64, i)
primitivePattern = booleanPattern + integerPattern
```

### 02.05 - Strings
String will be represented with `"` as delimiter and also have the usual escapes sequences like `\"`, `\n` etc. So we use an PEG sequence to match the beginning and ending `"`. But the string content in between can be any char except `"` or `\` or the escape sequences `\n`, `\r`, `\t`, `\\` and `\"` with is the escaped `"` and will not be confused with the string ending.

To do that we extend our PEG parser with an `AnyChar` pattern that will hold the count of the characters to match. If positive we match the exact count of any character otherwise we return `nothing`. If the count is negative we match only there are -count character left.
We also will introduce a `Negate` pattern that holds a pattern and only matches if the pattern doesn't match. It will not consume any input on a match. For convenience we will overload overload the `pattern1 - pattern2` that will be translated to a `Sequence` with a `Negate` with pattern2 followed by pattern1.

Also enabled simple capture transferring support in the sequence. Need to improve and generalize that later on.

And of course to support the printing of the strings we extended the `Lair.print` with string support.

PEG DSL grammar for the language up so far:
```julia
booleanPattern = c("true" + "false") / m -> m == "true" 
integerPattern = c(("-" + "+") ^ -1 * range('0', '9') ^ 1) / i -> Base.parse(Int64, i) 
stringEscapePattern = "\\\"" + "\\\\" + "\\n" + "\\r" + "\\t" 
stringPattern = "\"" * c((stringEscapePattern + (1 - ("\"" + "\\"))) ^ 0) * "\"" 
primitivePattern = booleanPattern + integerPattern + stringPattern
```

## 03 - Generic Interpreter
So far we have only handled self evaluating primitive types which let us ignore many things needed for a useful interpreter like evaluation and application rules, environments, type system(s) and their handling, tail call optimization, continuations etc. So lets start to first implement the machinery needed to make a modular type directed interpreter that is easy to extend/modify with new evaluation and application rules for our types. When that's in place let us introduce new stuff like environments, symbols, arrays, structures, functions, conditionals etc. piece by piece

### 03.01 - Type Directed Interpreter
Let us focus on the types first because in principle each type has an data representation (intern/extern), an evaluation rule and possible an application rule in case it's a applicable type like a function, an object, a pattern etc. When that's in place we will convert all stuff we have so far to the new structure and more stuff later on in a more generic and consistent way.

We will start with the simplest type system that only have isolated types which means that there is no relationship of any kind in between types. And the types are only defined by a name for now represented by a identifier symbol. If your implementation language don't have symbols just use strings.

Now we tag each value with the appropriate type and because we only deal with native types that are tagged by Julia itself we can just map the native type to our own type identifier for now. For that we create a global dictionary `nativeTypes` that map the native type to our type identifiers and provide a `typeOf` function that returns the type identifier for a given expression. Besides our primitive types we have so far we will also map the native function type to the `PrimitiveFunction`.

Most languages are not designed to be extensible with new semantic (or syntactic) forms within the language itself. That means a user of the language is at the merci of the language designer that they implement the right features needed for their problems. But if it isn't supported then the user can in most instances only use a language that have the feature and glue that parts together or hack together an approximated abstraction that in most cases isn't as integrated as the native types. 

Fortunately for us it's pretty easy to design an interpreter with that kind of extensibility. Instead of just implement the hole logic into the eval/apply function directly we introduce an indirection that look up what evaluation and application rules should be used for the expression. That way we can easily add new types with new evaluation or application rules and also expose that functionality to the user so they can build their own types with it's own evaluation and applications rules that behave like native types.

To-do that we introduce an global `evaluators` and `applicators` dictionary that map a the type identifier to a an evaluation or application function and the generic `Lair.eval` and `Lair.apply` just look like something the following:
```julia
function eval(expr, env)
    apply(evaluators[typeOf(expr)], expr, env)
end

function apply(applicator, args, env)
    if typeOf(applicator) == :PrimitiveFunction
        applicator(args, env)
    else
        apply(applicators[typeOf(applicator)], append!([applicator], args), env)
    end
end
```
Basically `Lair.eval` will just look up the evaluation rule and apply it. `Lair.apply` will lookup the application rule and apply it recursively again for non `PrimitiveFunction`s. But when we hit a `PrimitiveFunction` (native function), we stop the the recursive loop and just apply it. The REPL just pass `nothing` for now for the environment parameter `env` in the `Lair.eval` call.

Now what's left is to migrate the primitive self evaluation types to the new logic. So that `typeOf` returns the type identifier for them and we only add evaluators for them in the form like `(exp, env) -> exp`.

We also generalize the `Lair.print` function in the same way that it will now get the type identifier of the expression and look it up in the `serializer` dictionary and use the returned function to convert that expression to a string representation and print it. If no serializer is found just print an error message that the serializer is missing for the type.

### 03.02 - PEG Parser Dynamic Grammar Support
In the previous step we made the interpreter more flexible when it comes to adding types and their evaluation and application rules in isolation/runtime so the user may add their own types that are integrated like the native types. But without also allowing syntactic abstraction for the new types they may never be as integrated as native types. In general it's much harder to make extensible syntax because the syntax rules may interact much easier in unforeseen ways than semantic extensions. To ease that problem we need a syntax that is as regular as possible when it comes to adding new rules to it.

The most regular syntax that fit that bill that i am aware of are the postfix and prefix notation. But postfix have the problem that it can't represent variable arguments function well so we go for a lisp like prefix notation for the application forms in the style of `(operator operant1 ... operantN)`. Where each operator is a applicate able type that takes 0 - N operant's that are separated by whitespace. That way the forms are all disclosed and the actual operator and operant's may all have their own syntax as long as they don't contain the whitespaces or the  delimiters `(` and `)`.

After revealing some general syntax design decision needed later on we are still faced with the problem who we can allow syntactic extension at runtime. The solution is the same as with the interpreter we introduce an indirection that delays the actual decisions to the runtime. In this case we will add grammar support to the PEG Parser and allow dynamic references to the grammar rules.

The grammar itself is just a dictionary that map grammar rule names to their rules. And have 1 special entry at `1` that will hold the start rule name. We could make a extra `Grammar` pattern but i have decided against it. Because we will just pass the grammar along in each match function and only the new `Reference` pattern that hold a grammar name will lookup the respective grammar rule and apply the match function to it. And if we just use the inbuild dictionary we don't must write functions for adding, deleting and modifying grammar rules. Of course we also need to write a new match function that takes a dictionary that get the start rule with the key `1` and then lookup it up and apply the match function to it. For the names we have chosen to use symbols but if your implementation language don't have them just use strings. But be careful that your possible PEG DSL may then collide with the `Literal` pattern. 

The only thing left for now is to convert the fixed PEG rules so far to the new dynamic grammar logic which is pretty strait forward.

### 03.03 - Arrays & Multiple PEG Captures
So far we only handled the atomic types `Boolean`s, `String`s and `Integer`s that are also captured as singular items and returned directly in the result. Also our `Sequence` match function so far has a hack in it so handle the capture of the String pattern. But for more sophisticated matches that need multiple captures like the `Array` we will introduce that single capture functionality won't be enough.

To support multiple captures the capture pattern
To support multiple captures we will extend each `match` function with a `captureStack` that will hold all captured items so far. Basically all match functions, except those that won't create captures like the `Negate` pattern, just pass the `captureStack` through. The `Capture` match function will the only function that place items onto the capture stack. But we also need to extend the `Capture` pattern with a type to differentiate which what kind of capture we are dealing with. For now we only will have the following capture types:
* `string` just as before it only extract the text string but now places it into the result and also onto the given capture stack.
* `array` will take the hole capture stack and place it as a hole onto the given capture stack given.
To make that work we always need to create a fresh capture stack in the `Capture` match function before that we use for the match call to the capture pattern. That way we don't modify outer capture stacks and can deal with the captures in isolation.
Also the `Tranform` pattern will now pop the last item from the stack, transform it and put it back onto the capture stack.

Then we introduce a helper function `resultCapture` to extract the capture results for the `Sequence` and `Repeat` patterns that may capture multiple values. Also using it on the `Tranform` pattern is convenient but we could do without it. It just takes the captureStack and returns nothing if the capture stack is empty, if the capture stack only contain 1 item use that as capture result. Otherwise just use the hole capture stack as capture result.

The last thing to do is to warp the new stuff into the grammar including white space support. Now we let every thing be an expression and differentiate between atoms (primitive basic types) and collections. So the Grammar structure should look something like that:
```julia
grammar[1] = :Expression
grammar[:Expression] = :WhiteSpace * (:Collection + :Atom) * :WhiteSpace
grammar[:Atom] = :Boolean + :Integer + :String
grammar[:Collection] = :Array

grammar[:WhiteSpace] = (" " + "\t" + "\r" + "\n") ^ 0
```
The array them self use the new array capture mechanism and should look something like that `grammar[:Array] = "[" * ca(p(:Expression) ^ 0) * "]"` and evaluate each of their elements like that `evaluators[:Array] = (array, env) -> map(item -> eval(item, env), array)`. The rest should be self explaining.

### 03.04 - Environment And Symbols
So far our types didn't need an environment to evaluate the values because they are self evaluating or only consists of self evaluating parts in the array case. That will change now with the introduction of symbols. A symbol is just a identifier for a value. The default evaluation of a symbol is that it will lookup the value of the symbol in the environment. The environment itself is just a key value store of symbols to values. With the twist that we can nest environments and their respective scopes that they represent. So if we don't find a key in the actual active environment we look in the surrounding environment for the value. And keep that going until we found the symbol or there are no more surrounding environments in which case we abort with an unbound variable error.

Because we still have not introduced an applicate able form we just add the symbols `a = 1` and `b = 2` for testing the functionality. Also the contents of the while loop in the REPL is now surrounded by a `try/catch` block so that we catch any exception in the interpreter, print it and continue until the user exit it explicitly.

The allowed characters for symbols are any character excluding the delimiters so far and the whitespace. Will later on more and more restricted depending on the actual syntax representation we choose for other forms. And if we ever choose to support also an infix syntax with operators then we need to exclude those or handle them differently.

### 03.04 - Primitive Functions and Special Forms
Now that we have symbols in place it's getting more interesting and we will implement primitive functions and special forms that get us to the functionality of a simple calculator. To do that we implement an applicate form that syntax wise looks like that `(operator operant1 ... operantN)`. The evaluator for it will evaluate the operator position, that can also be nested applicate forms and then apply that form with the arguments. For now they are represented just as immutable tuples which may change later on.
With that in place we extend the environment with the 4 primitive operators `+`, `-`, `*` and `/` that can take an arbitrary number of arguments and evaluate like all primitive functions all their arguments before applying the primitive function. If they get 0 arguments we will return the neutral element for the operations. In the case of `+` and `-` that is `0` and in case of `*` and `/` that is 1. Now we can already calculate stuff and also notice because we use native arrays that are also a matrix representation in Julia we can also make some matrix calculations.
We also introduce our first special form, special in the sense that it will not evaluate all their arguments before applying it. In our case that is the `def` form that takes 2 arguments. A symbol and value that will be placed into the actual environment.
We also introduced 2 helper macros do define primitive and special forms. We did go for macros so that we can generate function code with names like `primitive:<name>` and `special:<name>` that will be used for printing the `PrimitiveFunction` type. Used simple functions before but the printing was then just the anonymous function name like `var#36` which isn't really helpful.

### 03.05 - If Special Form & Comparison Functions
We now introduce the if special form control flow construct and because we are using prefix notation we can minimize the syntactic overhead of the if then else branches compared to infix based languages. All the if forms also return the values from there respective branches. So a simple `if then` construct will look the following way and it will return the new `Nothing` type in case the condition don't meet:
```lisp
(if condition thenBranch)
```  
The `if then else` construct will look the following way:
```lisp
(if condition thenBranch elseBranch)
```
And multiple `if then else if then ... else` construct can easily represented by a sequence of conditions and then branches in that way (the last else branch is then optional and if missing and it branches to it it will return `Nothing`):
```lisp
(if condition1 thenBranch1
    condition2 thenBranch2
    ...
    conditionN thenBranchN
    optionalElseBranch)
```
We also make sure that each evaluated condition evaluate to `true` or `false` an then take the `thenBranch` or `optionalElseBranch` pattern. The if special form construct need at least 2 parameters. 1 Condition and 1 then part and support arbitrary long condition and thenBranch pairs.

To make the if special form more useful we also introduce the following primitive comparison functions:
* `=` -> all given operands are equal
* `<` -> all given operands are less then the operand before it
* `<=` -> all given operands are less or equal then the operand before it
* `>`-> all given operands are greater then the operand before it
* `>=` -> all given operands are greater or equal then the operand before it
Because of the multiple dispatch of Julia they also should work on all data types we have so far.
