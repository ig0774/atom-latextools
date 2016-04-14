{Lexer} = require '../../../lib/parsers/bibtex/lexer'

describe 'Lexer', ->
  beforeEach ->
    @lexer = new Lexer

  describe 'preambleToken', ->
    it 'should parse the start of an @preamble entry', ->
      @lexer.chunk = '@preamble{'

      expect(@lexer.preambleToken()).toBe 10
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'PREAMBLE'
      expect(@lexer.tokens[0][1]).toBe 'preamble'

    it 'should parse a token regardless of case', ->
      @lexer.chunk = '@PREAMBLE{'
      @lexer.preambleToken()
      expect(@lexer.tokens[0][0]).toBe 'PREAMBLE'

    it 'should parse a token with spaces before the bracket', ->
      @lexer.chunk = '@preamble {'
      expect(@lexer.preambleToken()).toBe 11

    it 'should not parse a token without the @ sign', ->
      @lexer.chunk = 'preamble{'
      expect(@lexer.preambleToken()).toBe 0

    it 'should not parse a token without the bracket', ->
      @lexer.chunk = '@preamble'
      expect(@lexer.preambleToken()).toBe 0

    it 'should not parse text after the bracket', ->
      @lexer.chunk = '@preamble{blah, blah, blah, blah'
      expect(@lexer.preambleToken()).toBe 10

  describe 'stringToken', ->
    it 'should parse the start of a @string entry', ->
      @lexer.chunk = '@string{'

      expect(@lexer.stringToken()).toBe 8
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'STRING'
      expect(@lexer.tokens[0][1]).toBe 'string'

    it 'should parse a token regardless of case', ->
      @lexer.chunk = '@STRING{'
      @lexer.stringToken()
      expect(@lexer.tokens[0][0]).toBe 'STRING'

    it 'should parse a token with spaces before the bracket', ->
      @lexer.chunk = '@string {'
      expect(@lexer.stringToken()).toBe 9

    it 'should not parse a token without the @ sign', ->
      @lexer.chunk = 'string{'
      expect(@lexer.stringToken()).toBe 0

    it 'should not parse a token without a bracket', ->
      @lexer.chunk = '@string'
      expect(@lexer.stringToken()).toBe 0

    it 'should not parse text after the bracket', ->
      @lexer.chunk = '@string{blah, blah, blah, blah'
      expect(@lexer.stringToken()).toBe 8

  describe 'commentToken', ->
    it 'should parse the start of a @comment entry', ->
      @lexer.chunk = '@comment{'

      expect(@lexer.commentToken()).toBe 9

    it 'should parse a token regardless of case', ->
      @lexer.chunk = '@COMMENT{'
      @lexer.commentToken()
      expect(@lexer.commentToken()).toBe 9

    it 'should not parse a token without the @ sign', ->
      @lexer.chunk = 'comment{'
      expect(@lexer.commentToken()).toBe 0

    it 'should parse a token without a bracket', ->
      @lexer.chunk = '@comment'
      expect(@lexer.commentToken()).toBe 0

    it 'should consume the rest of the line', ->
      @lexer.chunk = '@comment{blah, blah, blah, blah'
      expect(@lexer.commentToken()).toBe 31

    it 'should not consume the next line', ->
      @lexer.chunk = '@comment{blah, blah, blah, blah\nblah, blah, blah, blah'
      expect(@lexer.commentToken()).toBe 31

    it 'should consume the rest of the line without a bracket', ->
      @lexer.chunk = '@comment blah, blah, blah, blah'
      expect(@lexer.commentToken()).toBe 31

    it 'should consume the rest of the line without any separator at all', ->
      @lexer.chunk = '@commentblahblahblahblahblah'
      expect(@lexer.commentToken()).toBe 28

  describe 'entryStartToken', ->
    # "entry" here means anything that is not a @preamble, @string, or @comment
    it 'should parse the start of an entry', ->
      @lexer.chunk = '@entry{'

      expect(@lexer.entryStartToken()).toBe 1
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'ENTRY_START'
      expect(@lexer.tokens[0][1]).toBe '@'

    it 'should parse a token with spaces before the bracket', ->
      @lexer.chunk = '@entry {'
      expect(@lexer.entryStartToken()).toBe 1

    it 'should not parse a token without the @ sign', ->
      @lexer.chunk = 'entry{'
      expect(@lexer.entryStartToken()).toBe 0

    it 'should not parse a token without the bracket', ->
      @lexer.chunk = '@entry'
      expect(@lexer.entryStartToken()).toBe 0

    it 'should not parse a token without an entry type', ->
      @lexer.chunk = '@{'
      expect(@lexer.entryStartToken()).toBe 0

  describe 'entryTypeToken', ->
    it 'should parse the entry type', ->
      # the @ is consumed by the ENTRY_START token
      @lexer.chunk = 'entry{'

      expect(@lexer.entryTypeToken()).toBe 6
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'ENTRY_TYPE'
      expect(@lexer.tokens[0][1]).toBe 'entry'

    it 'should parse a token with spaces before the bracket', ->
      @lexer.chunk = 'entry {'
      expect(@lexer.entryTypeToken()).toBe 7

    it 'should not parse a token without the bracket', ->
      @lexer.chunk = 'entry'
      expect(@lexer.entryTypeToken()).toBe 0

    it 'should not parse text after the bracket', ->
      @lexer.chunk = 'entry{blah, blah, blah, blah'
      expect(@lexer.entryTypeToken()).toBe 6

  describe 'identifierToken', ->
    it 'should parse an identifier', ->
      @lexer.chunk = 'beemer'

      expect(@lexer.identifierToken()).toBe 6
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'IDENTIFIER'
      expect(@lexer.tokens[0][1]).toBe 'beemer'

    it 'should only parse up to a comma', ->
      @lexer.chunk = 'beemer,blah'
      expect(@lexer.identifierToken()).toBe 6

    it 'should only parse up to a newline', ->
      @lexer.chunk = 'beemer\nblah'
      expect(@lexer.identifierToken()).toBe 6

    it 'should only parse up to a concat operator', ->
      @lexer.chunk = 'beemer#blah'
      expect(@lexer.identifierToken()).toBe 6

    it 'should not parse a number', ->
      @lexer.chunk = '134'
      expect(@lexer.identifierToken()).toBe 0

  describe 'numberToken', ->
    it 'should parse a number', ->
      @lexer.chunk = '1234'

      expect(@lexer.numberToken()).toBe 4
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'NUMBER'
      expect(@lexer.tokens[0][1]).toBe '1234'

    it 'should only parse digits', ->
      @lexer.chunk = '1234a'
      expect(@lexer.numberToken()).toBe 4

    it 'should not parse non-digits', ->
      @lexer.chunk = 'abc'
      expect(@lexer.numberToken()).toBe 0

  describe 'keyToken', ->
    it 'should parse a key', ->
      @lexer.chunk = 'key = value'

      expect(@lexer.keyToken()).toBe 6
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'KEY'
      expect(@lexer.tokens[0][1]).toBe 'key'

    it 'should parse a key without spaces', ->
      @lexer.chunk = 'key=value'

      expect(@lexer.keyToken()).toBe 4
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'KEY'
      expect(@lexer.tokens[0][1]).toBe 'key'

    it 'should parse a key with hyphens', ->
      @lexer.chunk = 'key-token = value'

      expect(@lexer.keyToken()).toBe 12
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'KEY'
      expect(@lexer.tokens[0][1]).toBe 'key-token'

    it 'should parse a token without a value', ->
      @lexer.chunk = 'key ='

      expect(@lexer.keyToken()).toBe 5
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'KEY'
      expect(@lexer.tokens[0][1]).toBe 'key'

    it 'should parse a key with a newline before the value', ->
      @lexer.chunk = 'key =\nvalue'

      expect(@lexer.keyToken()).toBe 6
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'KEY'
      expect(@lexer.tokens[0][1]).toBe 'key'

    it 'should parse a key with a newline before the equals sign', ->
      @lexer.chunk = 'key\n= value'

      expect(@lexer.keyToken()).toBe 6
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'KEY'
      expect(@lexer.tokens[0][1]).toBe 'key'

    it 'should not parse a token without an equals sign', ->
      @lexer.chunk = 'key value'
      expect(@lexer.keyToken()).toBe 0

  describe 'valueToken', ->
    it 'should parse a value token', ->
      @lexer.chunk = '{value}'

      expect(@lexer.valueToken()).toBe 7
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'VALUE'
      expect(@lexer.tokens[0][1]).toBe 'value'

    it 'should parse values with nested brackets', ->
      @lexer.chunk = '{value {other value}}'

      expect(@lexer.valueToken()).toBe 21
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'VALUE'
      expect(@lexer.tokens[0][1]).toBe 'value {other value}'

    it 'should parse values with deeply nested brackets', ->
      @lexer.chunk = '{value {{oth}er value}}'

      expect(@lexer.valueToken()).toBe 23
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'VALUE'
      expect(@lexer.tokens[0][1]).toBe 'value {{oth}er value}'

    it 'should parse valuse with newlines', ->
      @lexer.chunk = '{value\nother value}'

      expect(@lexer.valueToken()).toBe 19
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'VALUE'
      expect(@lexer.tokens[0][1]).toBe 'value other value'

    it 'should not parse a token without brackets', ->
      @lexer.chunk = 'value'
      expect(@lexer.valueToken()).toBe 0

    it 'should not parse a token without a closing bracket', ->
      @lexer.chunk = '{value'
      expect(@lexer.valueToken()).toBe 0

    it 'should not parse a token with unmatched nested bracket', ->
      @lexer.chunk = '{value {other value}'
      expect(@lexer.valueToken()).toBe 0

  describe 'quotedStringToken', ->
    it 'should parse a quoted string token', ->
      @lexer.chunk = '"value"'

      expect(@lexer.quotedStringToken()).toBe 7
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'QUOTED_STRING'
      expect(@lexer.tokens[0][1]).toBe 'value'

    it 'should parse quoted string with escaped quotes', ->
      @lexer.chunk = '"value \\"other value\\""'

      expect(@lexer.quotedStringToken()).toBe 23
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'QUOTED_STRING'
      expect(@lexer.tokens[0][1]).toBe 'value "other value"'

    it 'should parse a quoted string with a newline', ->
      @lexer.chunk = '"value\nother value"'

      expect(@lexer.quotedStringToken()).toBe 19
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'QUOTED_STRING'
      expect(@lexer.tokens[0][1]).toBe 'value other value'

    it 'should collapse newlines and spaces', ->
      @lexer.chunk = '"value\n     other value"'

      expect(@lexer.quotedStringToken()).toBe 24
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'QUOTED_STRING'
      expect(@lexer.tokens[0][1]).toBe 'value other value'

    it 'should parse a quoted string that ends with a newline', ->
      @lexer.chunk = '"value\n"'

      expect(@lexer.quotedStringToken()).toBe 8
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'QUOTED_STRING'
      expect(@lexer.tokens[0][1]).toBe 'value'

    it 'shoud not parse a token without quotes', ->
      @lexer.chunk = 'value'
      expect(@lexer.quotedStringToken()).toBe 0

    it 'should not parse a token without a starting quote', ->
      @lexer.chunk = '"value'
      expect(@lexer.quotedStringToken()).toBe 0

    it 'should not parse a token without an ending quote', ->
      @lexer.chunk = 'value"'
      expect(@lexer.quotedStringToken()).toBe 0

  describe 'entryEndToken', ->
    it 'should parse an entry end token', ->
      @lexer.chunk = '}'

      expect(@lexer.entryEndToken()).toBe 1
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe 'ENTRY_END'
      expect(@lexer.tokens[0][1]).toBe '}'

    it 'should not parse a non-closing token', ->
      @lexer.chunk = 'blah}'
      expect(@lexer.entryEndToken()).toBe 0

  describe 'hash', ->
    it 'should parse a hash token', ->
      @lexer.chunk = '#'

      expect(@lexer.hashToken()).toBe 1
      expect(@lexer.tokens.length).toBe 1
      expect(@lexer.tokens[0][0]).toBe '#'
      expect(@lexer.tokens[0][1]).toBe '#'

    it 'should not parse a non-hash token', ->
      @lexer.chunk = 'blah#'
      expect(@lexer.hashToken()).toBe 0

  describe 'commaToken', ->
    it 'should consume a comma', ->
      @lexer.chunk = ','

      expect(@lexer.commaToken()).toBe 1
      expect(@lexer.tokens.length).toBe 0

    it 'should not consume a non-comma token', ->
      @lexer.chunk = 'blah,'
      expect(@lexer.commaToken()).toBe 0

  describe 'whitespaceToken', ->
    it 'should consume a space', ->
      @lexer.chunk = ' '

      expect(@lexer.whitespaceToken()).toBe 1
      expect(@lexer.tokens.length).toBe 0

    it 'should consume multiple spaces', ->
      @lexer.chunk = '          '
      expect(@lexer.whitespaceToken()).toBe 10

    it 'should consume tabs', ->
      @lexer.chunk = '\t\t\t'
      expect(@lexer.whitespaceToken()).toBe 3

    it 'should consume newlines', ->
      @lexer.chunk = '\n\n'
      expect(@lexer.whitespaceToken()).toBe 2

    it 'should consume a string of mixed whitespace tokens', ->
      @lexer.chunk = '  \n\t  \n'
      expect(@lexer.whitespaceToken()).toBe 7

    it 'should not consume non-whitespace tokens', ->
      @lexer.chunk = 'blah '
      expect(@lexer.whitespaceToken()).toBe 0

  describe 'tokenize', ->
    it 'should properly tokenize an entry', ->
      tokens = @lexer.tokenize('''
        @book{ citekey,
          author = { Bloggs, Joe },
        }
      ''')

      expect(tokens.length).toBe 7
      expect(tokens[0][0]).toBe 'ENTRY_START'
      expect(tokens[1][0]).toBe 'ENTRY_TYPE'
      expect(tokens[1][1]).toBe 'book'
      expect(tokens[2][0]).toBe 'IDENTIFIER'
      expect(tokens[2][1]).toBe 'citekey'
      expect(tokens[3][0]).toBe 'KEY'
      expect(tokens[3][1]).toBe 'author'
      expect(tokens[4][0]).toBe 'VALUE'
      expect(tokens[4][1]).toBe 'Bloggs, Joe'
      expect(tokens[5][0]).toBe 'ENTRY_END'
      expect(tokens[6][0]).toBe 'EOF'

    it 'should tokenize an entry with spaces before entry brackets', ->
      tokens = @lexer.tokenize('''
        @book { citekey,
          author = { Bloggs, Joe },
        }
      ''')

      expect(tokens.length).toBe 7
      expect(tokens[0][0]).toBe 'ENTRY_START'
      expect(tokens[1][0]).toBe 'ENTRY_TYPE'
      expect(tokens[1][1]).toBe 'book'
      expect(tokens[2][0]).toBe 'IDENTIFIER'
      expect(tokens[2][1]).toBe 'citekey'
      expect(tokens[3][0]).toBe 'KEY'
      expect(tokens[3][1]).toBe 'author'
      expect(tokens[4][0]).toBe 'VALUE'
      expect(tokens[4][1]).toBe 'Bloggs, Joe'
      expect(tokens[5][0]).toBe 'ENTRY_END'
      expect(tokens[6][0]).toBe 'EOF'

    it 'should tokenize an entry with hashes', ->
      tokens = @lexer.tokenize('@preamble{constant # other_constant}')

      expect(tokens.length).toBe 6
      expect(tokens[1][0]).toBe 'IDENTIFIER'
      expect(tokens[1][1]).toBe 'constant'
      expect(tokens[2][0]).toBe '#'
      expect(tokens[3][0]).toBe 'IDENTIFIER'
      expect(tokens[3][1]).toBe 'other_constant'
      expect(tokens[4][0]).toBe 'ENTRY_END'
      expect(tokens[5][0]).toBe 'EOF'

    it 'should tokenize multiple entries', ->
      tokens = @lexer.tokenize('''
        @book{ citekey,
          author = { Bloggs, Joe },
        }

        @book{ citekey,
          author = { Bloggs, Joe },
        }
      ''')

      expect(tokens.length).toBe 13
      expect(tokens[0][0]).toBe 'ENTRY_START'
      expect(tokens[1][0]).toBe 'ENTRY_TYPE'
      expect(tokens[1][1]).toBe 'book'
      expect(tokens[2][0]).toBe 'IDENTIFIER'
      expect(tokens[2][1]).toBe 'citekey'
      expect(tokens[3][0]).toBe 'KEY'
      expect(tokens[3][1]).toBe 'author'
      expect(tokens[4][0]).toBe 'VALUE'
      expect(tokens[4][1]).toBe 'Bloggs, Joe'
      expect(tokens[5][0]).toBe 'ENTRY_END'
      expect(tokens[6][0]).toBe 'ENTRY_START'
      expect(tokens[7][0]).toBe 'ENTRY_TYPE'
      expect(tokens[7][1]).toBe 'book'
      expect(tokens[8][0]).toBe 'IDENTIFIER'
      expect(tokens[8][1]).toBe 'citekey'
      expect(tokens[9][0]).toBe 'KEY'
      expect(tokens[9][1]).toBe 'author'
      expect(tokens[10][0]).toBe 'VALUE'
      expect(tokens[10][1]).toBe 'Bloggs, Joe'
      expect(tokens[11][0]).toBe 'ENTRY_END'
      expect(tokens[12][0]).toBe 'EOF'

    it 'should ignore anything before an entry', ->
      tokens = @lexer.tokenize('''
        Unfortunately, the way BibTeX works, anything can be here, anything
        at all. It doesn't matter what. Even things that look like part = { of
        and entry}

        @book{ citekey,
          author = { Bloggs, Joe },
        }
      ''')

      expect(tokens.length).toBe 7
      expect(tokens[0][0]).toBe 'ENTRY_START'
      expect(tokens[1][0]).toBe 'ENTRY_TYPE'
      expect(tokens[1][1]).toBe 'book'
      expect(tokens[2][0]).toBe 'IDENTIFIER'
      expect(tokens[2][1]).toBe 'citekey'
      expect(tokens[3][0]).toBe 'KEY'
      expect(tokens[3][1]).toBe 'author'
      expect(tokens[4][0]).toBe 'VALUE'
      expect(tokens[4][1]).toBe 'Bloggs, Joe'
      expect(tokens[5][0]).toBe 'ENTRY_END'
      expect(tokens[6][0]).toBe 'EOF'

    it 'should ignore anything after an entry', ->
      tokens = @lexer.tokenize('''
        @book{ citekey,
          author = { Bloggs, Joe },
        }

        Unfortunately, the way BibTeX works, anything can be here, anything
        at all. It doesn't matter what. Even things that look like part = { of
        and entry}
      ''')

      expect(tokens.length).toBe 7
      expect(tokens[0][0]).toBe 'ENTRY_START'
      expect(tokens[1][0]).toBe 'ENTRY_TYPE'
      expect(tokens[1][1]).toBe 'book'
      expect(tokens[2][0]).toBe 'IDENTIFIER'
      expect(tokens[2][1]).toBe 'citekey'
      expect(tokens[3][0]).toBe 'KEY'
      expect(tokens[3][1]).toBe 'author'
      expect(tokens[4][0]).toBe 'VALUE'
      expect(tokens[4][1]).toBe 'Bloggs, Joe'
      expect(tokens[5][0]).toBe 'ENTRY_END'
      expect(tokens[6][0]).toBe 'EOF'

    it 'should ignore anything between entries', ->
      tokens = @lexer.tokenize('''
        @book{ citekey,
          author = { Bloggs, Joe },
        }

        Unfortunately, the way BibTeX works, anything can be here, anything
        at all. It doesn't matter what. Even things that look like part = { of
        and entry}

        @book{ citekey,
          author = { Bloggs, Joe },
        }
      ''')

      expect(tokens.length).toBe 13
      expect(tokens[0][0]).toBe 'ENTRY_START'
      expect(tokens[1][0]).toBe 'ENTRY_TYPE'
      expect(tokens[1][1]).toBe 'book'
      expect(tokens[2][0]).toBe 'IDENTIFIER'
      expect(tokens[2][1]).toBe 'citekey'
      expect(tokens[3][0]).toBe 'KEY'
      expect(tokens[3][1]).toBe 'author'
      expect(tokens[4][0]).toBe 'VALUE'
      expect(tokens[4][1]).toBe 'Bloggs, Joe'
      expect(tokens[5][0]).toBe 'ENTRY_END'
      expect(tokens[6][0]).toBe 'ENTRY_START'
      expect(tokens[7][0]).toBe 'ENTRY_TYPE'
      expect(tokens[7][1]).toBe 'book'
      expect(tokens[8][0]).toBe 'IDENTIFIER'
      expect(tokens[8][1]).toBe 'citekey'
      expect(tokens[9][0]).toBe 'KEY'
      expect(tokens[9][1]).toBe 'author'
      expect(tokens[10][0]).toBe 'VALUE'
      expect(tokens[10][1]).toBe 'Bloggs, Joe'
      expect(tokens[11][0]).toBe 'ENTRY_END'
      expect(tokens[12][0]).toBe 'EOF'

    it 'should raise an error on unrecognizable tokens', ->
      expect(@lexer.tokenize.bind(@lexer, '@entry { ______ }')).toThrowError(
        SyntaxError, /unexpected tokens:.+/
      )
