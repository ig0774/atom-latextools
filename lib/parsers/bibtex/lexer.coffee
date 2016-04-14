{count, throwSyntaxError} = require './helpers'

# Emit tokens as
#
#   [tag, value, locationData]
#
# where locationData is {first_line, first_column, last_line, last_column}
exports.Lexer = class Lexer
  constructor: ->
    @tokens = []
    @chunkLine = 0
    @chunkColumn = 0
    @inEntry = false

  tokenize: (code) ->
    @tokens = []
    @chunkLine = 0
    @chunkColumn = 0
    @inEntry = false

    i = 0
    while @chunk = code[i..]
      if not @inEntry
        consumed = @untilEntry()
        @inEntry = true
        startEntry = true
      else
        if startEntry
          consumed = \
            @preambleToken()      or
            @stringToken()        or
            @commentToken()       or
            @entryStartToken()    or
            @tokenError()

          startEntry = false
        else if @tokens.slice(-1)[0][0] == 'ENTRY_START'
          consumed = \
            @entryTypeToken()     or
            @tokenError()
        else
          consumed = \
            @whitespaceToken()    or
            @commaToken()         or
            @keyToken()           or
            @identifierToken()    or
            @numberToken()        or
            @valueToken()         or
            @quotedStringToken()  or
            @hashToken()          or
            @entryEndToken()      or
            @tokenError()

      [@chunkLine, @chunkColumn] = @getLineAndColumnFromChunk consumed

      i += consumed

    @tokens.push ['EOF', '', {}]
    return @tokens

  untilEntry: ->
    match = @chunk.search(ENTRY_START)
    if match is -1
      @chunk.length
    else
      # don't consume the @
      match

  preambleToken: ->
    return 0 unless match = PREAMBLE.exec @chunk
    @token 'PREAMBLE', match[1]
    match[0].length

  stringToken: ->
    return 0 unless match = STRING.exec @chunk
    @token 'STRING', match[1]
    match[0].length

  commentToken: ->
    return 0 unless match = COMMENT.exec @chunk
    @inEntry = false
    match[0].length

  entryStartToken: ->
    return 0 unless match = ENTRY_START.exec @chunk
    @token 'ENTRY_START', match[0]
    match[0].length

  entryTypeToken: ->
    return 0 unless match = ENTRY_TYPE.exec @chunk
    @token 'ENTRY_TYPE', match[1]
    match[0].length

  identifierToken: ->
    return 0 unless match = IDENTIFIER.exec @chunk
    @token 'IDENTIFIER', match[0]
    match[0].length

  numberToken: ->
    return 0 unless match = NUMBER.exec @chunk
    @token 'NUMBER', match[0]
    match[0].length

  keyToken: ->
    return 0 unless match = KEY.exec @chunk
    @token 'KEY', match[1]
    match[0].length

  valueToken: ->
    return 0 if @chunk[0] isnt '{'
    value = ''

    depth = 0
    i = 1
    while c = @chunk[i]
      if c is '}'
        break if depth-- <= 0
        value += c
      else if c is '{'
        depth++
        value += c
      else if c is '\n'
        # if we have a new line, replace whitespace with a single space
        replaced_chars = @chunk[i..].split(WHITESPACE)[1]
        i += replaced_chars.length
        value += ' '
        continue
      else
        value += c

      i++

    return 0 if depth >= 0

    # store length of chunk consumed
    length = i + 1
    @token 'VALUE', value.trim()

    length

  quotedStringToken: ->
    return 0 unless @chunk[0] is '"'
    value = ''

    i = 1
    previous = null

    while c = @chunk[i]
      if c is '"'
        break if previous isnt '\\'
        value = value[...-1]
      else if c is '\n'
        # consume all the whitespace after a newline
        i++
        while c = @chunk[i]
          break if c isnt ' ' and c isnt '\t'
          i++
        # replace newline with single space
        value += ' '
        previous = ' '
        continue

      value += c
      previous = c
      i++

    # consume possible trailing space
    value = value[...-1] if previous is ' '

    # exit without a closing quote
    return 0 if c isnt '"'

    @token 'QUOTED_STRING', value
    i + 1

  entryEndToken: ->
    return 0 unless @chunk[0] is '}'

    @inEntry = false

    @token 'ENTRY_END', '}'
    1

  commaToken: ->
    return 0 unless @chunk[0] is ','
    1

  hashToken: ->
    return 0 unless @chunk[0] is '#'
    @token '#', '#'
    1

  whitespaceToken: ->
    return 0 unless match = WHITESPACE.exec @chunk
    match[0].length

  tokenError: ->
    @error "unexpected tokens: #{@chunk.split(/[\n\r]+/)[0]}"

  getLineAndColumnFromChunk: (offset) ->
    if offset is 0
      return [@chunkLine, @chunkColumn]

    string =
      if offset >= @chunk.length
        @chunk
      else
        @chunk[0...offset]

    lineCount = count string, '\n'

    column = @chunkColumn
    if lineCount > 0
      [..., lastLine] = string.split '\n'
      column = lastLine.length
    else
      column += string.length

    [@chunkLine + lineCount, column]

  makeToken: (tag, value, offsetInChunk = 0, length = value.length) ->
    locationData = {}
    [locationData.first_line, locationData.first_column] =
        @getLineAndColumnFromChunk offsetInChunk

    [locationData.last_line, locationData.last_column] =
        @getLineAndColumnFromChunk offsetInChunk + length

    token = [tag, value, locationData]
    token

  token: (tag, value, offsetInChunk = 0, length = value.length) ->
    token = @makeToken tag, value, offsetInChunk, length
    @tokens.push token
    token

  error: (message, options = {}) ->
    location =
      if 'first_line' of options
        options
      else
        [first_line, first_column] = \
          @getLineAndColumnFromChunk options.offset ? 0
        {first_line, first_column, \
          last_column: first_column + (options.length ? 1) - 1}
    throwSyntaxError message, location

WHITESPACE          = /^([\s\r\n]+)/
PREAMBLE            = /^@(preamble)[\s\r\n]*\{/i
STRING              = /^@(string)[\s\r\n]*\{/i
COMMENT             = /^@(comment)[^\n]+/i
ENTRY_START         = /@(?=[^\W\d_][^,\s]*[\s\n\r]*\{)/
ENTRY_TYPE          = /^([^\W\d_][^,\s]*)[\s\r\n]*\{/
IDENTIFIER          = /^[^\W\d_][^,\s}#]*(?=\s*[,]|\s*#\s*|\s*\}?(?:\n|$))/
NUMBER              = /^\d+/
KEY                 = /^([^\W\d_][^,\s]*)[\s\r\n]*=[\s\r\n]*/

NEXT_QUOTE_BREAK    = /(?:\\")|\n|"/
NEXT_BRACKET_BREAK  = /\{|\}|\n/
SPACE               = /[\s\r\n]+/
