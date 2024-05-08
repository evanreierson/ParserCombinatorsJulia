module ParserCombinators
export recognizer, recognizers, then, or, apply, ϵ, oneof, sequence, optional, many, some, ParseResult, ParseError

# Result types
struct ParseError
    message::String
end

struct ParseResult
    parsed
    rest::String
end
Base.:(==)(a::ParseResult, b::ParseResult) = (a.parsed == b.parsed) && (a.rest == b.rest)
Base.isequal(a::ParseResult, b::ParseResult) = Base.isequal(a.parsed, b.parsed) && Base.isequal(a.rest, b.rest)
Base.hash(a::ParseResult, h::UInt) = Base.hash((a.parsed, a.rest), h)

# Terminal recognizers 
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

recognizers(xs) = Base.map(recognizer, xs)



# Base combinators
then(p1, p2) =
    function (input::String)
        then(p1, p2, input)
    end
then(p1, p2, input::String) = then(p1(input), p2)
then(p1::ParseResult, p2) = then(p1, p2(p1.rest))
then(p1::ParseResult, p2::ParseResult) = ParseResult(vcat(p1.parsed, p2.parsed), p2.rest)
then(e1::ParseError, _p2) = e1
then(_p1::ParseResult, e2::ParseError) = e2


or(p1, p2) =
    function (input::String)
        or(p1, p2, input)
    end
or(p1, p2, input::String) = or(p1(input), p2(input))
or(p1::ParseResult, _p2) = p1
or(_e1::ParseError, p2::ParseResult) = p2
or(_e1::ParseError, e2::ParseError) = e2

apply(f, p) =
    function (input::String)
        apply(f, p, input)
    end
apply(f, p, input) = apply(f, p(input))
apply(f, p::ParseResult) = ParseResult(f(p.parsed), p.rest)
apply(f, e::ParseError) = e

ϵ() =
    function (input::String)
        ParseResult([], input)
    end

# Derived combinators
oneof(ps) = foldl(or, ps)

sequence(ps) = foldl(then, ps)

optional(p) = or(p, ϵ())

many(p) =
    function (input::String)
        many(p, ϵ()(input), input)
    end
many(p, output::ParseResult, input::String) = many(p, output, p(input))
many(p, output::ParseResult, x::ParseResult) = many(p, then(output, x), p(x.rest))
many(p, output::ParseResult, _x::ParseError) = output

some(p) = then(p, many(p))

end