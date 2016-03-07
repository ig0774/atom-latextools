path = require 'path'
fs = require 'fs'

module.exports =
  selector: '.text.tex.latex'
  disableForSelector: '.comment.line.percentage.tex'
  filterSuggestions: true

  getSuggestions: ({editor, bufferPosition, scopeDescriptor}) ->
    prefix = @getPrefix(editor, bufferPosition)

    if not prefix.startsWith('\\')
      return []

    if atom.config.get('latextools.commandCompletion') == 'prefixed' and /[\\]{2,}/g.exec(prefix)?
      return []

    prefix = prefix.replace /[\\]+/, '\\'
    prefix = prefix[1...]

    suggestions = []
    for x in @completions
      suggestion =
        rightLabel: x[1]

      if x[2]
        suggestion.snippet = x[0]
      else
        suggestion.text = x[0]
      suggestions.push suggestion

    suggestions

  getPrefix: (editor, bufferPosition) ->
    prefix = /^\w*[\\]+/
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition]).split('').reverse().join('')
    line.match(prefix)?[0].split('').reverse().join('') or ''

  loadCompletions: ->
    console.log "load cwl completions files"
    @completions = []

    # get cwl_list from config
    cwl_list = atom.config.get('latextools.cwlList')

    # path of saving cwl list
    # Does any one know what license the latexing-cwl is using?
    # could we use them directly?
    cwl_data_path = path.join __dirname, "..", "data", "cwl-completion-files"

    for cwl in cwl_list
      f = path.join(cwl_data_path, "#{cwl}.cwl")
      try
        # reading and parsing cwl files
        lines = fs.readFileSync(f, 'utf8').split('\n')
        for line in lines
          console.log line
          l = line.trim()

          # ignore comment and blank lines
          if not l.startsWith('#') and l.length != 0
            parse_result = @_parseCwlSnippets l
            if parse_result?
              @completions.push [parse_result[1...], cwl, true]
            else
              @completions.push [l[1...], cwl, false]

      catch error
        # if reading errors
        console.log "Reading file #{f} error, make sure it exist!"

  # parsing cwl strings to snippet
  _parseCwlSnippets: (cwl_string) ->

    regex_braces = /\{([^\{\}\[\]\(\)]*)\}|\[([^\{\}\[\]\(\)]*)\]|\(([^\{\}\[\]\(\)]*)\)/g

    parsing_result = null
    if regex_braces.exec(cwl_string)?
      replace_index = 0
      parsing_result = cwl_string.replace regex_braces, (m, p1, p2, p3) ->
        replace_index += 1
        g = if p1?
          p1
        else if p2?
          p2
        else if p3?
          p3
        console.log g
        return m.replace g, "$$\{#{replace_index}:#{g}\}"

    parsing_result
