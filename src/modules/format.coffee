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
      parentTag = node.parentNode?.tagName
      return value and (parentTag == 'OL' or parentTag == 'UL')

  QUOTE:
    tag: 'BLOCKQUOTE'


Embed =
  AUDIO:
    tag: 'AUDIO'
    attribute:
      src: null

  EMBED:
    tag: 'EMBED'
    attribute:
      height: null
      src: null
      width: null

  IFRAME:
    tag: 'IFRAME'
    attribute:
      frameborder: 0
      height: null
      sandbox: true
      src: null
      width: null

  IMAGE:
    tag: 'IMG'
    attribute:
      alt: null
      height: null
      src: null
      width: null

  VIDEO:
    tag: 'VIDEO'
    attribute:
      autoplay: false
      controls: true
      height: null
      src: null
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
