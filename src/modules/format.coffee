Quill = require('../quill')
_     = Quill.require('lodash')


Inline =
  BACKGROUND:
    style:
      backgroundColor: 'rgb(255, 255, 255)'

  BOLD:
    tag: 'B'

  COLOR:
    style:
      color: 'rgb(0, 0, 0)'

  FONT:
    style:
      fontFamily: "'Helvetica', 'Arial', sans-serif"

  ITALIC:
    tag: 'I'

  LINK:
    tag: 'A'
    attribute:
      href: null
      title: null
      target: '_blank'

  SIZE:
    style:
      fontSize: '13px'

  STRIKE:
    tag: 'S'

  SUBSCRIPT:
    tag: 'SUB'

  SUPERSCRIPT:
    tag: 'SUP'

  UNDERLINE:
    tag: 'U'


Line =
  ALIGN:
    style:
      textAlign: 'left'

  BULLET:
    tag: 'LI'
    value: (node, value) ->
      return value and node.parentNode?.tagName == 'UL'

  DIRECTION:
    style:
      direction: 'ltr'

  HEADER:
    tag:
      H1: 1
      H2: 2
      H3: 3
      H4: 4
      H5: 5

  LIST:
    tag: 'LI'
    value: (node, value) ->
      return value and node.parentNode?.tagName == 'OL'

  QUOTE:
    tag: 'BLOCKQUOTE'


Embed =
  IMAGE:
    tag: 'IMG'
    attribute:
      src: null
      alt: null
      height: null
      width: null


Format =
  embed: Embed
  inline: Inline
  line: Line


Quill.registerFormat('link', Inline.LINK)
Quill.registerFormat('background', Inline.BACKGROUND)

_.each(Format, (group, type) ->
  _.each(group, (config, name) ->
    Quill.registerFormat(name.toLowerCase(), config, type) unless name == 'LINK' or name == 'BACKGROUND'
  )
)


module.exports = Format
