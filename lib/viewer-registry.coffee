{CompositeDisposable} = require 'atom'

module.exports =
class ViewerRegistry
  constructor: ->
    @viewers = {}

  clear: ->
    @viewers = {}

  add: (names, cls) ->
    names = [names] unless Array.isArray names

    for name in names
      @viewers[name] = cls

  get: (name) ->
    return @viewers[name] if name of @viewers
    undefined

  updateConfigSchema: ->
    viewers = Object.keys(@viewers)
      .filter((n) -> n isnt 'default')
      .sort()

    viewers.unshift('default')

    atom.config.getSchema('latextools.viewer').enum = viewerList
