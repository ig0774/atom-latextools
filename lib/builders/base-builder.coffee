{execFile} = require 'child_process'
{quote} = require '../ltutils'

module.exports =
class BaseBuilder
  constructor: (ltConsole) ->
    @ltConsole = ltConsole

  # dir: directory of master file
  # texfile: the base name (name+ext, no directory) of the master file
  # texfilename: name only (no ext no dir) of the master file
  # user_options: any user-specified options for the tex compiler
  # user_program: user-specified tex compiler
  # env: the environment to execute the command in
  build: (dir, texfile, texfilename, user_options, user_program, env) ->
    throw
      name: "Not Implemented Error"
      message: "build() is not implemented"

  runCommand: (command, options = {}) ->
    @ltConsole.addContent "Executing #{quote(command)}"

    # 25 MB buffer
    options.maxBuffer = 26214400

    new Promise (resolve, reject) ->
      [cmd, args] = if command.length > 1
        [command[0], command[1..]]
      else
        [command[0], []]

      execFile cmd, args, options, (err, stdout, stderr) =>
        resolve(err, stdout, stderr)
