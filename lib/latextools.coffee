LTConsole = null
Builder = null
BuilderRegistry = null
Viewer = null
ViewerRegistry = null
CompletionManager = null
SnippetManager = null
ProjectManager = null
deleteTempFiles = null
{Disposable, CompositeDisposable} = require 'atom'
path = require 'path'

module.exports = Latextools =
  ltConsole: null
  builder: null
  subscriptions: null
  snippets: null

  config:
    useProjectFiles:
      type: 'boolean'
      default: true
      description: 'Whether to use project files or ignore them completely.'
      order: 0.5
    citeAutoTrigger:
      type: 'boolean'
      default: true
      order: 1
    refAutoTrigger:
      type: 'boolean'
      default: true
      order: 2
    refAddParenthesis:
      type: 'boolean'
      default: false
      order: 3
    # fillAutoTrigger:
    #   type: 'boolean'
    #   default: true
    #   order: 4
    keepFocus:
      type: 'boolean'
      default: true
      order: 5
    forwardSync:
      type: 'boolean'
      default: true
      order: 6
    viewer:
      type: 'string'
      default: 'default'
      order: 6.5

    commandCompletion:
      type: 'string'
      default: 'prefixed'
      enum: ['always', 'prefixed', 'never']
      order: 7

    cwlList:
      type: 'array'
      default: [
        "tex",
        "latex-209",
        "latex-document",
        "latex-l2tabu",
        "latex-mathsymbols"
      ]
      items:
        type: 'string'
      order: 8

    # hideBuildPanel:
    #   type: 'string'
    #   default: 'never'
    #   enum: ['always', 'no_errors', 'no_warnings', 'never']
    #   order: 8

    texFileExtensions:
      type: 'array'
      default: ['.tex']
      items:
        type: 'string'
      order: 9

    # latextoolsSetSyntax:
    #   type: 'boolean'
    #   default: true
    #   order: 10

    temporaryFileExtensions:
      type: 'array'
      default: [
        ".blg",".bbl",".aux",".log",".brf",".nlo",".out",".dvi",".ps",
        ".lof",".toc",".fls",".fdb_latexmk",".pdfsync",".synctex.gz",
        ".ind",".ilg",".idx"
      ]
      items:
        type: 'string'
      order: 11
    temporaryFilesIgnoredFolders:
      type: 'array'
      default: [".git", ".svn", ".hg"]
      items:
        type: 'string'
      order: 12

    darwin:
      type: 'object'
      properties:
        texpath:
          type: 'string'
          default: "/Library/TeX/texbin:/usr/texbin:/usr/local/bin:/opt/local/bin:$PATH"
      order: 13

    win32:
      type: 'object'
      properties:
        texpath:
          type: 'string'
          default: ""
        distro:
          type: 'string'
          default: "miktex"
          enum: ["miktex", "texlive"]
        sumatra:
          type: 'string'
          default: "SumatraPDF.exe"
        atomExecutable:
          type: 'string'
          default: ""
        # keepFocusDelay:
        #   type: 'number'
        #   default: 0.5
      order:14

    linux:
      type: 'object'
      properties:
        texpath:
          type: 'string'
          default: "$PATH:/usr/texbin"
        python:
          type: 'string'
          description: "Path to a Python interpreter that includes the DBus library"
          default: ""
        atomExecutable:
          type: 'string'
          description: "Path to Atom"
          default: ""
        syncWait:
          type: 'number'
          description: "Time to wait between launching Evince and syncing"
          default: 1.0
        # keepFocusDelay:
        #   type: 'number'
        #   default: 0.5
      order: 15

    builder:
      type: 'string'
      default: "texify-latexmk"
      order: 16

    # builderPath:
    #   type: 'string'
    #   default: ""
    #   order: 17

    builderSettings:
      type: 'object'
      properties:
        program:
          type: 'string'
          default: "pdflatex"
          enum: ["pdflatex", "xelatex", "lualatex"]
        options:
          type: 'array'
          default: []
          items:
            type: 'string'
        # command:
        #   description: "The exact command to run. <strong>Leave this blank</strong> unless you know what you are doing!"
        #   type: 'array'
        #   default: []
        #   items:
        #     type: 'string'
      order: 18


# Still need image opening defaults
# Also, rethink below

    citePanelFormat:
      type: 'array'
      default: ["{author_short} {year} - {title_short} ({keyword})","{title}"]
      order: 19
    citeAutocompleteFormat:
      type: 'string'
      default: "{keyword}: {title}"
      order: 20


  activate: (@state) ->
    @ltConsole = null
    @viewer = null
    @builder = null
    @completionManager = null
    @snippetManager = null
    @builderRegistry = null
    @projectManager = null
    @viewerRegistry = null
    @cwlProvider = null

    # ensure initial viewer drop-down is populated
    currentViewer = atom.config.get 'latextools.viewer'
    viewerList = ['pdf-view']
    viewerList.push currentViewer if currentViewer isnt 'pdf-view' and
      currentViewer isnt 'default'
    viewerList = viewerList.sort()
    viewerList.unshift 'default'
    atom.config.schema.properties.latextools.properties.viewer.enum =
      viewerList

    # ensure initial viewer drop-down is populated
    currentViewer = atom.config.get 'latextools.viewer'
    viewerList = ['pdf-view']
    switch process.platform
      when 'darwin'
        viewerList.push 'skim'
      when 'win32'
        viewerList.push 'sumatra'
      else
        viewerList.push 'evince'
        viewerList.push 'okular'
    viewerList.push currentViewer if currentViewer isnt 'default' and
      currentViewer not in viewerList
    viewerList = viewerList.sort()
    viewerList.unshift 'default'
    atom.config.getSchema('latextools.viewer').enum = viewerList

    # ensure initial viewer drop-down is populated
    currentViewer = atom.config.get 'latextools.viewer'
    viewerList = ['pdf-view']
    switch process.platform
      when 'darwin'
        viewerList.push 'skim'
      when 'win32'
        viewerList.push 'sumatra'
      else
        viewerList.push 'evince'
        viewerList.push 'okular'
    viewerList.push currentViewer if currentViewer isnt 'default' and
      currentViewer not in viewerList
    viewerList = viewerList.sort()
    viewerList.unshift 'default'
    atom.config.getSchema('latextools.viewer').enum = viewerList

    # ensure initial viewer drop-down is populated
    currentViewer = atom.config.get 'latextools.viewer'
    viewerList = ['pdf-view']
    switch process.platform
      when 'darwin'
        viewerList.push 'skim'
      when 'win32'
        viewerList.push 'sumatra'
      else
        viewerList.push 'evince'
        viewerList.push 'okular'
    viewerList.push currentViewer if currentViewer isnt 'default' and
      currentViewer not in viewerList
    viewerList = viewerList.sort()
    viewerList.unshift 'default'
    atom.config.getSchema('latextools.viewer').enum = viewerList

    # ensure initial viewer drop-down is populated
    currentViewer = atom.config.get 'latextools.viewer'
    viewerList = ['pdf-view']
    switch process.platform
      when 'darwin'
        viewerList.push 'skim'
      when 'win32'
        viewerList.push 'sumatra'
      else
        viewerList.push 'evince'
        viewerList.push 'okular'
    viewerList.push currentViewer if currentViewer isnt 'default' and
      currentViewer not in viewerList
    viewerList = viewerList.sort()
    viewerList.unshift 'default'
    atom.config.getSchema('latextools.viewer').enum = viewerList

    # ensure initial viewer drop-down is populated
    currentViewer = atom.config.get 'latextools.viewer'
    viewerList = ['pdf-view']
    switch process.platform
      when 'darwin'
        viewerList.push 'skim'
      when 'win32'
        viewerList.push 'sumatra'
      else
        viewerList.push 'evince'
        viewerList.push 'okular'
    viewerList.push currentViewer if currentViewer isnt 'default' and
      currentViewer not in viewerList
    viewerList = viewerList.sort()
    viewerList.unshift 'default'
    atom.config.getSchema('latextools.viewer').enum = viewerList

    # function to register a viewer with latextools
    @addViewer = (names, cls) =>
      @requireIfNeeded ['viewer']
      @viewerRegistry.add names, cls
      @viewerRegistry.updateConfigSchema()

    # function to register a builder with latextools
    @addBuilder = (names, cls) =>
      @requireIfNeeded ['builder']
      @builderRegistry.add names, cls

    # Events subscribed to in atom's system can be easily cleaned up with a CompositeDisposable
    @subscriptions = new CompositeDisposable

    # Register command that toggles this view; DEBUG ONLY
    @subscriptions.add atom.commands.add 'atom-workspace', 'latextools:toggle-log': =>
      @ltConsole.toggle()
    @subscriptions.add atom.commands.add 'atom-workspace', 'latextools:add-log': =>
      @ltConsole.addLog()
    @subscriptions.add atom.commands.add 'atom-workspace', 'latextools:clear-log': =>
      @ltConsole.clear()

    # Actual commands
    @subscriptions.add atom.commands.add 'atom-workspace', 'latextools:hide-ltconsole': =>
      @ltConsole.hide()
    @subscriptions.add atom.commands.add 'atom-workspace', 'latextools:show-ltconsole': =>
      @ltConsole.show()
    @subscriptions.add atom.commands.add 'atom-text-editor', 'latextools:build': =>
      @requireIfNeeded ['viewer', 'builder']
      # drop to JS to call this.getModel() which is the TextEditor the command
      # is run on
      te = `this.getModel()`
      @builder.build(te)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'latextools:jump-to-pdf': =>
      @requireIfNeeded ['viewer']
      # drop to JS to call this.getModel() which is the TextEditor the command
      # is run on
      te = `this.getModel()`
      @viewer.jumpToPdf(te)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'latextools:ref-cite-complete': =>
      @requireIfNeeded ['completion-manager', 'snippet-manager']
      # drop to JS to call this.getModel() which is the TextEditor the command
      # is run on
      te = `this.getModel()`
      @completionManager.refCiteComplete(te, keybinding=true)
    @subscriptions.add atom.commands.add 'atom-text-editor', 'latextools:ref-cite-keypress': (e) =>
      e.abortKeyBinding()
      @requireIfNeeded ['completion-manager', 'snippet-manager']
      # drop to JS to call this.getModel() which is the TextEditor the command
      # is run on
      te = `this.getModel()`
      setTimeout (=>
        @completionManager.refCiteComplete(te)
      ), 50
    @subscriptions.add atom.commands.add 'atom-text-editor', 'latextools:delete-temp-files': =>
      deleteTempFiles ?= require './commands/delete-temp-files'
      # drop to JS to call this.getModel() which is the TextEditor the command
      # is run on
      te = `this.getModel()`
      deleteTempFiles.bind(@)(te)

    # Snippet insertion

    @subscriptions.add atom.commands.add 'atom-text-editor', 'latextools:wrap-in-command': =>
      @requireIfNeeded ['snippet-manager']
      @snippetManager.wrapInCommand()
    @subscriptions.add atom.commands.add 'atom-text-editor', 'latextools:wrap-in-environment': =>
      @requireIfNeeded ['snippet-manager']
      @snippetManager.wrapInEnvironment()
    @subscriptions.add atom.commands.add 'atom-text-editor', 'latextools:insert-command': =>
      @requireIfNeeded ['snippet-manager']
      @snippetManager.insertCmdEnv("command")
    @subscriptions.add atom.commands.add 'atom-text-editor', 'latextools:insert-environment': =>
      @requireIfNeeded ['snippet-manager']
      @snippetManager.insertCmdEnv("environment")
    @subscriptions.add atom.commands.add 'atom-text-editor', 'latextools:wrap-in-emph': =>
      @requireIfNeeded ['snippet-manager']
      @snippetManager.wrapIn("emph")
    @subscriptions.add atom.commands.add 'atom-text-editor', 'latextools:wrap-in-bold': =>
      @requireIfNeeded ['snippet-manager']
      @snippetManager.wrapIn("textbf")
    @subscriptions.add atom.commands.add 'atom-text-editor', 'latextools:wrap-in-underline': =>
      @requireIfNeeded ['snippet-manager']
      @snippetManager.wrapIn("underline")
    @subscriptions.add atom.commands.add 'atom-text-editor', 'latextools:wrap-in-monospace': =>
      @requireIfNeeded ['snippet-manager']
      @snippetManager.wrapIn("texttt")
    @subscriptions.add atom.commands.add 'atom-text-editor', 'latextools:close-environment': =>
      @requireIfNeeded ['snippet-manager']
      @snippetManager.closeEnvironment()
    @subscriptions.add atom.commands.add 'atom-text-editor', 'latextools:dollar-sign': =>
      @requireIfNeeded ['snippet-manager']
      @snippetManager.dollarSign()
    @subscriptions.add atom.commands.add 'atom-text-editor', 'latextools:backquote': =>
      @requireIfNeeded ['snippet-manager']
      @snippetManager.quotes('`', '\'', '`')
    @subscriptions.add atom.commands.add 'atom-text-editor', 'latextools:quote': =>
      @requireIfNeeded ['snippet-manager']
      @snippetManager.quotes('`', '\'', '\'')
    @subscriptions.add atom.commands.add 'atom-text-editor', 'latextools:double-quote': =>
      @requireIfNeeded ['snippet-manager']
      @snippetManager.quotes('``', '\'\'', '"')

  getProvider: ->
    # if using cwl-completion, load autocomplete provider
    if atom.config.get("latextools.commandCompletion") != 'never'
      @cwlProvider = require './ltcwl-completion'
      @cwlProvider.loadCompletions()
      @cwlProvider

  deactivate: ->
    @subscriptions.dispose()
    @ltConsole.destroy()

  serialize: ->
    ltConsoleState: @ltConsole.serialize()

  consumeSnippets: (snippets) ->
    @requireIfNeeded ['snippet-manager']
    @snippetManager.setService(snippets)
    new Disposable -> @snippets = null

  getConfig: (keyPath, te) ->
    te = atom.workspace.getActiveTextEditor() unless te?

    if te? and atom.config.get('latextools.useProjectFiles')
      @requireIfNeeded ['project']

      project = @projectManager.getProject(te.getPath())
      result = project?.get keyPath
      return result if result?

    return atom.config.get keyPath

  # Find tex root by checking %!TEX line
  # TODO add support for configurable extensions
  # In: current tex file; Out: tex root
  getTeXRoot: (editor) ->
    if typeof(editor) is 'string'
      root = editor
    else
      root = editor.getPath()

    console.log root

    parse_tex_directives = require './parsers/tex-directive-parser'
    directives = parse_tex_directives editor, onlyFor: ['root']
    if directives.root?
      return path.resolve(path.dirname(root), directives.root)

    if atom.config.get('latextools.useProjectFiles')
      @requireIfNeeded ['project']
      project = @projectManager?.getProject(root)
      console.log project
      if project?
        setting = project.get 'TEXroot'
        setting = project.get 'latextools.TEXroot' unless setting?
        return path.resolve(project.cwd, setting) if setting?

    return root

  # Private: ensure modules are loaded on demand
  requireIfNeeded: (modules) ->
    # ltConsole is needed by all, so load it
    LTConsole ?= require './ltconsole'
    @ltConsole ?= new LTConsole @state.ltConsoleState

    for m in modules
      console.log("requiring if needed: #{m}")
      switch m
        when "viewer"
          ViewerRegistry ?= require './viewer-registry'
          Viewer ?= require './viewer'

          unless @viewerRegistry?
            @viewerRegistry = new ViewerRegistry

            @viewerRegistry.add 'pdf-view',
              require './viewers/atom-pdf-viewer'

            switch process.platform
              when 'darwin'
                @viewerRegistry.add ['default', 'skim'],
                  require './viewers/skim-viewer'
              when 'win32'
                @viewerRegistry.add ['default', 'sumatra'],
                  require './viewers/sumatra-viewer'
              else
                @viewerRegistry.add ['default', 'okular'],
                  require './viewers/okular-viewer'
                @viewerRegistry.add 'evince',
                  require './viewers/evince-viewer'

            @viewerRegistry.updateConfigSchema()

          @viewer ?= new Viewer @viewerRegistry, @
        when "builder"
          BuilderRegistry ?= require './builder-registry'
          unless @builderRegistry?
            @builderRegistry = new BuilderRegistry
            @builderRegistry.add 'latexmk',
              require './builders/latexmk-builder'
            if process.platform is 'win32'
              @builderRegistry.add 'texify',
                require './builders/texify-builder'

          Builder ?= require './builder'
          unless @builder?
            @builder = new Builder @builderRegistry, @

            # ensure viewer is loaded before builder
            @requireIfNeeded ['viewer'] unless @viewer?
            @builder.viewer = @viewer
        when "completion-manager"
          CompletionManager ?= require('./completion-manager').CompletionManager
          @completionManager ?= new CompletionManager @
        when "snippet-manager"
          SnippetManager ?= require './snippet-manager'
          @snippetManager ?= new SnippetManager @
        when "project"
          ProjectManager ?= require('./project-manager').ProjectManager
          @projectManager ?= new ProjectManager
