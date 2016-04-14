exports.count = (string, substr) ->
  num = pos = 0
  return 1/0 unless substr.length
  num++ while pos = 1 + string.indexOf substr, pos
  num

# Throws a SyntaxError from a given location.
# The error's `toString` will return an error message following the "standard"
# format <filename>:<line>:<col>: <message> plus the line with the error and a
# marker showing where the error is.
exports.throwSyntaxError = (message, location) ->
  error = new SyntaxError message
  error.location = location
  error.toString = syntaxErrorToString

  # Instead of showing the compiler's stacktrace, show our custom error message
  # (this is useful when the error bubbles up in Node.js applications that
  # compile CoffeeScript for example).
  error.stack = error.toString()

  throw error

syntaxErrorToString = ->
  return Error::toString.call @ unless @location

  filename = @filename or "[stdin]"
  {first_line, first_column, last_line, last_column} = @location

  """
  #{filename}:#{first_line + 1}:#{first_column + 1}: error: #{@message}
  """
