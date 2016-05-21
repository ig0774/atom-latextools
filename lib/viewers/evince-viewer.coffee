BaseViewer = require './base-viewer'
{execFile, execFileSync} = require 'child_process'
path = require 'path'
{quote} = require '../ltutils'

module.exports =
class EvinceViewer extends BaseViewer
  getAtomExecutable: ->
    unless @_atom?
      @_atom = atom.config.get("latextools.#{process.platform}.atomExecutable")
      @_atom = 'atom' if @_atom? or @_atom is ''
    Promise.resolve(@_atom)

  checkPythons: (pythons) ->
    new Promise (resolve, reject) ->
      done = false
      for python in pythons
        unless done
          console.log "Running #{quote([python, '-c', 'import dbus'])}"
          try
            execFileSync python, ['-c', 'import dbus']
            resolve(python)
            done = true
          catch
      reject()

  getPython: ->
    if @_python? and @_python isnt ''
      Promise.resolve(@_python)
    else
      python = atom.config.get("latextools.#{process.platform}.python")
      if python? and python isnt ''
        @_python = python
        Promise.resolve(python)
      else
        @checkPythons(['python', 'python3', 'python2']).then(
          (python) => @_python = python,
          ->
            atom.notifications.addError(
              '''Cannot find a valid Python interpreter.
              Please ensure your `python` setting is correct in your Latextools settings.
              '''
            )

            # try to exit out if we can't find python
            throw
              name: "Python not found error"
              description: "A valid Python interpreter could not be found"
        )

  evinceIsRunning: (pdfFile) ->
    new Promise (resolve, reject) ->
      execFile 'ps', ['xw'], (err, stdout, stderr) ->
        if err isnt 0 or stdout.indexOf("evince #{pdfFile}") < 0
          reject()
        else
          resolve()

  launchEvince: (pdfFile) ->
    Promise.all([@getPython(), @getAtomExecutable()]).then ([python, atom]) =>
      cwd = path.join(
        window.atom.packages.resolvePackagePath('latextools'),
        'lib',
        'support'
      )

      command = ['/bin/sh', 'evince_sync', python, atom, pdfFile]
      @ltConsole.addContent "Executing #{quote(command)}"
      execFile command[0], command[1..], cwd: cwd

  forwardSync: (pdfFile, texFile, line, col, opts = {}) ->
    @viewFile(pdfFile, opts).then =>
      @getPython().then (python) =>
        @doAfterPause ->
          execFile python, [
            path.join(
              window.atom.packages.resolvePackagePath('latextools'),
              'lib', 'support', 'evince_forward_search'
            ),
            pdfFile, "#{line}", texFile
          ]

  viewFile: (pdfFile, opts = {}) ->
    keepFocus = opts?.keepFocus

    @evinceIsRunning(pdfFile).then(
      => execFile('evince', [pdfFile]) if not keepFocus,
      => @launchEvince(pdfFile)
    )
