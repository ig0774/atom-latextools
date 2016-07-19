{Project} = require '../lib/project'
fs = require 'fs'
path = require 'path'

describe 'Project', ->
  afterEach ->
    @project?.dispose()

  it 'should load a JSON project file', ->
    fixturePath = path.join __dirname,  'fixtures',
      'project', 'json-project'

    @project = new Project(fixturePath)
    expect(@project.config.latextools.type).toEqual 'json'

  it 'should load a JSON project file with js extension', ->
    fixturePath = path.join __dirname,  'fixtures',
      'project', 'js-project'

    @project = new Project(fixturePath)
    expect(@project.config.latextools.type).toEqual 'js'

  it 'should load a CSON project file', ->
    fixturePath = path.join __dirname,  'fixtures',
      'project', 'cson-project'

    @project = new Project(fixturePath)
    expect(@project.config.latextools.type).toEqual 'cson'

  it 'should load a YAML project file', ->
    fixturePath = path.join __dirname,  'fixtures',
      'project', 'yaml-project'

    @project = new Project(fixturePath)
    expect(@project.config.latextools.type).toEqual 'yaml'

  it 'should load a YAML project file with yaml extension', ->
    fixturePath = path.join __dirname,  'fixtures',
      'project', 'yaml-project-yaml-ext'

    @project = new Project(fixturePath)
    expect(@project.config.latextools.type).toEqual 'yaml'

  it 'should make configuration properties available via get()', ->
    fixturePath = path.join __dirname,  'fixtures',
      'project', 'cson-project'

    @project = new Project(fixturePath)
    expect(@project.get('latextools.type')).toEqual 'cson'

  it 'should wrap config in latextools object', ->
    fixturePath = path.join __dirname,  'fixtures',
      'project', 'without-latextools'

    @project = new Project(fixturePath)
    expect(@project.config.latextools).toBeDefined()
    expect(@project.config.latextools.type).toEqual 'cson'

  it 'should not wrap config in latextools if latextools object defined', ->
    fixturePath = path.join __dirname,  'fixtures',
      'project', 'with-latextools'

    @project = new Project(fixturePath)
    expect(@project.config.latextools).toBeDefined()
    expect(@project.config.type).toEqual 'cson'

  describe 'adding project file', ->
    beforeEach ->
      @fixturePath = path.join __dirname,  'fixtures',
        'project', 'add-project-file'
      @copiedFile = path.join @fixturePath, '.latextools.cson'

      fs.unlinkSync(@copiedFile) if fs.existsSync(@copiedFile)

    afterEach ->
      fs.unlinkSync(@copiedFile) if fs.existsSync(@copiedFile)

    it 'should load a project file when added', (done) ->
      [loadSpy] = []

      runs ->
        @project = new Project(@fixturePath)
        @project.onDidLoad loadSpy = jasmine.createSpy('loadHandler')

        expect(@project.config).toEqual {}

        fs.writeFileSync @copiedFile,
          fs.readFileSync path.join(@fixturePath, 'data/.latextools.cson')

      waitsFor 'did-load event', -> loadSpy.callCount > 0

      runs ->
        expect(@project.config).not.toEqual {}

  describe 'removing a project file', ->
    beforeEach ->
      @fixturePath = path.join __dirname,  'fixtures',
        'project', 'remove-project-file'
      @configFile = path.join @fixturePath, '.latextools.cson'

      unless fs.existsSync(@fixturePath)
        fs.mkdirSync(@fixturePath)

      unless fs.existsSync(@configFile)
        fs.writeFileSync @configFile,
          """latextools:
          \ttype: "cson"
          """

    afterEach ->
      fs.rmdirSync @fixturePath

    it 'should remove project settings when file deleted', ->
      [unloadSpy] = []

      runs ->
        @project = new Project(@fixturePath)
        @project.onDidUnload unloadSpy = jasmine.createSpy('unloadHandler')

        expect(@project.config).not.toEqual {}

        fs.unlinkSync @configFile

      waitsFor 'did-unload event', -> unloadSpy.callCount > 0

      runs ->
        expect(@project.config).toEqual {}

  describe 'updating a project file', ->
    beforeEach ->
      @fixturePath = path.join __dirname,  'fixtures',
        'project', 'update-project-file'
      @configFile = path.join @fixturePath, '.latextools.cson'

      fs.writeFileSync @configFile,
        """latextools:
        \ttype: "cson"
        """

    it 'should update project settings when file updated', ->
      [updateSpy] = []

      runs ->
        @project = new Project(@fixturePath)
        @project.onDidUpdate updateSpy = jasmine.createSpy('updateHandler')

        expect(@project.config.latextools.type).toEqual 'cson'

        fs.writeFileSync @configFile,
          """latextools:
          \ttype: "json"
          """

      waitsFor 'did-update event', -> updateSpy.callCount > 0

      runs ->
        expect(@project.config.latextools.type).toEqual 'json'
