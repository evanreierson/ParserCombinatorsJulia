module ParserCombinators

# Types
struct Error
    message::String
end

struct ParseResult
    parsed
    rest::String
end

# Parser
parser(x) =
    function (input::String)
        parser(x, input)
    end
parser(char::Char, input) =
    if input[1] == char
        ParseResult(char, input[2:end])
    else
        Error("expected $char at $input")
    end

# Base
then(p1, p2) =
    function (input::String)
        then(p1, p2, input)
    end
then(p1, p2, input::String) = then(p1(input), p2)
then(p1::ParseResult, p2) = then(p1, p2(p1.rest))
then(p1::ParseResult, p2::ParseResult) = ParseResult(vcat(p1.parsed, p2.parsed), p2.rest)
then(e1::Error, _p2) = e1
then(_p1::ParseResult, e2::Error) = e2


or(p1, p2) =
    function (input::String)
        or(p1, p2, input)
    end
or(p1, p2, input::String) = or(p1(input), p2(input))
or(p1::ParseResult, _p2) = p1
or(_e1::Error, p2::ParseResult) = p2
or(_e1::Error, e2::Error) = e2

map(f, p) =
    function (input::String)
        map(f, p, input)
    end
map(f, p, input) = map(f, p(input))
map(f, p::ParseResult) = ParseResult(f(p.parsed), p.rest)
map(f, e::Error) = e

empty() =
    function (input::String)
        ParseResult([], input)
    end

# Derived
one_of(ps) = foldl(or, ps)

sequence(ps) = foldl(then, ps)

optional(p) = or(p, empty())

many(p) =
    function (input::String)
        many(p, empty()(input), input)
    end
many(p, output::ParseResult, input::String) = many(p, output, p(input))
many(p, output::ParseResult, x::ParseResult) = many(p, then(output, x), p(x.rest))
many(p, output::ParseResult, _x::Error) = output

some(p) = then(p, many(p))


end