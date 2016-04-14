{Lexer} = require './lexer'
{Database, Entry} = require './datamodel'
{throwSyntaxError} = require './helpers'
{Name, NAME_FIELDS} = require './names'
{tokenizeList} = require './tex'
ast = require './ast'

exports.Parser = class Parser
  parse: (s, lexer = new Lexer()) ->
    @lexer = lexer
    @tokens = @lexer.tokenize(s)
    @database = new Database

    # internal state
    @currentToken = 0
    @tokensLen = @tokens.length
    @markLocations = []

    @error 'no entries' if @tokensLen < 0

    loop
      try
        @advance()
      catch
        @unexpectedToken 'preamble, string, entry_start, or eof'

      switch @tokenType
        when 'PREAMBLE'
          preamble = @preamble()
          @database.addPreamble @handleValue(preamble.contents)
        when 'STRING'
          string = @string()
          @database.addMacro key: string.key, value: @handleValue(string.value)
        when 'ENTRY_START'
          entryNode = @entry()

          entry = new Entry entryNode.entryType, entryNode.key.value

          for field in entryNode.fields
            entry.setAttribute field.key, @handleValue(field.value)
            if field.key in NAME_FIELDS
              entry[field.key] = (
                new Name(s).toString() for s in tokenizeList(entry[field.key])
              ).join ' and '

          @database.addEntry entry
        when 'EOF'
          return @database
        else @unexpectedToken 'preamble, string, entry_start, or eof'

  # token traversal
  advance: ->
    if @currentToken >= @tokensLen
      throw name: 'IndexError', message: 'no more tokens available'
    [@tokenType, @tokenValue, @lineInfo] = @tokens[@currentToken++]

  mark: ->
    @markLocations.push @currentToken

  unmark: ->
    @markLocations.pop()

  rewind: ->
    previousLocation = @markLocations.pop()
    unless previousLocation?
      if @currentToken <= 0
        throw
          name: 'IndexError',
          message: 'attempted to rewind before the beginning of tokens'
      @currentToken--
    else
      @currentToken = previousLocation

    currentToken = @tokens[@currentToken]
    if currentToken?
      [@tokenType, @tokenValue, @lineInfo] = currentToken
    else
      [@tokenType, @tokenValue, @lineInfo] = [undefined, undefined, undefined]

  # token handlers
  preamble: ->
    node = new ast.PreambleNode
    try
      node.contents = @fieldValue()
    catch
      @rewind()

    try
      @advance()
    catch
      @unexpectedToken('entry_end')

    if @tokenType isnt 'ENTRY_END'
      @unexpectedToken('entry_end')

    node

  string: ->
    node = new ast.StringNode
    try
      @advance()
    catch
      @unexpectedToken('key')

    if @tokenType isnt 'KEY'
      @unexpectedToken('key')

    # no expansion
    node.key = @tokenValue
    node.value = @stringValue()

    try
      @advance()
    catch
      @unexpectedToken('entry_end')

    if @tokenType isnt 'ENTRY_END'
      @unexpectedToken('entry_end')

    node

  entry: ->
    try
      @advance()
    catch
      @unexpectedToken('entry_type')

    if @tokenType isnt 'ENTRY_TYPE'
      @unexpectedToken('entry_type')

    node = new ast.EntryNode
    node.entryType = @tokenValue
    node.key = @entryKey()
    node.fields = @keyValues()

    try
      @advance()
    catch
      @unexpectedToken('entry_end')

    if @tokenType isnt 'ENTRY_END'
      @unexpectedToken('entry_end')

    node

  entryKey: ->
    try
      @advance()
    catch
      @unexpectedToken('identifier')

    if @tokenType isnt 'IDENTIFIER'
      @unexpectedToken('identifier')

    node = new ast.EntryKeyNode
    node.value = @tokenValue

    node

  stringValue: ->
    try
      @advance()
    catch
      @unexpectedToken('quoted_string or value')

    if @tokenType isnt 'QUOTED_STRING' and @tokenType isnt 'VALUE'
      @unexpectedToken('quoted_string or value')

    node = new ast.QuotedLiteralNode
    node.value = @tokenValue

    node

  keyValues: ->
    values = []

    loop
      try
        @advance()
      catch
        break

      if @tokenType isnt 'KEY'
        @rewind()
        break

      node = new ast.KeyValueNode
      node.key = @tokenValue
      node.value = @fieldValue()
      values.push node

    values

  fieldValue: ->
    @concatenatedValue() or @value()

  concatenatedValue: ->
    @mark()
    try
      lhs = @value()
    catch
      @rewind()
      return false

    try
      @advance()
    catch
      @rewind()
      return false

    if @tokenType isnt '#'
      @rewind()
      return false

    try
      rhs = @fieldValue()
    catch
      @rewind()
      return false

    @unmark()

    node = new ast.ConcatenationNode
    node.lhs = lhs
    node.rhs = rhs

    node

  value: ->
    try
      @advance()
    catch
      @unexpectedToken('quoted_string, value, identifier, or number')

    switch @tokenType
      when 'QUOTED_STRING'
        node = new ast.QuotedLiteralNode
      when 'NUMBER'
        node = new ast.NumberNode
      when 'VALUE'
        node = new ast.QuotedLiteralNode
      when 'IDENTIFIER'
        node = new ast.LiteralNode
      else
        @unexpectedToken('quoted_string, value, identifier, or number')

    node.value = @tokenValue

    node

  unexpectedToken: (expecting) ->
    line = @lineInfo?.first_line or -1
    column = @lineInfo?.first_column or -1

    if expecting isnt null
      expecting = "; expecting #{expecting}"
    else
      expecting = ""

    if @tokenType is undefined
      tokenType = 'eof'
    else
      tokenType = @tokenType.toLowerCase()

    if line > 0 and column > 0
      throwSyntaxError \
        "#{line + 1}:#{column + 1} - unexpected #{tokenType}#{expecting}"
    else
      throwSyntaxError "unexpected #{tokenType}#{expecting}"

  # ast transforms
  handleValue: (value) ->
    if value instanceof ast.ConcatenationNode
      [
        @handleValue(value.lhs),
        @handleValue(value.rhs)
      ].join('')
    else if value instanceof ast.LiteralNode
      macro = value.value
      @database.getMacro(macro) or macro
    else
      value.value
