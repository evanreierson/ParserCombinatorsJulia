using ParserCombinators
using Test

@testset "recognizers" begin
    @testset "from char" begin
        a = recognizer('a')

        @test a("a") == ParseResult('a', "")
        @test a("abc") == ParseResult('a', "bc")

        @test isa(a(""), ParseError)
        @test isa(a("bcd"), ParseError)
    end

    @testset "from char iterable" begin
        az = recognizers('a':'z')

        @test az[1]("abc") == ParseResult('a', "bc")
        @test az[end]("zbc") == ParseResult('z', "bc")
    end
end

@testset "then combinator" begin
    a = recognizer('a')
    b = recognizer('b')
    ab = then(a, b)

    @test ab("ab") == ParseResult(['a', 'b'], "")
    @test ab("abc") == ParseResult(['a', 'b'], "c")

    @test isa(ab(""), ParseError)
    @test isa(ab("a"), ParseError)
    @test isa(ab("bca"), ParseError)
end

@testset "or combinator" begin
    a = recognizer('a')
    b = recognizer('b')
    aorb = or(a, b)

    @test aorb("abc") == ParseResult('a', "bc")
    @test aorb("bac") == ParseResult('b', "ac")

    @test isa(aorb(""), ParseError)
    @test isa(aorb("cab"), ParseError)
end

@testset "apply combinator" begin
    one = recognizer('1')
    int = apply(p -> parse(Int64, p), one)

    @test int("1ab") == ParseResult(1, "ab")

    @test isa(int(""), ParseError)
    @test isa(int("abc"), ParseError)
end

@testset "ϵ (empty) combinator" begin
    e = ϵ()

    @test e("abc") == ParseResult("", "abc")

    @test e("") == ParseResult("", "")
end

@testset "oneof combinator" begin
    digit = oneof(recognizers('0':'9'))

    @test digit("0abc") == ParseResult('0', "abc")
    @test digit("9abc") == ParseResult('9', "abc")

    @test isa(digit(""), ParseError)
    @test isa(digit("abc"), ParseError)
end

@testset "sequence combinator" begin
    onetwothree = sequence(recognizers('1':'3'))

    @test onetwothree("123abc") == ParseResult(['1', '2', '3'], "abc")

    @test isa(onetwothree(""), ParseError)
    @test isa(onetwothree("abc"), ParseError)
    @test isa(onetwothree("12abc"), ParseError)
end

@testset "optional combinator" begin
    maybe_a = optional(recognizer('a'))

    @test maybe_a("abc") == ParseResult('a', "bc")
    @test maybe_a("bac") == ParseResult("", "bac")
    @test maybe_a("") == ParseResult("", "")
end

@testset "many combinator" begin
    maybe_as = many(recognizer('a'))

    @test maybe_as("bc") == ParseResult([], "bc")
    @test maybe_as("abc") == ParseResult(['a'], "bc")
    @test maybe_as("aaabc") == ParseResult(['a', 'a', 'a'], "bc")
end

@testset "some combinator" begin
    as = some(recognizer('a'))

    @test as("abc") == ParseResult(['a'], "bc")
    @test as("aaabc") == ParseResult(['a', 'a', 'a'], "bc")

    @test isa(as(""), ParseError)
    @test isa(as("bc"), ParseError)
end

@testset "keepfirst combinator" begin
    a = recognizer('a')
    b = recognizer('b')

    a_ = keepfirst(a, b)

    @test a_("abc") == ParseResult('a', "c")

    @test isa(a_(""), ParseError)
    @test isa(a_("bac"), ParseError)
end

@testset "keepsecond combinator" begin
    a = recognizer('a')
    b = recognizer('b')

    _b = keepsecond(a, b)

    @test _b("abc") == ParseResult('b', "c")

    @test isa(_b(""), ParseError)
    @test isa(_b("bac"), ParseError)
end

@testset "keepmiddle combinator" begin
    a = recognizer('a')
    b = recognizer('b')
    c = recognizer('c')

    _b_ = keepmiddle(a, b, c)

    @test _b_("abcd") == ParseResult('b', "d")

    @test isa(_b_(""), ParseError)
    @test isa(_b_("bac"), ParseError)
end

@testset "Parse whitespace-separated list of numbers" begin
    input = """
    2344 23454.34
    45.67  5  3  """

    expected = [2344, 23454.34, 45.67, 5, 3]

    digit = oneof(recognizers('0':'9'))
    digits = some(digit)
    int = apply(p -> parse(Int64, join(p)), digits)
    dot = recognizer('.')
    float = apply(p -> parse(Float64, join(p)), sequence([digits, dot, digits]))
    number = or(float, int)

    whitespace = optional(some(oneof(recognizers([' ', '\t', '\n']))))

    element = keepmiddle(whitespace, number, whitespace)

    numberlist = many(element)

    @test numberlist(input) == ParseResult(expected, "")
end

@testset "Parse nested vector" begin
    input = "[[],[[],[[]],[]],[]]"
    expected = [[], [[], [[]], []], []]


    # TODO figure out mutually recursive definitions
    openbracket = recognizer('[')
    closebracket = recognizer(']')
    unitlist = then(openbracket, closebracket)
    comma = recognizer(',')

    listitem = keepmiddle(comma, or(list, unitlist), comma)
    list = (then(openbracket, many(listitem)), closebracket)

    list(input)
end


@testset "Parse to struct" begin
    struct Point
        x::Int
        y::Int
    end

    input = "(1 2) (30 40) (500 600)"
    expected = [Point(1, 2), Point(30, 40), Point(500, 600)]

    openparen = recognizer('(')
    closeparen = recognizer(')')
    space = recognizer(' ')

    digit = oneof(recognizers('0':'9'))
    digits = some(digit)
    int = apply(p -> parse(Int64, join(p)), digits)

    pair = sequence([openparen, int, space, int, closeparen, optional(space)])
    point = apply(p -> Point(p[2], p[4]), pair)

    pointlist = some(point)


    @test pointlist(input) == ParseResult(expected, "")

    @test isa(pointlist("(4, hello)"), ParseError)
    @test isa(pointlist(""), ParseError)
end