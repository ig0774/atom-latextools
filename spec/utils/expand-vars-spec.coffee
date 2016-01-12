{expand_variables} = require '../../lib/utils/expand-vars'
{mockPlatform, mockEnvVar} = require '../spec-helpers'

describe 'expand_variables', ->
  it 'should expand Unix-style variables', ->
    str = '$PATH'
    expectedPath = process.env.PATH
    expect(expand_variables(str)).toBe expectedPath

  it 'should expand Unix-style variables wrapped in brackets', ->
    str = '${PATH}'
    expectedPath = process.env.PATH
    expect(expand_variables(str)).toBe expectedPath

  it 'should expand Unix-style variables when embedded in string', ->
    str = '/foo:$PATH:/bar'
    expectedPath = str.replace('$PATH', process.env.PATH)
    expect(expand_variables(str)).toBe expectedPath

  it 'should do nothing if string contains no variables', ->
    str = '/foo:/bar'
    expect(expand_variables(str)).toBe str,

  it 'should replace multiple tokens', ->
    str = '$PATH:/foo/:$PATH:/bar'
    expectedPath = str.replace(/\$PATH/g, process.env.PATH)
    expect(expand_variables(str)).toBe expectedPath

  describe 'Windows-specific behavior', ->
    mockPlatform('win32')

    it 'should expand Windows-style variables on Windows', ->
      str = '%PATH%'
      expectedPath = process.env.PATH
      expect(expand_variables(str)).toBe expectedPath

    it 'should expand Windows-style variables when embedded in string', ->
      str = '/foo;%PATH%;/bar'
      expectedPath = str.replace('%PATH%', process.env.PATH)
      expect(expand_variables(str)).toBe expectedPath

    it 'should replace multiple Windows-style variables', ->
      str = '%PATH%:/foo/:%PATH%:/bar'
      expectedPath = str.replace(/%PATH%/g, process.env.PATH)
      expect(expand_variables(str)).toBe expectedPath

    it 'should not be case-sensitive on Windows', ->
      str = '/foo:$PaTh:/bar'
      expectedPath = str.replace(/\$PATH/gi, process.env.PATH)
      expect(expand_variables(str)).toBe expectedPath

    it 'should not be case-sensitive with Windows-style variables', ->
      str = '/foo;%PaTh%;/bar'
      expectedPath = str.replace(/%PATH%/gi, process.env.PATH)
      expect(expand_variables(str)).toBe expectedPath
