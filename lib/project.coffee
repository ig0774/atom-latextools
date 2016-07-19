{Emitter, File, Directory, CompositeDisposable, Disposable} = require 'atom'
{getValueAtKeyPath} = require 'key-path-helpers'
fs = require 'fs'
path = require 'path'

SUPPORTED_EXTENSIONS =
  cson: (contents) ->
    CSON = require 'cson-parser'
    CSON.parse(contents)

  json: (contents) ->
    # JSON.minify adds supports for comments
    JSON.minify = require 'node-json-minify'
    JSON.parse(JSON.minify(contents))

  js: (contents) -> @json(contents)

  yml: (contents) ->
    YAML = require 'js-yaml'
    YAML.safeLoad contents

  yaml: (contents) -> @yml(contents)

FILE_MATCHER = new RegExp(
  "\\.latextools\\.(?:#{Object.keys(SUPPORTED_EXTENSIONS).join('|')})"
)

module.exports.Project =
class Project extends Disposable
  constructor: (@cwd) ->
    @emitter = new Emitter
    @config = {}

    candidates = Object.keys(SUPPORTED_EXTENSIONS).map((ext) =>
      path.join(@cwd, ".latextools.#{ext}")
    ).filter(fs.existsSync)

    if candidates? and candidates.length > 0
      @configFile = candidates[0]
      @loadConfig()
    else
      @addDirWatcher()

  get: (keyPath) ->
    getValueAtKeyPath(@config, keyPath)

  onDidLoad: (callback) ->
    @emitter.on 'did-load', callback

  onDidUnload: (callback) ->
    @emitter.on 'did-unload', callback

  onDidUpdate: (callback) ->
    @emitter.on 'did-update', callback

  dispose: ->
    @unloadConfig()
    @fileDisposable?.dispose()
    @dirDisposable?.dispose()
    @emitter.dispose()

  # -- Private API --
  addFileWatcher: ->
    return unless @configFile?

    @file = new File(@configFile)
    @fileDisposable = new CompositeDisposable
    @fileDisposable.add @file.onDidChange =>
      @updateConfig()
      @emitter.emit 'did-update', @
    @fileDisposable.add @file.onDidDelete =>
      @unloadConfig()
      @addDirWatcher()
    @fileDisposable.add @file.onDidRename =>
      if FILE_MATCHER.exec @file.getBaseName()
        @configFile = @file.getPath()
        @updateConfig()
        @emitter.emit 'did-update', @
      else
        @unloadConfig()

  addDirWatcher: ->
    return if @configFile?

    @dir = new Directory(@cwd)
    @dirDisposable = new CompositeDisposable
    @dirDisposable.add @dir.onDidChange =>
      for entry in @dir.getEntriesSync()
        continue unless entry instanceof File
        continue unless FILE_MATCHER.exec(entry.getBaseName())
        @configFile = entry.getPath()
        @loadConfig()

        @dirDisposable.dispose()
        @dir = null
        break

  loadConfig: ->
    @addFileWatcher()
    @updateConfig()
    @emitter.emit 'did-load', @

  updateConfig: ->
    return unless @configFile?
    contents = "#{fs.readFileSync @configFile}"
    try
      config = SUPPORTED_EXTENSIONS[path.extname(@configFile)[1..]](contents)
      config = {latextools: config} unless 'latextools' in Object.keys(config)
      @config = config
    catch
      @config = {}

  unloadConfig: ->
    @configFile = null
    @config = {}
    @file = null
    @fileDisposable?.dispose()
    @fileDisposable = null

    @emitter.emit 'did-unload', @
