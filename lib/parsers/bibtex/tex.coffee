exports.splitTeXString = splitTeXString = (string, {maxSplit, sep}={}) ->
  maxSplit ?= Math.Infinity
  sep ?= '[\\s~]+'

  next_break = new RegExp("\\{|\\}|(#{sep})", "gm")

  result = []
  brace_level = 0
  word_start = 0
  splits = 0

  i = 0

  while i < string.length
    break if splits is maxSplit
    match = next_break.exec string
    if match?
      i = next_break.lastIndex
      switch match[0]
        when '{'
          brace_level++
        when '}'
          brace_level--
        else
          if brace_level is 0 and match[1]?
            result.push string.substring word_start, match.index
            word_start = match.index + match[0].length
            splits += 1
    else
      i = string.length

  if word_start < string.length
    result.push string.substring word_start, string.length

  result

exports.tokenizeList = tokenizeList = (list, _and = "and") ->
  splitTeXString(list, sep: "[\\s~]+#{_and}(?:[\\s~]+|$)")
