exports.Database    = class Database
  constructor: ->
    @preamble   = undefined
    @macros     = {
      "jan": "January",
      "feb": "February",
      "mar": "March",
      "apr": "April",
      "may": "May",
      "jun": "June",
      "jul": "July",
      "aug": "August",
      "sep": "September",
      "oct": "October",
      "nov": "November",
      "dec": "December"
    }
    @entries    = new Object
    Object.defineProperty(@entries, 'length', {
      __proto__: null
      get: => (entry for entry of @entries).length
    })

  addPreamble: (preamble) ->
    @preamble = preamble

  addMacro: (macro) ->
    @macros[macro.key.toLowerCase()] = macro.value

  addEntry: (entry) ->
    entry._database = this
    @entries[entry.citeKey.toLowerCase()] = entry

  getPreamble: ->
    @preamble

  getMacro: (key) ->
    @macros[key.toLowerCase()] or key

  getEntry: (key) ->
    @entries[key.toLowerCase()]

  toString: ->
    "<Database> [#{entry for entry of @entries}]"

exports.Entry       = class Entry
  constructor: (entryType, citeKey) ->
    @entryType  = entryType?.toLowerCase()
    @citeKey    = citeKey
    @_database   = null

  getAttribute: (attribute) ->
    @[attribute.toLowerCase()]

  setAttribute: (attribute, value) ->
    @[attribute.toLowerCase()] = value

  toString: ->
    @citeKey
