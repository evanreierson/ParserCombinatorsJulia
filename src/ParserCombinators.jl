module ParserCombinators
export recognizer, recognizers, then, or, apply, ϵ, oneof, sequence, optional, many, some, keepfirst, keepsecond, keepmiddle, ParseResult, ParseError

"""
    ParseError(message::String)

A struct representing a parsing error with a message.
    
In the future, this could store additional data such as current parser,
position, and remaining input.
"""
struct ParseError
    message::String
end

"""
    ParseResult(parsed, message::String)

A struct representing a successfully parsed result and the remaining input.
"""
struct ParseResult
    parsed
    rest::String
end
Base.:(==)(a::ParseResult, b::ParseResult) = (a.parsed == b.parsed) && (a.rest == b.rest)
Base.isequal(a::ParseResult, b::ParseResult) = Base.isequal(a.parsed, b.parsed) && Base.isequal(a.rest, b.rest)
Base.hash(a::ParseResult, h::UInt) = Base.hash((a.parsed, a.rest), h)

"""
    recognize(a)

Create a function that parses a terminal value.

Currently, only char recognizers are supported.

# Examples
```jldoctest
julia> r = recognizer('a')
julia> r("abc")
ParseResult('a', "bc")

julia> r("bcd")
ParseError("expected 'a' at bcd")
```
"""
recognizer(a) =
    function (input::String)
        recognizer(a, input)
    end
recognizer(char::Char, input) =
    if isempty(input)
        ParseError("End of input")
    elseif input[1] == char
        ParseResult(char, input[2:end])
    else
        ParseError("expected $char at $input")
    end

"""
    recognizers(xs)

Create an array of recognizer functions from a list of characters.

# Examples
```jldoctest
julia> rs = recognizers('a':'c')
julia> rs[1]("abc")
ParseResult('a', "bc")

julia> rs[3]("cde")
ParseResult('c', "de")

julia> rs[1]("bcd")
ParseError("expected 'a' at bcd")
```
"""
recognizers(xs) = Base.map(recognizer, xs)


"""
    ϵ()

Create a parser that aways returns the empty string and unchanged input.

# Examples
```jldoctest
julia> e = ϵ()
julia> e("abc")
ParseResult("", "abc")
```
"""
ϵ() =
    function (input::String)
        ParseResult("", input)
    end

"""
    then(p1, p2)

Create a parser that applies two parsers in sequence.

Currently, this parser returns an array, but it may be better to
return a pair, which results in a cons list when `then` is chained.

# Examples
```jldoctest
julia> r1 = recognizer('a')
julia> r2 = recognizer('b')
julia> ab = then(r1, r2)
julia> ab("abc")
ParseResult(['a', 'b'], "c")

julia> ab("acd")
ParseError("expected 'b' at cd")
```
"""
then(p1, p2) =
    function (input::String)
        then(p1, p2, input)
    end
then(p1, p2, input::String) = then(p1(input), p2)
then(p1::ParseResult, p2) = then(p1, p2(p1.rest))
then(p1::ParseResult, p2::ParseResult) = ParseResult(vcat(p1.parsed, p2.parsed), p2.rest)
then(e1::ParseError, _p2) = e1
then(_p1::ParseResult, e2::ParseError) = e2

"""
    or(p1, p2)

Create a parser that returns the result of the first successful parser.

# Examples
```jldoctest
julia> r1 = recognizer('a')
julia> r2 = recognizer('b')
julia> a_or_b = or(r1, r2)
julia> a_or_b("abc")
ParseResult('a', "bc")

julia> a_or_b("bcd")
ParseResult('b', "cd")

julia> a_or_b("cde")
ParseError("expected 'b' at cde")
```
"""
or(p1, p2) =
    function (input::String)
        or(p1, p2, input)
    end
or(p1, p2, input::String) = or(p1(input), p2(input))
or(p1::ParseResult, _p2) = p1
or(_e1::ParseError, p2::ParseResult) = p2
or(_e1::ParseError, e2::ParseError) = e2

"""
    apply(f, p)

Create a parser that applies a function `f` to the result of a parser `p`.

The name `map` was not used to avoid conflicts with `Base.map`.

# Examples
```jldoctest
julia> r = recognizer('a')
julia> a = apply(uppercase, r)
julia> a("abc")
ParseResult('A', "bc")

julia> a("bcd")
ParseError("expected 'a' at bcd")
```
"""
apply(f, p) =
    function (input::String)
        apply(f, p, input)
    end
apply(f, p, input) = apply(f, p(input))
apply(f, p::ParseResult) = ParseResult(f(p.parsed), p.rest)
apply(f, e::ParseError) = e

"""
    many(p)

Create a parser that matches a parser `p` zero or more times.

# Examples
```jldoctest
julia> r = recognizer('a')
julia> m = many(r)
julia> m("aaaabc")
ParseResult(['a', 'a', 'a', 'a'], "bc")

julia> m("bcdef")
ParseResult([], "bcdef")
```
"""
many(p) =
    function (input::String)
        emptylist = apply(_ -> [], ϵ()(input))
        many(p, emptylist, input)
    end
many(p, output::ParseResult, input::String) = many(p, output, p(input))
many(p, output::ParseResult, x::ParseResult) = many(p, then(output, x), p(x.rest))
many(p, output::ParseResult, _x::ParseError) = output

"""
    some(p)

Create a parser that matches a parser `p` one or more times.

# Examples
```jldoctest
julia> r = recognizer('a')
julia> s = some(r)
julia> s("aaaabc")
ParseResult(['a', 'a', 'a', 'a'], "bc")

julia> s("bcdef")
ParseError("expected 'a' at bcdef")
```
"""
some(p) = then(p, many(p))

"""
    oneof(ps)

Create a parser that returns the result of the first successful match in an array of parsers.

# Examples
```jldoctest
julia> r1 = recognizer('a')
julia> r2 = recognizer('b')
julia> r3 = recognizer('c')
julia> o = oneof([r1, r2, r3])
julia> o("abc")
ParseResult('a', "bc")

julia> o("cde")
ParseResult('c', "de")

julia> o("def")
ParseError("expected 'c' at def")
```
"""
oneof(ps) = foldl(or, ps)

"""
    sequence(ps)

Create a parser that matches a list of parsers in order.

# Examples
```jldoctest
julia> r1 = recognizer('a')
julia> r2 = recognizer('b')
julia> r3 = recognizer('c')
julia> s = sequence([r1, r2, r3])
julia> s("abcde")
ParseResult(['a', 'b', 'c'], "de")

julia> s("bcdef")
ParseError("expected 'a' at bcdef")
```
"""
sequence(ps) = foldl(then, ps)

"""
    optional(p)

Create a parser that matches a parser `p` zero or one times.

# Examples
```jldoctest
julia> r = recognizer('a')
julia> o = optional(r)
julia> o("abc")
ParseResult('a', "bc")

julia> o("bcd")
ParseResult("", "bcd")
```
"""
optional(p) = or(p, ϵ())

"""
    keepfirst(p1, p2)

Create a parser that matches two parsers in sequence and discards the result of the second parser.

# Examples
```jldoctest
julia> r1 = recognizer('a')
julia> r2 = recognizer('b')
julia> kf = keepfirst(r1, r2)
julia> kf("abc")
ParseResult('a', "c")

julia> kf("bcd")
ParseError("expected 'a' at bcd")
```
"""
keepfirst(p1, p2) = apply(p -> p[1], then(p1, p2))

"""
    keepsecond(p1, p2)

Create a parser that matches two parsers in sequence and discards the result of the first parser.

# Examples
```jldoctest
julia> r1 = recognizer('a')
julia> r2 = recognizer('b')
julia> ks = keepsecond(r1, r2)
julia> ks("abc")
ParseResult('b', "c")

julia> ks("bcd")
ParseError("expected 'a' at bcd")
```
"""
keepsecond(p1, p2) = apply(p -> p[2], then(p1, p2))


"""
    keepmiddle(p1, p2)

Create a parser that matches three parsers in sequence and discards the results of the first and third parsers.

# Examples
```jldoctest
julia> r1 = recognizer('a')
julia> r2 = recognizer('b')
julia> r3 = recognizer('c')
julia> km = keepmiddle(r1, r2, r3)
julia> km("abcd")
ParseResult('b', "c")

julia> km("bcde")
ParseError("expected 'a' at bcd")
```
"""
keepmiddle(p1, p2, p3) = keepfirst(keepsecond(p1, p2), p3)

end
