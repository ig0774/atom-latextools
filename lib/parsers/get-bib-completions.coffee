fs = require 'fs'
{Parser} = require './bibtex/parser'
{Name, NAME_FIELDS} = require './bibtex/names'
{tokenizeList} = require './bibtex/tex'

get_title_short = (title) ->
  return '' unless title? and title isnt ''

  sep = /:|\.|\?/
  title = title.split(sep)[0]
  if title.length > 40
    title[...40] + '...'
  else
    title

get_name_short = (authors) ->
  if authors.length > 2
    "#{authors[0].last}, et al."
  else
    ("#{author.last}" for author in authors).join ' & '

remove_latex_commands = (s) ->
  chars = []
  # parsing state
  found_slash = false

  for c in s
    switch c
      when '{'
        # entering contents of command
        found_slash = false
      when '}'
        continue
      when '\\'
        found_slash = true
      else
        if not found_slash
          chars.push c
        else if /\s/g.test c
          found_slash = false

  chars.join ''

class EntryWrapper
  constructor: (entry) ->
    for own prop of entry
      continue if prop is '_database'
      if prop in NAME_FIELDS
        people = (new Name(n) for n in tokenizeList(entry[prop]))
        @[prop] = people.join ' and '
        @["#{prop}_short"] = get_name_short people
      else
        @[prop] = entry[prop]

    @[prop] = remove_latex_commands @[prop]

    @.title_short = get_title_short(@.title) if @.title?

    @.keyword = @.citeKey
    @.author = @.editor or '????' unless @.author?
    @.journal = @.journaltitle or @.eprint or '????' unless @.journal?

module.exports =
get_bib_completions = (bibfile) ->
  try
    bib = fs.readFileSync(bibfile, 'utf-8')
  catch error
    atom.notifications.addError "cannot read #{bibfile}",
      detail: error.toString()
    return

  parser = new Parser()
  bibdata = parser.parse(bib)

  return (
    for _, entry of bibdata.entries
      new EntryWrapper(entry) unless entry.entryType in [
        'comment', 'string', 'entryset', 'xdata'
      ]
  )
