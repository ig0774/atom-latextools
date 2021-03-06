{LTool} = require './ltutils'
{exec} = require 'child_process'
path = require 'path'
fs = require 'fs'
{parse_tex_log} = require './parsers/parse-tex-log'
parse_tex_directives = require './parsers/tex-directive-parser'
{expand_variables} = require './utils/expand-vars'

module.exports =

class Builder extends LTool

  constructor: (@builderRegistry, ltConsole) ->
    super(ltConsole)

  build: (te) ->
    return unless te?

    # save on build
    # if unsaved, run saveAs
    unless te.getPath()?
      atom.workspace.paneForItem(te)?.saveItem(te)

    unless te.getPath()?
      atom.notifications.addError(
        'Please save your file before attempting to build'
      )
      return

    if te.isModified()
      te.save()

    fname = @getTeXRoot(te)

    parsed_fname = path.parse(fname)

    filedir = parsed_fname.dir
    filebase = parsed_fname.base  # base includes the extension but not the dir
    filename = parsed_fname.name  # name only includes the name (no dir, no ext)

    # Get options and programs
    directives = parse_tex_directives fname,
      multiValues: ['option'],
      keyMaps: {'ts-program': 'program'}

    user_options = @getConfig("latextools.builderSettings.options", te)
    user_options = user_options.concat directives.option

    # Special case: no default options, no user options give [undefined]
    if user_options.length==1 && user_options[0] == undefined
      user_options = []

    # white-list the selectable programs
    # on Windows / miktex, allow both pdftex, etc and pdflatex
    whitelist = ["pdflatex", "xelatex", "lualatex"]
    if process.platform == 'win32'
      whitelist = whitelist.concat ["pdftex", "xetex", "luatex"]
    if directives.program in whitelist
      user_program = directives.program
    else
      user_program = @getConfig("latextools.builderSettings.program", te)

    # prepare the build console
    @ltConsole.show()
    @ltConsole.clear()

    # Now prepare path
    # TODO: also env if needed

    texpath = atom.config.get("latextools." + process.platform + ".texpath")
    @ltConsole.addContent("Platform: #{process.platform}; texpath: #{texpath}")
    # shallow-copy
    cmd_env = Object.create process.env
    if texpath
      cmd_env.PATH = expand_variables(texpath)
      @ltConsole.addContent("setting PATH = #{cmd_env.PATH}")

    @ltConsole.addContent("Processing file #{filebase} (#{filename}) in directory #{filedir}")

    builderName = atom.config.get("latextools.builder")

    _builderName =
      if builderName is "texify-latexmk"
        if process.platform isnt 'win32' or \
            @getConfig('latextools.win32.distro').toLowerCase() is 'texlive'
          'latexmk'
        else
          'texify'
      else
        builderName

    builderClass = @builderRegistry.get _builderName

    @ltConsole.addContent("Using builder #{builderName}")

    unless builderClass?
      atom.notifications.addError(
        "Could not find builder #{_builderName}. Please check your config."
      )
      return if builderName is 'texify-latexmk'
      builderClass = @builderRegistry.get(
        if process.platform is 'win32' and \
            atom.config.get('latextools.win32.distro') is 'miktex'
          'texify'
        else
          'latexmk'
      )
      return unless builderClass?

    builder = new builderClass(@ltConsole)

    Promise.resolve(builder.build(
      filedir, filebase, filename, user_options, user_program, cmd_env
    )).then =>
      # If there were errors, print them and return
      # if err
      #   @ltConsole.addContent("BUILD ERROR!", br=true)
      #   @ltConsole.addContent(line, br=true) for line in stdout.split('\n')
      #   @ltConsole.addContent(line, br=true) for line in stderr.split('\n')
      # return
      # Parse error log
      fulllogfile = path.join(filedir, filename + ".log") # takes care of quotes
      @ltConsole.addContent("Parsing #{fulllogfile}")
      try
        log = fs.readFileSync(fulllogfile, 'utf8')
      catch error
        @ltConsole.addContent("Could not read log file!")
        atom.notifications.addError(
          "Could not read log file #{fulllogfile}",
          detail: error
        )
        return


      # We need to cd to the root file directory for the
      # file-matching logic to work with texlive (miktex reports full paths)
      # NOTE: we could also do this earlier and avoid setting cwd in the
      # exec call
      process.chdir(filedir)
      [errors, warnings] = parse_tex_log(log)

      @ltConsole.addContent("ERRORS:")
      for err in errors
        do (err) =>
          if err[1] == -1
            err_string = "#{err[0]}: #{err[2]} [#{err[3]}]"
            @ltConsole.addContent err_string, level: 'error'
          else
            err_string = "#{err[0]}:#{err[1]}: #{err[2]} [#{err[3]}]"
            file = switch
              when not err[0]? or err[0] is '[no file]' then null
              when path.isAbsolute(err[0]) then err[0]
              else path.join(filedir, err[0])

            @ltConsole.addContent err_string,
              file: file
              line: err[1]
              level: 'error'

      @ltConsole.addContent("WARNINGS:")
      for warn in warnings
        do (warn) =>
          if warn[1] == -1
            warn_string = "#{warn[0]}: #{warn[2]}"
            @ltConsole.addContent warn_string, level: 'warning'
          else
            warn_string = "#{warn[0]}:#{warn[1]}: #{warn[2]}"
            file = switch
              when not warn[0]? or warn[0] is '[no file]' then null
              when path.isAbsolute(warn[0]) then warn[0]
              else path.join(filedir, warn[0])

            @ltConsole.addContent warn_string,
              file: file
              line: warn[1]
              level: 'warning'

      unless errors.length > 0
        atom.notifications.addSuccess(
          "Build completed with 0 errors and #{warnings.length} warnings"
        )
      else
        atom.notifications.addError(
          "Build completed with #{errors.length} errors and #{warnings.length} warnings"
        )

      # Jump to PDF
      @ltConsole.addContent("Jumping to PDF...")
      @viewer.jumpToPdf(te)
