BaseViewer = require './base-viewer'
{execFileSync} = require 'child_process'

module.exports =
class OkularViewer extends BaseViewer
  _getArgs = (opts = {}) ->
    args = ["--unique"]
    args.push "--noraise" if opts?.keepFocus
    args

  okularIsRunning: (pdfFile) ->
    new Promise (resolve, reject) ->
      execFile 'ps', ['xw'], (err, stdout, stderr) ->
        if (err isnt 0 or
            stdout.indexOf("okular") < 0 or
            stdout.indexOf("--unique") <0)
          reject()
        else
          resolve()

  ensureOkular: (opts = {}) ->
    @okularIsRunning().catch ->
      execFileSync 'okular', ['--unique']

  forwardSync: (pdfFile, texFile, line, col, opts = {}) ->
    @ensureOkular(opts).then ->
      doAfterPause ->
        args = _getArgs opts
        args.push "#{pdfFile}#src:#{line}#{texFile}"
        args.unshift 'okular'
        @runViewer args

  viewFile: (pdfFile, opts = {}) ->
    @ensureOkular(opts).then ->
      doAfterPause ->
        args = _getArgs opts
        args.push "#{pdfFile}"
        args.unshift 'okular'
        @runViewer args
