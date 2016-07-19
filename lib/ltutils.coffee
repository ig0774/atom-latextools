{CompositeDisposable} = require 'atom'
parse_tex_directives = require './parsers/tex-directive-parser'
fs = require 'fs'
path = require 'path'

# Base class for all tools
# Constructor only copies the console to an instance variable
# Also create instance (?) variable for viewer, so it can be called from
# any other LTool, including the builder

module.exports.LTool =

class LTool
  constructor: (@latextools) ->
    # simplify common bindings
    @ltConsole = @latextools.ltConsole
    @viewer = @latextools.viewer
    @getConfig = @latextools.getConfig.bind(@latextools)
    @getTeXRoot = @latextools.getTeXRoot.bind(@latextools)


# Utility functions

# Check if a file exists
module.exports.is_file = (fname) ->
  try
    s = fs.statSync(fname)
  catch e # statSync errors out if tex_src doesn't exist
    return false
  return s.isFile()


# Check if a folder exists
module.exports.is_dir = (dname) ->
  try
    s = fs.statSync dname
  catch e
    return false
  s.isDirectory()


# Convenience method to convert an array of args into an escaped string
module.exports.quote = (list) ->
  (for s in list
    if /["\s]/.test(s) and not /'/.test(s)
      "'#{s.replace(/(['\\])/g, '\\$1')}'"
    else if /["'\s]/.test(s)
      "\"#{s.replace(/(["'\\$`!])/g, '\\$1')}\""
    else
      String(s).replace(/([\\$`(){}!#&*|])/g, '\\$1')
  ).join ' '


# Find all matches of a regex starting from a master file
# and working our way through all included files
#
# Based on LaTeXTools' find_labels_in_files
module.exports.find_in_files = find_in_files = (rootdir, src, rx) ->

  include_rx = /\\(?:input|include)\{([^\{\}]+)\}/g

  # We need a new RegExp object for every recursion!
  # Hence, we must pass it as a string
  #rx = new RegExp(rx_string, "g")
  # Hmm... apparently not! Good!

  # Deal with the possibility of a file without an extension
  # (always the case with \include)

  tex_exts = @getConfig('latextools.texFileExtensions')
  if path.extname(src) in tex_exts
    tex_src = src
  else
    console.log("Need to find extension for #{src}")
    not_found = true
    for ext in tex_exts
      tex_src = src + ext
      if module.exports.is_file(path.join(rootdir, tex_src))
        not_found = false
        break

    if not_found
      atom.notifications.addWarning "Could not find #{src}"
      return []

    # i = 0 # old-style looping
    # while not_found && i < tex_exts.length
    #   tex_src = src + tex_exts[i] # ext contains a dot
    #   i++
    #   try
    #     s = fs.statSync(path.join(rootdir, tex_src))
    #   catch e
    #     continue
    #   not_found = false if s.isFile()
    # if not_found
    #   alert("Could not find #{src}")
    #   return null

  file_path = path.join(rootdir, tex_src) # automatically normalizes
  console.log("find_in_files: searching #{file_path}")

  try
    src_content = fs.readFileSync(file_path, 'utf-8')
  catch e
    atom.notifications.addError "Could not read #{file_path}; encoding issues?",
      detail: e.toString()
    return []

  src_content = src_content.replace(/%.*/g, "")

  # Look for matches in the current file
  results = []
  while (r = rx.exec(src_content)) != null
    #console.log("found " + r[1] + " in " + file_path)
    results.push(r[1])

  # Now look for included files and recurse into them
  while (next_file_match = include_rx.exec(src_content)) != null
    new_results = find_in_files.bind(@)(rootdir, next_file_match[1], rx)
    results = results.concat(new_results)

  return results
