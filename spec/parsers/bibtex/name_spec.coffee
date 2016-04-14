{Name, tokenizeName} = require '../../../lib/parsers/bibtex/names'

describe 'tokenizeName', ->
  it 'should tokenize a simple name', ->
    expect(tokenizeName('Coddlington, Simon')).toEqual \
      ['Simon', '', '', 'Coddlington', '']

  it 'should tokenize a simple name with a non-breaking space', ->
    expect(tokenizeName('Coddlington,~Simon')).toEqual \
      ['Simon', '', '', 'Coddlington', '']

  it 'should tokenize a simple name in "first last" format', ->
    expect(tokenizeName('Simon Coddlington')).toEqual \
      ['Simon', '', '', 'Coddlington', '']

  it 'should tokenize a simple name in "first last" format with a non-breaking space', ->
    expect(tokenizeName('Simon~Coddlington')).toEqual \
      ['Simon', '', '', 'Coddlington', '']

  it 'should tokenize a name with a middle name', ->
    expect(tokenizeName('Coddlington, Simon P.')).toEqual \
      ['Simon', 'P.', '', 'Coddlington', '']

  it 'should tokenize a name with a middle name using non-breaking spaces', ->
    expect(tokenizeName('Coddlington,~Simon~P.')).toEqual \
      ['Simon', 'P.', '', 'Coddlington', '']

  it 'should tokenize a name in "first last" format with a middle name', ->
    expect(tokenizeName('Simon P. Coddlington')).toEqual \
      ['Simon', 'P.', '', 'Coddlington', '']

  it 'should tokenize a name with multiple middle names', ->
    expect(tokenizeName('Quine, Willard van Orman')).toEqual \
      ['Willard', 'van Orman', '', 'Quine', '']

  it 'should tokenize a name with multiple last names in "first last" format', ->
    # NOTE the ambiguity of "first last" means this resolves differently than
    # "last, first"!!
    expect(tokenizeName('Willard van Orman Quine')).toEqual \
      ['Willard', '', 'van', 'Orman Quine', '']

  it 'should tokenize a name consisting of a single name', ->
    expect(tokenizeName('Augustine')).toEqual ['Augustine', '', '', '', '']

  it 'should tokenize a name with a generation', ->
    # NOTE as with Bib(La)TeX, generations are only supported using commas
    expect(tokenizeName('Jones, Jr, James Earl')).toEqual \
      ['James', 'Earl', '', 'Jones', 'Jr']

  it 'should tokenize a name with a hyphenated forename', ->
    expect(tokenizeName('Sartre, Jean-Paul')).toEqual \
      ['Jean-Paul', '', '', 'Sartre', '']

  it 'should tokenize a name with a hyphenated forename in "first last" format', ->
    expect(tokenizeName('Jean-Paul Sartre')).toEqual \
      ['Jean-Paul', '', '', 'Sartre', '']

  it 'should tokenize a name with a hyphenated surname', ->
    expect(tokenizeName('Charles-Gabriel, Jean')).toEqual \
      ['Jean', '', '', 'Charles-Gabriel', '']

  it 'should tokenize a name with a hyphenated surname in "first last" format', ->
    expect(tokenizeName('Jean Charles-Gabriel')).toEqual \
      ['Jean', '', '', 'Charles-Gabriel', '']

  it 'should tokenize a name with a prefixed surname', ->
    expect(tokenizeName('van Houten, James')).toEqual \
      ['James', '', 'van', 'Houten', '']

  it 'should tokenize a name with a prefixed surname in "firt last" format', ->
    expect(tokenizeName('James van Houten')).toEqual \
      ['James', '', 'van', 'Houten', '']

  it 'should tokenize a name with a long prefixed surname', ->
    expect(tokenizeName('van auf der Rissen, Gloria')).toEqual \
      ['Gloria', '', 'van auf der', 'Rissen', '']

  it 'should tokenize a name with a long prefixed surname in "first last" format', ->
    expect(tokenizeName('Gloria van auf der Rissen')).toEqual \
      ['Gloria', '', 'van auf der', 'Rissen', '']

  it 'should tokenize a compound last name', ->
    # NOTE this is not reproducible in "first last" format because of the
    # ambiguity between a compound last name and a middle name
    expect(tokenizeName('Almodóvar Caballero, Pedro')).toEqual \
      ['Pedro', '', '', 'Almodóvar Caballero', '']

  it 'should tokenize a compound last name with brackets', ->
    expect(tokenizeName('{Almodóvar Caballero}, Pedro')).toEqual \
      ['Pedro', '', '', '{Almodóvar Caballero}', '']

  it 'should tokenize a compound last name with brackets in "first last" format', ->
    # NOTE unlike the unbracketed form, with brackets, this should be
    # tokenizeable in any format
    expect(tokenizeName('Pedro {Almodóvar Caballero}')).toEqual \
      ['Pedro', '', '', '{Almodóvar Caballero}', '']

  it 'should tokenize a complex name', ->
    expect(tokenizeName(
      'de la Vall{\\\'e}e~Poussin, Jean Charles~Gabriel'
    )).toEqual \
      ['Jean', 'Charles Gabriel', 'de la', 'Vall{\\\'e}e Poussin', '']

  it 'should tokenize a complex name in "first last" format', ->
    expect(tokenizeName(
      'Jean Charles~Gabriel de la Vall{\\\'e}e~Poussin'
    )).toEqual \
      ['Jean', 'Charles Gabriel', 'de la', 'Vall{\\\'e}e Poussin', '']

  it 'should tokenize a complex name with unicode', ->
    expect(tokenizeName(
      'de la Vallée~Poussin, Jean Charles~Gabriel'
    )).toEqual \
      ['Jean', 'Charles Gabriel', 'de la', 'Vallée Poussin', '']

  it 'should tokenize a name with lower-case in the last name', ->
    expect(tokenizeName(
      'von Berlichingen zu Hornberg, Johann Gottfried'
    )).toEqual \
      ['Johann', 'Gottfried', 'von', 'Berlichingen zu Hornberg', '']

  it 'should tokenize a name with lower-case in the last name in "first last" format', ->
    expect(tokenizeName(
      'Johann Gottfried von Berlichingen zu Hornberg'
    )).toEqual \
      ['Johann', 'Gottfried', 'von', 'Berlichingen zu Hornberg', '']

  it 'should tokenize a mononym in brackets', ->
    expect(tokenizeName('{Marx and Sons}')).toEqual \
      ['{Marx and Sons}', '', '', '', '']

  it 'should tokenize a name with an initial only', ->
    expect(tokenizeName('T. Hobbes')).toEqual \
      ['T.', '', '', 'Hobbes', '']

describe 'Name', ->
  it 'should reformat a simple name', ->
    expect(new Name('Simon~Coddlington').toString()).toEqual \
      'Coddlington, Simon'

  it 'should handle a name with a hyphen', ->
    expect(new Name('Jean-Paul Sartre').toString()).toEqual \
      'Sartre, Jean-Paul'

  it 'should handle a prefixed surname', ->
    expect(new Name('Gloria van auf der Rissen').toString()).toEqual \
      'van auf der Rissen, Gloria'

  it 'should handle a complex name', ->
    expect(new Name('de la Vall{\\\'e}e~Poussin, Jean Charles~Gabriel')\
      .toString()).toEqual \
        'de la Vall{\\\'e}e Poussin, Jean Charles Gabriel'

  it 'should handle a mononym', ->
    expect(new Name('Augustine').toString()).toEqual 'Augustine'
