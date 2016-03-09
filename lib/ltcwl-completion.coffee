path = require 'path'
fs = require 'fs'

module.exports =
  selector: '.text.tex.latex'
  disableForSelector: '.comment.line.percentage.tex'
  filterSuggestions: true

  getSuggestions: ({editor, bufferPosition, scopeDescriptor}) ->
    [prefix, is_valid_prefix] = @_getValidPrefix(editor, bufferPosition)

    suggestions = []
    # if not a valid prefix, do nothing
    if not is_valid_prefix
      return suggestions

    env_name = null
    # if in an environment then get environment name,
    # to avoid searching in whole buffer
    if @_isEnvironment scopeDescriptor
      env_name = @_getEnvironmentName(editor, bufferPosition)

    # put \end of this environment at the top of suggest list
    if env_name?
      suggestions.push
        snippet: "end{${1:#{env_name}}}$0"
        rightLabel: path.basename(editor.getPath())

    # generating suggestions from @completions
    for x in @completions

      # if not in a environment, do not include '\end' tag
      # in the suggest list
      if not env_name? and x[0].match(/^end\{[^\}]*\}/)?
        continue

      # if snippet
      if x[2]
        suggestions.push
          snippet: x[0]
          rightLabel: x[1]
      else
        suggestions.push
          text: x[0]
          rightLabel: x[1]

    return suggestions

  # trigger auto indent after insert completions
  onDidInsertSuggestion: ({editor}) ->
    atom.commands.dispatch(atom.views.getView(editor), "editor:auto-indent")

  # validate and paring prefix
  _getValidPrefix: (editor, bufferPosition) ->
    prefix_pattern = /^\w*[\\]+/
    line = editor.getTextInRange([[bufferPosition.row, 0], bufferPosition]).split('').reverse().join('')
    prefix = line.match(prefix_pattern)?[0].split('').reverse().join('') or ''

    # validate prefix accroding the configuration of "latextools.commandCompletion"
    is_valid_prefix = true
    if prefix.length == 0 or @commandCompletion == 'prefixed' and /[\\]{2,}/g.exec(prefix)?
      is_valid_prefix = false

    # trim '\' charactors of the prefix
    prefix = prefix.replace /[\\]+/, ''
    [prefix, is_valid_prefix]

  # check if in environment
  _isEnvironment: (scopeDescriptor) ->
    for x in scopeDescriptor.scopes
      if x.indexOf('environment') > 0
        return true
    false

  # get nearest unclosed environment's name
  _getEnvironmentName: (editor, bufferPosition)->
    env_begin_pattern = /\}([^\}]+)\{(?:\][^\]]+\[)?nigeb\\/g
    env_end_pattern = /\}[^\}]+\{dne\\/g

    env_pairs = []
    current_row = bufferPosition.row

    env_name = null
    # from current_row to the beginning,
    # to search current unclosed environment's name
    while current_row > 0

      # get line's
      if current_row == bufferPosition.row
        line = editor.getTextInRange([[current_row, 0], bufferPosition])
      else
        line = editor.getBuffer().lineForRow(current_row)

      line = line.split('').reverse().join('')

      # if find end env tag
      end_match = env_end_pattern.exec(line)
      while end_match?
        env_pairs.push 1
        end_match = env_end_pattern.exec(line)

      # search begin env tag
      # env_name = line.match(env_begin_pattern)?[1].split('').reverse().join('') or null
      start_match = env_begin_pattern.exec(line)
      while start_match?
        if env_pairs.length == 0
          env_name = start_match[1].split('').reverse().join('')
          break
        env_pairs.pop()
        start_match = env_begin_pattern.exec(line)

      current_row -= 1

    env_name

  # loading cwl snippet from file
  loadCompletions: ->
    console.log "load cwl completions files"

    # for saving parsed cwl snippet
    @completions = []

    # get commandCompletion
    @commandCompletion = atom.config.get("latextools.commandCompletion")

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
          l = line.trim()

          # ignore comment and blank lines
          if not l.startsWith('#') and l.length != 0
            parse_result = @_parseCwlSnippets l
            if parse_result?
              @completions.push [parse_result.slice(1), cwl, true]
            else
              @completions.push [l.slice(1), cwl, false]

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
        g = if p1? then p1 else if p2? then p2 else if p3? then p3
        if g.length != 0
          return m.replace g, "$$\{#{replace_index}:#{g}\}"

      parsing_result = "#{parsing_result}$0"

    parsing_result
