{Parser} = require '../../../lib/parsers/bibtex/parser'
ast = require '.../../../lib/parsers/bibtex/ast'
jasmine = require 'jasmine'

describe 'Parser', ->
  beforeEach ->
    @parser = new Parser()

    # some helpers
    @.tokens = (tokens) ->
      @parser.tokens = tokens
      @parser.currentToken = 0
      @parser.tokensLen = tokens.length
      @parser.markLocations = []

    @.singleToken = (token) ->
      @tokens [token]

    @.noTokens = ->
      @tokens []

  describe 'value', ->
    it 'should transform an IDENTIFIER token into a LiteralNode', ->
      @singleToken ['IDENTIFIER', 'id', {}]
      node = @parser.value()
      expect(node.value).toBe 'id'

    it 'should transform a NUMBER token into a NumberNode', ->
      @singleToken ['NUMBER', '12345', {}]
      node = @parser.value()
      expect(node.value).toBe '12345'

    it 'should transform a VALUE token into a QuotedLiteralNode', ->
      @singleToken ['VALUE', 'value', {}]
      node = @parser.value()
      expect(node.value).toBe 'value'

    it 'should transform a QUOTED_STRING token into a QuotedLiteralNode', ->
      @singleToken ['QUOTED_STRING', 'value', {}]
      node = @parser.value()
      expect(node.value).toBe 'value'

    it 'should throw an exception on an unexpected token', ->
      @singleToken ['EOF', 'EOF', {}]
      expect(@parser.value.bind(@parser)).toThrowError(
        SyntaxError, /\bunexpected eof\b/
      )

    it 'should throw an exception when no tokens available', ->
      @noTokens()
      expect(@parser.value.bind(@parser)).toThrowError(
        SyntaxError, /\bunexpected eof\b/
      )

  describe 'concatenatedValue', ->
    it 'should transform concatenated tokens into a ConcatenationNode', ->
      @tokens [
        ['IDENTIFIER', 'id', {}],
        ['#', '#', {}],
        ['IDENTIFIER', 'id2', {}]
      ]
      node = @parser.concatenatedValue()
      expect(node.lhs?.value).toBe 'id'
      expect(node.rhs?.value).toBe 'id2'

    it 'should support two concatenations in a row', ->
      @tokens [
        ['IDENTIFIER', 'id', {}],
        ['#', '#', {}],
        ['IDENTIFIER', 'id2', {}],
        ['#', '#', {}],
        ['IDENTIFIER', 'id3', {}]
      ]
      node = @parser.concatenatedValue()
      expect(node.lhs?.value).toBe 'id'
      expect(node.rhs?.lhs?.value).toBe 'id2'
      expect(node.rhs?.rhs?.value).toBe 'id3'

    it 'should support multiple concatenations', ->
      @tokens [
        ['IDENTIFIER', 'id', {}],
        ['#', '#', {}],
        ['IDENTIFIER', 'id2', {}],
        ['#', '#', {}],
        ['IDENTIFIER', 'id3', {}],
        ['#', '#', {}],
        ['IDENTIFIER', 'id4', {}],
        ['#', '#', {}],
        ['IDENTIFIER', 'id5', {}],
        ['#', '#', {}],
        ['IDENTIFIER', 'id6', {}],
        ['#', '#', {}],
        ['IDENTIFIER', 'id7', {}]
      ]
      node = @parser.concatenatedValue()
      expect(node.lhs?.value).toBe 'id'
      expect(node.rhs?.lhs?.value).toBe 'id2'
      expect(node.rhs?.rhs?.rhs?.rhs?.rhs?.rhs?.value).toBe 'id7'

    it 'should return false if first token is not a value', ->
      @tokens [
        ['EOF', 'EOF', {}],
        ['#', '#', {}],
        ['IDENTIFIER', 'id2', {}]
      ]
      expect(@parser.concatenatedValue()).toBe false

    it 'should return false if second token is not a hash', ->
      @tokens [
        ['IDENTIFIER', 'id', {}],
        ['EOF', 'EOF', {}],
        ['IDENTIFIER', 'id2', {}]
      ]
      expect(@parser.concatenatedValue()).toBe false

    it 'should return false if third token is not a value', ->
      @tokens [
        ['IDENTIFIER', 'id', {}],
        ['#', '#', {}],
        ['EOF', 'EOF', {}]
      ]
      expect(@parser.concatenatedValue()).toBe false

    it 'should only support concatenations up to the last valid one', ->
      @tokens [
        ['IDENTIFIER', 'id', {}],
        ['#', '#', {}],
        ['IDENTIFIER', 'id2', {}],
        ['#', '#', {}],
        ['EOF', 'EOF', {}]
      ]
      node = @parser.concatenatedValue()
      expect(node.lhs?.value).toBe 'id'
      expect(node.rhs?.value).toBe 'id2'

  describe 'fieldValue', ->
    it 'should parse a valid value', ->
      @singleToken ['IDENTIFIER', 'id', {}]
      node = @parser.fieldValue()
      expect(node.value).toBe 'id'

    it 'should parse a concatenated value', ->
      @tokens [
        ['IDENTIFIER', 'id', {}],
        ['#', '#', {}],
        ['IDENTIFIER', 'id2', {}]
      ]
      node = @parser.fieldValue()
      expect(node.lhs?.value).toBe 'id'
      expect(node.rhs?.value).toBe 'id2'

    it 'should throw an exception when trying to parse an invalid token', ->
      @singleToken ['EOF', 'EOF', {}]
      expect(@parser.fieldValue.bind(@parser)).toThrowError SyntaxError

    it 'should throw an exception when no tokens are available', ->
      @noTokens()
      expect(@parser.fieldValue.bind(@parser)).toThrowError SyntaxError

  describe 'keyValues', ->
    it 'should parse a key-value pair', ->
      @tokens [
        ['KEY', 'key', {}],
        ['VALUE', 'value', {}]
      ]
      node = @parser.keyValues()[0]
      expect(node.key).toBe 'key'
      expect(node.value.value).toBe 'value'

    it 'should parse multiple key-value pairs', ->
      @tokens [
        ['KEY', 'key1', {}],
        ['VALUE', 'value', {}],
        ['KEY', 'key2', {}],
        ['VALUE', 'value', {}],
        ['KEY', 'key3', {}],
        ['VALUE', 'value', {}]
      ]
      nodes = @parser.keyValues()
      expect(nodes[0].key).toBe 'key1'
      expect(nodes[1].key).toBe 'key2'
      expect(nodes[2].key).toBe 'key3'

    it 'should stop parsing when a key-value pair doesnt start with a key', ->
      @tokens [
        ['KEY', 'key', {}],
        ['VALUE', 'value', {}],
        ['EOF', 'EOF', {}]
      ]
      nodes = @parser.keyValues()
      expect(nodes[0].key).toBe 'key'
      expect(nodes.length).toBe 1

    it 'should not parse a key-value pair where value isnt a value', ->
      @tokens [
        ['KEY', 'key', {}],
        ['EOF', 'EOF', {}]
      ]
      expect(@parser.keyValues.bind(@parser)).toThrowError SyntaxError

    it 'should throw a syntax error if any key-value pair is invalid', ->
      @tokens [
        ['KEY', 'key1', {}],
        ['VALUE', 'value', {}],
        ['KEY', 'key2', {}],
        ['VALUE', 'value', {}],
        ['KEY', 'key3', {}],
        ['EOF', 'EOF', {}]
      ]
      expect(@parser.keyValues.bind(@parser)).toThrowError SyntaxError

    it 'should return an empty list if first token is invalid', ->
      @singleToken ['EOF', 'EOF', {}]
      expect(@parser.keyValues()).toEqual []

    it 'should return an empty list if no more tokens available', ->
      @noTokens()
      expect(@parser.keyValues()).toEqual []

  describe 'stringValue', ->
    it 'should parse a VALUE', ->
      @singleToken ['VALUE', 'value', {}]
      node = @parser.stringValue()
      expect(node.value).toBe 'value'

    it 'should parse a QUOTED_STRING', ->
      @singleToken ['QUOTED_STRING', 'value', {}]
      node = @parser.stringValue()
      expect(node.value).toBe 'value'

    it 'should not parse a non-VALUE and non-QUOTED_STRING token', ->
      @singleToken ['EOF', 'EOF', {}]
      expect(@parser.stringValue.bind(@parser)).toThrowError SyntaxError

    it 'should throw an exception if no more tokens are available', ->
      @noTokens()
      expect(@parser.stringValue.bind(@parser)).toThrowError SyntaxError

  describe 'entryKey', ->
    it 'should parse an entry key', ->
      @singleToken ['IDENTIFIER', 'id', {}]
      node = @parser.entryKey()
      expect(node.value).toBe 'id'

    it 'should not parse an invalid entry type', ->
      @singleToken ['EOF', 'EOF', {}]
      expect(@parser.entryKey.bind(@parser)).toThrowError SyntaxError

    it 'should throw an exception if no more tokens available', ->
      @noTokens()
      expect(@parser.entryKey.bind(@parser)).toThrowError SyntaxError

  describe 'entry', ->
    it 'should parse a valid entry', ->
      @tokens [
        ['ENTRY_TYPE', 'book', {}],
        ['IDENTIFIER', 'id', {}],
        ['KEY', 'title', {}],
        ['VALUE', '1984', {}],
        ['ENTRY_END', '}', {}]
      ]

      node = @parser.entry()
      expect(node.entryType).toBe 'book'
      expect(node.key.value).toBe 'id'
      expect(node.fields[0].key).toBe 'title'
      expect(node.fields[0].value.value).toBe '1984'

    it 'should parse an entry without any key-value pairs', ->
      @tokens [
        ['ENTRY_TYPE', 'book', {}],
        ['IDENTIFIER', 'id', {}],
        ['ENTRY_END', '}', {}]
      ]

      node = @parser.entry()
      expect(node.entryType).toBe 'book'
      expect(node.key.value).toBe 'id'

    it 'should throw an exception if entryType is missing', ->
      @tokens [
        ['IDENTIFIER', 'id', {}],
        ['KEY', 'title', {}],
        ['VALUE', '1984', {}],
        ['ENTRY_END', '}', {}]
      ]
      expect(@parser.entry.bind(@parser)).toThrowError SyntaxError

    it 'should throw an exception if entryType is invalid', ->
      @tokens [
        ['EOF', 'EOF', {}]
        ['IDENTIFIER', 'id', {}],
        ['KEY', 'title', {}],
        ['VALUE', '1984', {}],
        ['ENTRY_END', '}', {}]
      ]
      expect(@parser.entry.bind(@parser)).toThrowError SyntaxError

    it 'should throw an exception if entryKey is missing', ->
      @tokens [
        ['ENTRY_TYPE', 'book', {}],
        ['KEY', 'title', {}],
        ['VALUE', '1984', {}],
        ['ENTRY_END', '}', {}]
      ]
      expect(@parser.entry.bind(@parser)).toThrowError SyntaxError

    it 'should throw an exception if entryKey is invalid', ->
      @tokens [
        ['ENTRY_TYPE', 'book', {}],
        ['EOF', 'EOF', {}],
        ['KEY', 'title', {}],
        ['VALUE', '1984', {}],
        ['ENTRY_END', '}', {}]
      ]
      expect(@parser.entry.bind(@parser)).toThrowError SyntaxError

    it 'should throw an exception if ENTRY_END is missing', ->
      @tokens [
        ['ENTRY_TYPE', 'book', {}],
        ['IDENTIFIER', 'id', {}],
        ['KEY', 'title', {}],
        ['VALUE', '1984', {}]
      ]
      expect(@parser.entry.bind(@parser)).toThrowError SyntaxError

    it 'should throw an exception if ENTRY_END is invalid', ->
      @tokens [
        ['ENTRY_TYPE', 'book', {}],
        ['IDENTIFIER', 'id', {}],
        ['KEY', 'title', {}],
        ['VALUE', '1984', {}],
        ['EOF', 'EOF', {}]
      ]
      expect(@parser.entry.bind(@parser)).toThrowError SyntaxError

    it 'should throw an exception if key is invalid', ->
      @tokens [
        ['ENTRY_TYPE', 'book', {}]
        ['IDENTIFIER', 'id', {}],
        ['EOF', 'EOF', {}],
        ['VALUE', '1984', {}],
        ['ENTRY_END', '}', {}]
      ]
      expect(@parser.entry.bind(@parser)).toThrowError SyntaxError

    it 'should throw an exception if value is invalid', ->
      @tokens [
        ['ENTRY_TYPE', 'book', {}]
        ['IDENTIFIER', 'id', {}],
        ['KEY', 'title', {}],
        ['EOF', 'EOF', {}],
        ['ENTRY_END', '}', {}]
      ]
      expect(@parser.entry.bind(@parser)).toThrowError SyntaxError

    it 'should throw an exception if no more tokens are available', ->
      @noTokens()
      expect(@parser.entry.bind(@parser)).toThrowError SyntaxError

  describe 'string', ->
    it 'should parse a valid string entry', ->
      @tokens [
        ['KEY', 'cup', {}],
        ['VALUE', 'Cambridge University Press', {}],
        ['ENTRY_END', '}', {}]
      ]
      node = @parser.string()
      expect(node.key).toBe 'cup'
      expect(node.value.value).toBe 'Cambridge University Press'

    it 'should throw an exception if key is missing', ->
      @tokens [
        ['VALUE', 'Cambridge University Press', {}],
        ['ENTRY_END', '}', {}]
      ]
      expect(@parser.string.bind(@parser)).toThrowError SyntaxError

    it 'should throw an exception if key is invalid', ->
      @tokens [
        ['EOF', 'EOF', {}],
        ['VALUE', 'Cambridge University Press', {}],
        ['ENTRY_END', '}', {}]
      ]
      expect(@parser.string.bind(@parser)).toThrowError SyntaxError

    it 'should throw an exception if value is missing', ->
      @tokens [
        ['KEY', 'cup', {}],
        ['ENTRY_END', '}', {}]
      ]
      expect(@parser.string.bind(@parser)).toThrowError SyntaxError

    it 'should throw an exception if value is invalid', ->
      @tokens [
        ['KEY', 'cup', {}],
        ['EOF', 'EOF', {}],
        ['ENTRY_END', '}', {}]
      ]
      expect(@parser.string.bind(@parser)).toThrowError SyntaxError

    it 'should throw an exception if ENTRY_END is missing', ->
      @tokens [
        ['KEY', 'cup', {}],
        ['VALUE', 'Cambridge University Press', {}],
      ]
      expect(@parser.string.bind(@parser)).toThrowError SyntaxError

    it 'should throw an exception if ENTRY_END is invalid', ->
      @tokens [
        ['KEY', 'cup', {}],
        ['VALUE', 'Cambridge University Press', {}],
        ['EOF', 'EOF', {}]
      ]
      expect(@parser.string.bind(@parser)).toThrowError SyntaxError

    it 'should throw an exception if no more tokens are available', ->
      @noTokens()
      expect(@parser.string.bind(@parser)).toThrowError SyntaxError

  describe 'preamble', ->
    it 'should parse a valid preamble', ->
      @tokens [
        ['VALUE', '\\newcommand{\\nop}[1]{}', {}],
        ['ENTRY_END', '}', {}]
      ]
      node = @parser.preamble()
      expect(node.contents.value).toBe '\\newcommand{\\nop}[1]{}'

    it 'should parse a preamble without a value', ->
      @singleToken ['ENTRY_END', '}', {}]
      node = @parser.preamble()

    it 'should throw an exception if value is invalid', ->
      @tokens [
        ['EOF', 'EOF', {}],
        ['ENTRY_END', '}', {}]
      ]
      expect(@parser.preamble.bind(@parser)).toThrowError SyntaxError

    it 'should throw an exception if ENTRY_END is missing', ->
      @singleToken ['VALUE', '\\newcommand{\\nop}[1]{}', {}]
      expect(@parser.preamble.bind(@parser)).toThrowError SyntaxError

    it 'should throw an exception if ENTRY_END is invalid', ->
      @tokens [
        ['VALUE', '\\newcommand{\\nop}[1]{}', {}],
        ['EOF', 'EOF', {}]
      ]
      expect(@parser.preamble.bind(@parser)).toThrowError SyntaxError

  describe 'parse', ->
    beforeEach ->
      class DummyLexer
        tokenize: (s) ->
          @tokens

      @lexer = new DummyLexer()
      @parser = new Parser()

      # some helpers
      @.tokens = (tokens) ->
        @lexer.tokens = tokens

      @.singleToken = (token) ->
        @tokens [token]

      @.noTokens = ->
        @tokens []

    it 'should parse a preamble', ->
      @tokens [
        ['PREAMBLE', '@preamble', {}],
        ['VALUE', '\\newcommand{\\nop}[1]{}', {}],
        ['ENTRY_END', '}', {}],
        ['EOF', 'EOF', {}]
      ]
      result = @parser.parse('', @lexer)
      expect(result.getPreamble()).toBe '\\newcommand{\\nop}[1]{}'

    it 'should parse a string', ->
      @tokens [
        ['STRING', '@string', {}],
        ['KEY', 'cup', {}],
        ['VALUE', 'Cambridge University Press', {}],
        ['ENTRY_END', '}', {}],
        ['EOF', 'EOF', {}]
      ]
      result = @parser.parse('', @lexer)
      expect(result.getMacro('cup')).toBe 'Cambridge University Press'

    it 'should parse a simple entry', ->
      @tokens [
        ['ENTRY_START', '@', {}],
        ['ENTRY_TYPE', 'book', {}],
        ['IDENTIFIER', 'id', {}],
        ['ENTRY_END', '}', {}],
        ['EOF', 'EOF', {}]
      ]
      result = @parser.parse('', @lexer)
      expect(result.getEntry('id').entryType).toBe 'book'

    it 'should parse an entry with fields', ->
      @tokens [
        ['ENTRY_START', '@', {}],
        ['ENTRY_TYPE', 'book', {}],
        ['IDENTIFIER', 'id', {}],
        ['KEY', 'title', {}],
        ['VALUE', '1984', {}],
        ['ENTRY_END', '}', {}],
        ['EOF', 'EOF', {}]
      ]
      result = @parser.parse('', @lexer)
      expect(result.getEntry('id').getAttribute('title')).toBe '1984'

    it 'should parse an entry with a name', ->
      @tokens [
        ['ENTRY_START', '@', {}],
        ['ENTRY_TYPE', 'book', {}],
        ['IDENTIFIER', 'id', {}],
        ['KEY', 'author', {}],
        ['VALUE', 'Simon Coddlington', {}],
        ['ENTRY_END', '}', {}],
        ['EOF', 'EOF', {}]
      ]
      result = @parser.parse('', @lexer)
      expect(result.getEntry('id').getAttribute('author')).toEqual \
        'Coddlington, Simon'

    it 'should parse an entry with a name field with multiple entries', ->
      @tokens [
        ['ENTRY_START', '@', {}],
        ['ENTRY_TYPE', 'book', {}],
        ['IDENTIFIER', 'id', {}],
        ['KEY', 'author', {}],
        ['VALUE', 'Simon Coddlington and Warren Harding', {}],
        ['ENTRY_END', '}', {}],
        ['EOF', 'EOF', {}]
      ]
      result = @parser.parse('', @lexer)
      expect(result.getEntry('id').getAttribute('author')).toEqual \
        'Coddlington, Simon and Harding, Warren'

    it 'should parse an entry with a field value set to a macro', ->
      @tokens [
        ['ENTRY_START', '@', {}],
        ['ENTRY_TYPE', 'book', {}],
        ['IDENTIFIER', 'id', {}],
        ['KEY', 'month', {}],
        ['IDENTIFIER', 'jan', {}],
        ['ENTRY_END', '}', {}],
        ['EOF', 'EOF', {}]
      ]
      result = @parser.parse('', @lexer)
      expect(result.getEntry('id').getAttribute('month')).toEqual 'January'

    it 'should parse an entry with a field set to an undefined macro', ->
      @tokens [
        ['ENTRY_START', '@', {}],
        ['ENTRY_TYPE', 'book', {}],
        ['IDENTIFIER', 'id', {}],
        ['KEY', 'month', {}],
        ['IDENTIFIER', 'Not_A_Macro', {}],
        ['ENTRY_END', '}', {}],
        ['EOF', 'EOF', {}]
      ]
      result = @parser.parse('', @lexer)
      expect(result.getEntry('id').getAttribute('month')).toEqual 'Not_A_Macro'

    it 'should parse an empty database', ->
      @singleToken ['EOF', 'EOF', {}]
      result = @parser.parse('', @lexer)
      expect(result).not.toBeNull

    it 'should throw an error with an unexpected token', ->
      @singleToken ['VALUE', 'value', {}]
      expect(@parser.parse.bind(@parser, '', @lexer)).toThrowError SyntaxError

    it 'should throw an error if no tokens are available', ->
      @noTokens()
      expect(@parser.parse.bind(@parser, '', @lexer)).toThrowError SyntaxError
