module.exports =
class BuilderRegistry
  constructor: ->
    @builders = {}

  clear: ->
    @builders = {}

  add: (names, cls) ->
    names = [names] unless Array.isArray names

    for name in names
      @builders[name] = cls

  get: (name) ->
    return @builders[name] if name of @builders
    undefined
