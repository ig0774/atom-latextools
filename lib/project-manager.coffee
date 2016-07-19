{Emitter, Disposable, CompositeDisposable} = require 'atom'
{Project} = require './project'

module.exports.ProjectManager =
class ProjectManager extends Disposable
  constructor: ->
    @disposables = new CompositeDisposable
    @disposables.add @emitter = new Emitter
    @disposables.add atom.config.onDidChange 'latextools.useProjectFiles',
      ({newValue}) =>
        if newValue is true
          @loadProjects()
        else
          @dispose()

    @loadProjects() if atom.config.get('latextools.useProjectFiles')


  dispose: ->
    @disposables.dispose()
    @projectFiles = undefined

  getProject: (path) ->
    unless path?
      if @projectFiles?
        keys = Object.keys(@projectFiles)
        if keys.length is 1
          return @projectFiles[keys[0]]
        else if @projectFiles?
          atom.notifications.addWarning(
            'Cannot determine project for unsaved buffer as more than one ' +
            'project is currently opened.'
          )
      return undefined

    projects = Object.keys(@projectFiles).filter (p) ->
      if p?
        path.startsWith(p)
      else
        false

    switch
      when not projects
        undefined
      when projects.length is 1
        @projectFiles[projects[0]]
      else
        # take the longest matching project path which should be the most
        # local to the project, e.g. comparing /path/to/main to
        # /path/to/subfolder whereas /path/to/subfolder/subsubfolder will've
        # alreadyg been filtered out
        @projectFiles[projects.reduce ((p, c) ->
          if c.length > p.length
            c
          else
            p
        ), '']

  onDidAddProject: (callback) ->
    @emitter.on 'did-add', callback

  # note that this *only* emits the project path
  onDidRemoveProject: (callback) ->
    @emitter.on 'did-remove', callback

  # -- Private API --
  loadProjects: ->
    @projectFiles = {}
    for path in atom.project.getPaths()
      @disposables.add @projectFiles[path] = new Project(path)
      @emitter.emit 'did-add', @projectFiles[path]

    @disposables.add atom.project.onDidChangePaths (newPaths) =>
      projectPaths = Object.keys(@projectFiles)
      addedPaths = newPaths.filter (it) ->
        projectPaths.indexOf(it) is -1
      removedPaths = @projectPaths.filter (it) ->
        newPaths.indexOf(it) is -1

      for path in removedPaths
        removed = @projectFiles[path]
        @disposables.remove removed
        removed.dispose()
        @projectFiles[path] = undefined
        @emitter.emit 'did-remove', path

      for path in addedPaths
        @disposables.add @projectFiles[path] = new Project(path)
        @emitter.emit 'did-add', @projectFiles[path]
