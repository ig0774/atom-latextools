{tokenizeList, splitTeXString} = require '../../../lib/parsers/bibtex/tex'

describe 'tokenizeList', ->
  it 'should split a simple list', ->
    expect(tokenizeList('Chemicals and Entrails')).toEqual \
      ['Chemicals', 'Entrails']

  it 'should split a list that uses non-breaking spaces', ->
    expect(tokenizeList('Chemicals~and~Entrails')).toEqual \
      ['Chemicals', 'Entrails']

  it 'should not split values in brackets', ->
    expect(tokenizeList('{Chemicals and Entrails}')).toEqual \
      ['{Chemicals and Entrails}']

  it 'should not split on an and in brackets', ->
    expect(tokenizeList('Chemicals {and} Entrails')).toEqual \
      ['Chemicals {and} Entrails']

  it 'should not split on an and in brackets with whitespace', ->
    expect(tokenizeList('Chemicals { and } Entrails')).toEqual \
      ['Chemicals { and } Entrails']

  it 'should not split on an and in brackets with non-breaking spaces', ->
    expect(tokenizeList('Chemicals {~and~} Entrails')).toEqual \
      ['Chemicals {~and~} Entrails']

  it 'should split a partial list', ->
    expect(tokenizeList('Chemicals and')).toEqual ['Chemicals']

describe 'splitTeXString', ->
  it 'should split a string by spaces', ->
    expect(splitTeXString('A test')).toEqual ['A', 'test']

  it 'should split a string by non-breaking spaces', ->
    expect(splitTeXString('A~test')).toEqual ['A', 'test']

  it 'should split a string with mixed spaces', ->
    expect(splitTeXString('This is~a~test')).toEqual ['This', 'is', 'a', 'test']

  it 'should split a string with many tokens', ->
    expect(splitTeXString('This is a string with several spaces')).toEqual \
      ['This', 'is', 'a', 'string', 'with', 'several', 'spaces']

  it 'should treat many spaces as a single break', ->
    expect(splitTeXString('Here    ~~~~~  we are')).toEqual \
      ['Here', 'we', 'are']
    expect(splitTeXString('Here           we are')).toEqual \
      ['Here', 'we', 'are']

  it 'should not split on strings inside brackets', ->
    expect(splitTeXString('This {is a} test')).toEqual \
      ['This', '{is a}', 'test']

  it 'should accept a custom separator to split on', ->
    expect(splitTeXString('SplitTthisTbyTts', sep: 'T')).toEqual \
      ['Split', 'this', 'by', 'ts']

  it 'should accept a parameter specifying the number of splits to make', ->
    expect(splitTeXString('This is a test', maxSplit: 1)).toEqual \
      ['This', 'is a test']
