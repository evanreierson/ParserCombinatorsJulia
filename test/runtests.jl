using ParserCombinators
using Test

@testset "Parse nested Vector with various data types" begin
    input = "[234, 453.34, 'hello', [ [ 1, 2 ], 5.0 , 6 ], 'world' ]"
    expected = [234, 453.34, "hello", [[1, 2], 5.0, 6], "world"]


    digit_parsers = Base.map(ParserCombinators.char_parser, '0':'9')
    digit = ParserCombinators.one_of(digit_parsers)

    numbers = ParserCombinators.some(digit)

    int = ParserCombinators.map(p -> parse(Int64, p), numbers)

    dot = ParserCombinators.char_parser('.')
    # exception on int :thinking:
    float = ParserCombinators.map(p -> parse(Float64, p), ParserCombinators.then(ParserCombinators.then(numbers, dot), numbers))

    number = ParserCombinators.or(float, int)



end


@testset "Parse to struct" begin
    input = "(1 2) (30 40) (500 600)"

    struct Point
        x::Int
        y::Int
    end

    expected = [Point(1, 2), Point(30, 40), Point(x=500, y=600)]

end