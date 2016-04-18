BaseBuilder = require './base-builder'

module.exports =
class LatexmkBuilder extends BaseBuilder
  build: (dir, texfile, texfilename, user_options, user_program, env) ->
    @ltConsole.addContent("latexmk builder")

    user_program = 'pdf' if user_program is 'pdflatex'

    options =  ["-cd", "-e", "-f", "-#{user_program}",
      "-interaction=nonstopmode", "-synctex=1"]

    for texopt in user_options
      options.push "-latexoption=\"#{texopt}\""

    command = ["latexmk"].concat(options, "#{texfile}")

    @runCommand command,
      cwd: dir
      env: env
