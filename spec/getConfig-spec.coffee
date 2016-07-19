latextools = require '../lib/latextools'
{getValueAtKeyPath} = require 'key-path-helpers'

class ProjectDummy
  constructor: ->
    @config = {}

  get: (keyPath) ->
    getValueAtKeyPath(@config, keyPath)

describe 'getConfig', ->
  beforeEach ->
    atom.config.set 'latextools.useProjectFiles', true
    latextools.requireIfNeeded = () ->
    latextools.projectManager = new Object
      getProject: => @project
    @project = new ProjectDummy
    @te = new Object getPath: -> ''

  it 'should return project setting', ->
    @project.config = latextools: value: 'match'
    result = latextools.getConfig 'latextools.value', @te
    expect(result).toEqual 'match'

  describe 'iteraction with atom.config', ->
    afterEach ->
      atom.config.unset 'latextools.value'

    it 'should override the atom setting if project setting set', ->
      atom.config.set 'latextools.value', 'atom.config', save: false
      @project.config = latextools: value: 'project.config'

      result = latextools.getConfig 'latextools.value', @te
      expect(result).toEqual 'project.config'

    it 'should return the atom setting if project setting unset', ->
      atom.config.set 'latextools.value', 'atom.config', save: false
      result = latextools.getConfig 'latextools.value', @te
      expect(result).toEqual 'atom.config'

    it 'should return the atom setting if project setting undefined', ->
      atom.config.set 'latextools.value', 'atom.config', save: false
      @project.config = latextools: value: undefined

      result = latextools.getConfig 'latextools.value', @te
      expect(result).toEqual 'atom.config'

    it 'should return the atom setting if project not found', ->
      atom.config.set 'latextools.value', 'atom.config', save: false
      latextools.projectManager.getProject = -> undefined

      result = latextools.getConfig 'latextools.value', @te
      expect(result).toEqual 'atom.config'

    it 'should return the atom setting if useProjectFiles is false', ->
      atom.config.set 'latextools.useProjectFiles', false
      atom.config.set 'latextools.value', 'atom.config', save: false
      result = latextools.getConfig 'latextools.value', @te
      expect(result).toEqual 'atom.config'
