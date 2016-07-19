{ProjectManager} = require '../lib/project-manager'

describe 'ProjectManager', ->
  describe 'toggle activation', ->
    beforeEach ->
      @projectManager = new ProjectManager

    afterEach ->
      @projectManager?.dispose()

    it 'should load projects if setting set to true', ->
      spyOn(@projectManager, 'loadProjects')

      runs ->
        atom.config.set 'latextools.useProjectFiles', true

      waitsFor 'did-load event', => @projectManager.loadProjects.callCount > 0

      runs ->
        expect(@projectManager.loadProjects).toHaveBeenCalled()

    it 'should unload projects if setting is set to false', ->
      spyOn(@projectManager, 'dispose').andCallThrough()

      runs ->
        atom.config.set 'latextools.useProjectFiles', false

      waitsFor 'did-load event', => @projectManager.dispose.callCount > 0

      runs ->
        expect(@projectManager.dispose).toHaveBeenCalled()

  describe 'initial state', ->
    it 'should call loadProjects if useProjectFiles is true', ->
      atom.config.set 'latextools.useProjectFiles', true
      spyOn(ProjectManager::, 'loadProjects')
      @projectManager = new ProjectManager
      expect(ProjectManager::loadProjects).toHaveBeenCalled()

    it 'should not call laodProjects if useProjectFiles is false', ->
      atom.config.set 'latextools.useProjectFiles', false
      spyOn(ProjectManager::, 'loadProjects')
      @projectManager = new ProjectManager
      expect(ProjectManager::loadProjects).not.toHaveBeenCalled()

  describe 'getProject', ->
    beforeEach ->
      @projectManager = new ProjectManager

    afterEach ->
      @projectManager?.dispose()

    describe 'no path provided', ->
      it 'should return undefined if no project files exist', ->
        expect(@projectManager.getProject()).toBeUndefined()

      it 'should return project if a single project exists', ->
        project = {}
        @projectManager.projectFiles =
          '/tmp': project

        expect(@projectManager.getProject()).toBe project
