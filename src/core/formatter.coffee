_   = require('lodash')
dom = require('../lib/dom')
OrderedHash = require('../lib/ordered-hash')


calculateTag = (config, type, value) ->
  if _.isObject(config.tag)
    tag = _.findKey(value)
  else if type == Formatter.types.LINE
    tag = dom.DEFAULT_BLOCK_TAG
  else
    tag = dom.DEFAULT_INLINE_TAG
  return tag


class Format
  constructor: (config, @type = Formatter.types.INLINE) ->
    @config = _.clone(config)
    # Allows for shorthands ex. { tag: 'B' }
    _.each(['tag', 'class'], (key) =>
      if _.isString(config[key])
        value = config[key]
        @config[key] = {}
        @config[key][value] = true
    )

  set: (node, value) ->
    if @config.tag or dom(node).isTextNode()
      tagValue = if _.isString(value) then value else value.tag
      tag = calculateTag(this, tagValue)
      if tag != node.tagName
        if @type == Formatter.types.LINE
          node = dom(node).switchTag(tag)
        else
          formatNode = document.createElement(tag)
          dom(node).wrap(formatNode)
          node = formatNode
    if @config.attribute
      _.each(@config.attribute, (attributeValue, attributeName) ->
        if _.isString(value)
          attribute = value
        else
          attribute = if value[attributeName]? then value[attributeName] else attributeValue
        if attribute
          node.setAttribute(attributeName, attribute)
        else
          node.removeAttribute(attributeName)
      )
    if @config.class
      $node = dom(node)
      _.each(@config.class, (classValue, className) =>
        if className[className.length - 1] == '-'
          _.each($node.classes(), (c) ->
            $node.removeClass(c) if c.indexOf(className) == 0
          )
          classValue += className
        $node.addClass(className)
      )
    if @config.style
      _.each(@config.style, (styleDefault, styleName) ->
        style = if _.isString(value) then value else value[styleName]
        node.style[styleName] = style if style != styleDefault
      )
    return node

  create: (value) ->
    node = document.createElement(calculateTag(this, value))
    return this.set(node, value)

  prepare: (value) ->
    if _.isString(@config.prepare)
      document.execCommand(@config.prepare, false, value)
    else if _.isFunction(@config.prepare)
      this.prepare(value)

  remove: (node) ->
    if @type == Formatter.types.EMBED
      dom(node).remove()
      return
    if @config.style
      _.each(@config.style, (styleDefault, styleName) ->
        node.style[styleName] = ''    # IE10 requires setting to '', other browsers can take null
      )
    if @config.class
      $node = dom(node)
      _.each($node.classes(), (c) =>
        _.each(@config.class, (classValue, className) ->
          if className[className.length - 1] == '-'
            $node.removeClass(c) if c.indexOf(classValue) == 0
          else
            $node.removeClass(c) if c == classValue
        )
      )
    if @config.attribute
      _.each(@config.attribute, (attributeValue, attributeName) ->
        node.removeAttribute(attributeName)
      )
    if @config.tag
      if @type == Formatter.types.LINE
        node = dom(node).switchTag(dom.DEFAULT_BLOCK_TAG)
      else
        return dom(node).switchTag(dom.DEFAULT_INLINE_TAG)
    if node.tagName == dom.DEFAULT_INLINE_TAG and !node.hasAttributes()
      node = dom(node).unwrap()
    return node

  value: (node) ->
    value = {}
    if !_.all(@config.attribute or {}, (attributeValue, attributeName) ->
      nodeAttribute = node.getAttribute(attributeName) or false   # Avoid ""
      if attributeValue == null
      # Attribute presence required when config set to null
        return false if !nodeAttribute
        value[attributeName] = nodeAttribute
      else if nodeAttribute != attributeValue
        value[attributeName] = nodeAttribute
      return true
    )
      return undefined
    if @config.class
      classes = dom(node).classes()
      if !_.all(@config.class, (classValue, className) ->
        if className[className.length - 1] == '-'
          return _.any(classes, (c) ->
            if c.indexOf(classValue) == 0
              value[className] = c.slice(classValue)
              return true
            return false
          )
        else if classes.indexOf(className) > -1
          value[className] = true
          return true
        else
          return false
      )
        return undefined
    if !_.all(@config.style, (styleDefault, styleName) ->
      style = node.style[styleName]
      if style and style != styleDefault
        value[styleName] = style
        return true
      return false
    )
      return undefined
    if @config.tag and @config.tag[node.tagName]
      value.tag = @config.tag[node.tagName]
    else
      return undefined
    numKeys = _.keys(value).length
    if numKeys == 0
      return undefined
    else if numKeys == 1
      return value[_.keys(value)[0]]
    else
      return value


class Formatter extends OrderedHash
  @formats: new OrderedHash()

  @types:
    EMBED: 'embed'
    INLINE: 'inline'
    LINE: 'line'

  @Format: Format

  add: (name) ->
    format = Formatter.formats.get(name)
    throw new Error("Cannot load #{name} format. Are you sure you registered it?") unless format?
    this.set(name, format)
    # TODO Suboptimal performance and somewhat hacky
    @keys.sort(_.bind(Formatter.formats.compare, Formatter.formats))

  check: (node) ->
    # TODO optimize
    return _.reduce(@hash, (formats, format, name) ->
      if value = format.value(node)
        formats[name] = value
      return formats
    , {})


module.exports = Formatter
