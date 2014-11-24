_   = require('lodash')
dom = require('../lib/dom')


types =
  LINE: 'line'

Formatter =
  types: types

  formats:
    BOLD:
      tag: 'B'
      prepare: 'bold'

    ITALIC:
      tag: 'I'
      prepare: 'italic'

    UNDERLINE:
      tag: 'U'
      prepare: 'underline'

    STRIKE:
      tag: 'S'
      prepare: 'strikeThrough'

    COLOR:
      style: 'color'
      default: 'rgb(0, 0, 0)'
      prepare: 'foreColor'

    BACKGROUND:
      style: 'backgroundColor'
      default: 'rgb(255, 255, 255)'
      prepare: 'backColor'

    FONT:
      style: 'fontFamily'
      default: "'Helvetica', 'Arial', sans-serif"
      prepare: 'fontName'

    SIZE:
      style: 'fontSize'
      default: '13px'
      prepare: (value) ->
        document.execCommand('fontSize', false, dom.convertFontSize(value))

    LINK:
      tag: 'A'
      attribute: 'href'

    ALIGN:
      type: types.LINE
      style: 'textAlign'
      default: 'left'

    BULLET:
      type: types.LINE
      exclude: 'list'
      parentTag: 'UL'
      tag: 'LI'

    LIST:
      type: types.LINE
      exclude: 'bullet'
      parentTag: 'OL'
      tag: 'LI'


  add: (format, node, value) ->
    return this.remove(node) unless value
    return node if this.value(node) == value
    if _.isString(format.parentTag)
      parentNode = document.createElement(format.parentTag)
      dom(node).wrap(parentNode)
      if node.parentNode.tagName == node.parentNode.previousSibling?.tagName
        dom(node.parentNode.previousSibling).merge(node.parentNode)
      if node.parentNode.tagName == node.parentNode.nextSibling?.tagName
        dom(node.parentNode).merge(node.parentNode.nextSibling)
    if _.isString(format.tag)
      formatNode = document.createElement(format.tag)
      if dom.VOID_TAGS[formatNode.tagName]?
        dom(node).replace(formatNode) if node.parentNode?
        node = formatNode
      else if format.type == Formatter.types.LINE
        node = dom(node).switchTag(format.tag)
      else
        dom(node).wrap(formatNode)
        node = formatNode
    if _.isString(format.style) or _.isString(format.attribute) or _.isString(format.class)
      if _.isString(format.class)
        node = this.remove(node)
      if dom(node).isTextNode()
        inline = document.createElement(dom.DEFAULT_INLINE_TAG)
        dom(node).wrap(inline)
        node = inline
      if _.isString(format.style)
        node.style[format.style] = value if value != format.default
      if _.isString(format.attribute)
        node.setAttribute(format.attribute, value)
      if _.isString(format.class)
        dom(node).addClass(format.class + value)
    return node

  match: (format, node) ->
    return false unless dom(node).isElement()
    if _.isString(format.parentTag) and node.parentNode?.tagName != format.parentTag
      return false
    if _.isString(format.tag) and node.tagName != format.tag
      return false
    if _.isString(format.style) and (!node.style[format.style] or node.style[format.style] == format.default)
      return false
    if _.isString(format.attribute) and !node.hasAttribute(format.attribute)
      return false
    if _.isString(format.class)
      for c in dom(node).classes()
        return true if c.indexOf(format.class) == 0
      return false
    return true

  prepare: (format, value) ->
    if _.isString(format.prepare)
      document.execCommand(format.prepare, false, value)
    else if _.isFunction(format.prepare)
      format.prepare(value)

  remove: (format, node) ->
    return node unless this.match(node)
    if _.isString(format.style)
      node.style[format.style] = ''    # IE10 requires setting to '', other browsers can take null
      node.removeAttribute('style') unless node.getAttribute('style')  # Some browsers leave empty style attribute
    if _.isString(format.attribute)
      node.removeAttribute(format.attribute)
    if _.isString(format.class)
      for c in dom(node).classes()
        dom(node).removeClass(c) if c.indexOf(format.class) == 0
    if _.isString(format.tag)
      if format.type == Formatter.types.LINE
        if _.isString(format.parentTag)
          dom(node).splitAncestors(node.parentNode.parentNode) if node.previousSibling?
          dom(node.nextSibling).splitAncestors(node.parentNode.parentNode) if node.nextSibling?
        node = dom(node).switchTag(dom.DEFAULT_BLOCK_TAG)
      else
        node = dom(node).switchTag(dom.DEFAULT_INLINE_TAG)
        dom(node).text(dom.EMBED_TEXT) if dom.EMBED_TAGS[format.tag]?   # TODO is this desireable?
    if _.isString(format.parentTag)
      dom(node.parentNode).unwrap()
    if node.tagName == dom.DEFAULT_INLINE_TAG and !node.hasAttributes()
      node = dom(node).unwrap()
    return node

  value: (format, node) ->
    return undefined unless this.match(node)
    if _.isString(format.attribute)
      return node.getAttribute(format.attribute) or undefined    # So "" does not get returned
    else if _.isString(format.style)
      return node.style[format.style] or undefined
    else if _.isString(format.class)
      for c in dom(node).classes()
        return c.slice(format.class.length) if c.indexOf(format.class) == 0
    else if _.isString(format.tag)
      return true
    return undefined


module.exports = Formatter
