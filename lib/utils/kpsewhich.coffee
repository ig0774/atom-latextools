{execFileSync} = require 'child_process'
{expand_variables} = require './expand-vars'
path = require 'path'

module.exports = (fileName, fileFormat) ->
  args = [fileName]
  args.unshift "-format=#{fileFormat}" if fileFormat?

  texpath = atom.config.get "latextools.#{process.platform}.texpath"
  env = process.env
  env.PATH = expand_variables(texpath) if texpath

  try
    "#{execFileSync 'kpsewhich', args, env: env}".trim()
  catch e
    fileName
