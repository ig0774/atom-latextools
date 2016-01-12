module.exports =
  mockPlatform: (platform) ->
    beforeEach ->
      @originalPlatform = process.platform
      Object.defineProperty process, 'platform', value: platform

    afterEach ->
      Object.defineProperty process, 'platform', value: @originalPlatform

  mockEnvVar: (variable, value) ->
    beforeEach ->
      @originalValue = process.env[variable]
      Object.defineProperty process.env, variable, value: value

    afterEach ->
      Object.defineProperty process.env, variable, value: @originalValue
