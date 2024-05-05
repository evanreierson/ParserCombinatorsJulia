module ParserCombinators

struct Error
    message::String
end

struct ParseResult
    parsed
    rest::String
end

# make input an iterable with an end type to dispatch on?

function parser(x)
    function (input::String)
        parser(x, input)
    end
end

parser(char::Char, input) =
    if input[1] == char
        ParseResult(char, rest)
    else
        Error("expected $char at $input")
    end


function then(p1, p2)
    function (input::String)
        then(p1, p2, input)
    end
end
then(p1, p2, input::String) = then(p1(input), p2)
then(p1::ParseResult, p2) = then(p1, p2(p1.rest))
then(e1::Error, _p2) = e1
then(p1::ParseResult, p2::ParseResult) = ParseResult(string(p1.parsed, p2.parsed), p2.rest)
then(_p1::ParseResult, e2::Error) = e2

#function then(parser1, parser2)
#    function (input::String)
#        res = parser1(input)
#
#        if isnothing(res)
#            nothing
#        else
#            (parsed1, rest1) = res
#
#            res2 = parser2(rest1)
#            if isnothing(res2)
#                nothing
#            else
#                (parsed2, rest2) = res2
#                (string(parsed1, parsed2), rest2)
#            end
#        end
#    end
#end

function or(parser1, parser2)
    function (input::String)
        res = parser1(input)

        if isnothing(res)
            parser2(input)
        else
            (parsed1, rest1) = res
            (parsed1, rest1)
        end
    end
end

function drop_first(parser1, parser2)
    function (input::String)
        res = parser1(input)

        if isnothing(res)
            nothing
        else
            (_parsed1, rest1) = res
            parser2(rest1)
        end
    end
end

function map(func, parser)
    function (input::String)
        res = parser(input)

        if isnothing(res)
            nothing
        else
            (parsed1, rest1) = res
            (func(parsed1), rest1)
        end
    end
end


# Derived combinators
function one_of(parsers)
    foldl(or, parsers)
end

function sequence(parsers)
    foldl(then, parsers)
end

function many(parser)

    function many_rec(parser, input, output)
        res = parser(input)

        if isnothing(res)
            (output, input)
        else
            (parsed, rest) = res
            many_rec(parser, rest, string(output, parsed))
        end
    end

    function (input::String)
        many_rec(parser, input, "")
    end
end

function some(parser)
    then(parser, many(parser))
end


# Parsers
#function char_parser(char::Char)
#    function (input::String)
#        if input[1] == char
#            (char, input[2:end])
#        else
#            nothing
#        end
#    end
#end

function char_range_parsers(a, b)
    Base.map(ParserCombinators.char_parser, a:b)
end

end