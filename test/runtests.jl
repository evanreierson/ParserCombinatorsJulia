using ParserCombinators
using Test

@testset "then combinator" begin

end


@testset "Parse nested Vector with various data types" begin
    input = "[234, 453.34, 'hello', [ [ 1, 2 ], 5.0 , 6 ], 'world' ]"
    expected = [234, 453.34, "hello", [[1, 2], 5.0, 6], "world"]


    digit = ParserCombinators.one_of(ParserCombinators.char_range_parsers('0', '9'))

    numbers = ParserCombinators.some(digit)

    int = ParserCombinators.map(p -> parse(Int64, p), numbers)

    dot = ParserCombinators.char_parser('.')

    float = ParserCombinators.map(p -> parse(Float64, p), ParserCombinators.then(ParserCombinators.then(numbers, dot), numbers))

    number = ParserCombinators.or(float, int)

    upper = ParserCombinators.one_of(ParserCombinators.char_range_parsers('A', 'Z'))

    lower = ParserCombinators.one_of(ParserCombinators.char_range_parsers('a', 'z'))

    alphanumeric = ParserCombinators.one_of([digit, upper, lower])

    word = ParserCombinators.some(alphanumeric)

end


@testset "Parse to struct" begin
    input = "(1 2) (30 40) (500 600)"

    struct Point
        x::Int
        y::Int
    end

    expected = [Point(1, 2), Point(30, 40), Point(x=500, y=600)]

end