module.exports =
  expand_variables: (str) ->
    return str if typeof(str) is not "string"

    # on Windows, environment variables are not case-sensitive
    # on POSIX, they are
    flags = if process.platform is 'win32'
      'gi'
    else
      'g'

    for key of process.env
      str = str.replace(
        new RegExp("\\$\\{?#{key}\\}?", flags)
        process.env[key]
      )

      if process.platform is 'win32'
        str = str.replace(
          new RegExp("%#{key}%", flags)
          process.env[key]
        )

    return str
