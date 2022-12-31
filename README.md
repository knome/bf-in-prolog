
An implementation of the [turing complete esoteric language "bf"](https://en.wikipedia.org/wiki/Brainfuck) in prolog.

# Running The Program

To run the program, you will need a prolog interpreter.

Using the swi-prolog interpreter, you can run the program by running `swipl -s bf.prolog -g go -g halt`

See their documenation at https://www.swi-prolog.org/pldoc/man?section=runoptions

If you accidentally open the interactive interpreter, use either `halt.` or `Ctrl-d` to exit it.

# How it works

Prolog itself operates via ["unification"](https://en.wikipedia.org/wiki/Unification_\(computer_science\)).

It is turing complete, data is immutable, and complex logic can be written using a recursive style.

Programming in Prolog is somewhat similar to programming in languages such as haskell, or performing C++ template metaprogramming.

As it was originally created to perform complex queries across a database of rules and facts, it may also be thought of as operating akin to a perl-style regex, trying paths, backtracking and trying alternate paths.

There is a [`cut`](https://www.swi-prolog.org/pldoc/man?predicate=!/0) command similar to PCRE's [`(*PRUNE)`](https://www.rexegg.com/backtracking-control-verbs.html#prune) verb.

However, our `bf` implementation does not use `cut`, sticking purely to recursion and using prolog's backtracking only for pattern matching over datastructures. I mention it only to illustrate the similarities.

Prolog generally operates over lists, which our `bf` implementation often uses as tuples to bind together various related fields of data.

These tuple-based data structures and functions are documented in the code.

Many functions I considered "obvious" are not documented. If you have questions, feel free to contact me or open an issue.

# Known inefficiencies

We scan forward at each `[` when the data pointer has a 0-value to find the next bit of code to interpret (after the matching `]`), whereas we could have done more work up front and precompiled the jump targets.
