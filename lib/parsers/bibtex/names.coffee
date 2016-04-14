{splitTeXString} = require './tex'
{reverse} = require 'esrever'

exports.NAME_FIELDS = NAME_FIELDS = [
  'author',
  'bookauthor',
  'commentator',
  'editor',
  'editora',
  'editorb',
  'editorc',
  'foreword',
  'holder',
  'introduction',
  'shortauthor',
  'shorteditor',
  'translator',
  'sortname',
  'namea',
  'nameb',
  'namec'
]

exports.Name = Name = class Name
  constructor: (name) ->
    [@first, @middle, @prefix, @last, @generation] = \
      tokenizeName(name)

  toString: ->
    return @first unless @last

    if @prefix
      result = "#{@prefix} #{@last}"
    else
      result = @last

    if @generation
      result = "#{result}, #{@generation}"

    result = "#{result}, #{@first}"

    if @middle
      result = "#{result} #{@middle}"

    result

extractMiddleNames = (first) ->
  splitTeXString first, maxSplit: 1

extractPrefix = (last) ->
  names = splitTeXString last, maxSplit: 1
  return names if names.length is 1

  result = [names[0]]
  newNames = splitTeXString names[1], maxSplit: 1
  while newNames.length > 1 and newNames[0] is newNames[0].toLowerCase()
    result[0] = "#{result[0]} #{newNames[0]}"
    names = newNames
    newNames = splitTeXString names[1], maxSplit: 1

  result.push names[1]
  result

exports.tokenizeName = tokenizeName = (name) ->
  name = name.trim()

  # ensure this is set
  generation = ''
  parts = splitTeXString(name, sep: ',[\\s~]*')
  switch parts.length
    when 1
      # format is "first last"
      # save the last component of the string as the last name
      [last, first] =
        reverse(part) for part in splitTeXString(reverse(parts[0]), maxSplit: 1)

      # only one name
      unless first?
        return [last, '', '', '', '']

      # because of our splitting method, van, von, della, etc. may end up at
      # the end of the first name field
      firstParts = splitTeXString(first)
      if firstParts.length > 1
        lowerNameIndex = null
        for i in [0...firstParts.length]
          part = firstParts[i]
          if part is part.toLowerCase()
            if not lowerNameIndex? or lowerNameIndex is i
              lowerNameIndex = i
            else break

        if lowerNameIndex?
          last = "#{firstParts[lowerNameIndex..].join(' ')} #{last}"
          first = "#{firstParts[...lowerNameIndex].join(' ')}"

      forenames = extractMiddleNames(first)
      surnames = extractPrefix(last)

      return [
        forenames[0],
        if forenames.length > 1 then forenames[1] else '',
        if surnames.length > 1 then surnames[0] else '',
        if surnames.length > 1 then surnames[1] else surnames[0],
        ''
      ]
    when 2
      # format is "last, first"
      [last, first] = parts

      # strip TeX spaces
      first = "#{splitTeXString(first).join(' ')}"
      last = "#{splitTeXString(last).join(' ')}"

      forenames = extractMiddleNames(first)
      surnames = extractPrefix(last)

      if surnames.length > 1
        nameIndex = 0
        for part in surnames
          if part is part.toLowerCase()
            nameIndex++
          else
            break

      return [
          forenames[0],
          if forenames.length > 1 then forenames[1] else '',
          if surnames.length > 1
            surnames[...nameIndex].join(' ')
          else '',
          if surnames.length > 1
            surnames[nameIndex..].join(' ')
          else surnames[0],
          ''
      ]
    when 3
      # format is "last, generation, first"
      [last, generation, first] = parts

      forenames = extractMiddleNames(first)
      surnames = extractPrefix(last)

      return [
        forenames[0],
        if forenames.length > 1 then forenames[1] else '',
        if surnames.length > 1 then surnames[0] else '',
        if surnames.length > 1 then surnames[1] else surnames[0],
        generation
      ]
    else
      throw {
        name: "Value Error",
        message: "Unrecognized name format #{name}"
      }
