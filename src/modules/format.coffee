Quill = require('../quill')
_     = Quill.require('lodash')


Format =
  formats:
    BOLD:
      tag: 'B'

    ITALIC:
      tag: 'I'

    UNDERLINE:
      tag: 'U'

    STRIKE:
      tag: 'S'

    COLOR:
      style:
        color: 'rgb(0, 0, 0)'

    BACKGROUND:
      style:
        backgroundColor: 'rgb(255, 255, 255)'

    FONT:
      style:
        fontFamily: "'Helvetica', 'Arial', sans-serif"

    SIZE:
      style:
        fontSize: '13px'

    LINK:
      tag: 'A'
      attribute:
        href: null
        title: null
        target: '_blank'

    ALIGN:
      type: 'line'
      style:
        textAlign: 'left'

    BULLET:
      type: 'line'
      tag: 'LI'
      match: (node) ->
        return node.parentNode?.tagName == 'UL'

    LIST:
      type: 'line'
      tag: 'LI'
      match: (node) ->
        return node.parentNode?.tagName == 'OL'

    IMAGE:
      tag: 'IMG'
      attribute:
        src: null
        alt: null
        height: null
        width: null


_.each(Format.formats, (format, name) ->
  Quill.registerFormat(name.toLowerCase(), format)
)


module.exports = Format
