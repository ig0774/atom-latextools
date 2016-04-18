BaseBuilder = require './base-builder'

module.exports =
class TexifyBuilder extends BaseBuilder
  build: (dir, texfile, texfilename, user_options, user_program, env) ->
    @ltConsole.addContent("texify builder")

    options = ["-b", "-p"]

    user_program = switch user_program
      when 'pdflatex' then 'pdftex'
      when 'xelatex' then 'xetex'
      when 'lualatex' then 'luatex'
      else user_program

    options.push "--engine=#{user_program}"

    tex_options = ["--synctex=1"].concat user_options
    tex_options_string = "--tex-option=\"#{tex_options.join(' ')}\""
    options = options.concat [tex_options_string]

    command = ["texify"].concat(options, "\"#{texfile}\"")

    @runCommand command,
      cwd: dir
      env: env
