module ParserCombinators

# Base combinators


function then(parser1, parser2)
    function (input::String)
        res = parser1(input)

        if isnothing(res)
            nothing
        else
            (parsed1, rest1) = res
            (parsed2, rest2) = parser2(rest1)
            (string(parsed1, parsed2), rest2)
        end
    end
end

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
function char_parser(char::Char)
    function (input::String)
        if input[1] == char
            (char, input[2:end])
        else
            nothing
        end
    end
end

end