_          = require('lodash')
Delta      = require('rich-text/lib/delta')
dom        = require('../lib/dom')
Formatter  = require('./formatter')
Leaf       = require('./leaf')
Line       = require('./line')
LinkedList = require('../lib/linked-list')
Normalizer = require('../lib/normalizer')


class Line extends LinkedList.Node
  @CLASS_NAME : 'ql-line'
  @ID_PREFIX  : 'ql-line-'

  constructor: (@doc, @node) ->
    @id = _.uniqueId(Line.ID_PREFIX)
    @formats = {}
    dom(@node).addClass(Line.CLASS_NAME)
    this.rebuild()
    super(@node)

  buildLeaves: (node, formats) ->
    _.each(dom(node).childNodes(), (node) =>
      node = Normalizer.normalizeNode(node)
      nodeFormats = _.clone(formats)
      # TODO: optimize
      _.each(@doc.formats, (format, name) ->
        if format.type != Formatter.types.LINE and value = Formatter.value(format, node)
          nodeFormats[name] = value
      )
      if Leaf.isLeafNode(node)
        _.each(@doc.embeds, (embed, name) ->
          if value = Embedder.value(embed, node)
            nodeFormats[name] = value
        )
        @leaves.append(new Leaf(node, nodeFormats))
      else
        this.buildLeaves(node, nodeFormats)
    )

  deleteAt: (offset, length) ->
    return unless length > 0
    [leaf, offset] = this.findLeafAt(offset)
    while leaf? and length > 0
      deleteLength = Math.min(length, leaf.length - offset)
      leaf.deleteText(offset, deleteLength)
      length -= deleteLength
      leaf = leaf.next
      offset = 0
    this.rebuild()

  findLeaf: (leafNode) ->
    curLeaf = @leaves.first
    while curLeaf?
      return curLeaf if curLeaf.node == leafNode
      curLeaf = curLeaf.next
    return null

  findLeafAt: (offset, inclusive = false) ->
    # TODO exact same code as findLineAt
    return [@leaves.last, @leaves.last.length] if offset >= @length - 1
    leaf = @leaves.first
    while leaf?
      if offset < leaf.length or (offset == leaf.length and inclusive)
        return [leaf, offset]
      offset -= leaf.length
      leaf = leaf.next
    return [@leaves.last, offset - @leaves.last.length]   # Should never occur unless length calculation is off

  format: (name, value) ->
    return if (line.formats[name] == value) or (!value and !line.formats[name]?)
    if value
      if format.type == Formatter.types.LINE
        @node = Formatter.add(format, @node, value)
      else
        # TODO add indicator to DOM
        todo = true
      @formats[name] = value
    else
      @node = Formatter.remove(format, @node) if format.type == Formatter.types.LINE
      delete @formats[format.exclude]

  formatAt: (offset, length, name, value) ->
    format = @doc.formatter.get(name)
    return if format.type == Formatter.types.LINE
    [leaf, leafOffset] = this.findLeafAt(offset)
    while leaf? and length > 0
      nextLeaf = leaf.next
      # Make sure we need to change leaf format
      if (value and leaf.formats[name] != value) or (!value and leaf.formats[name]?)
        leafNode = leaf.node
        # Isolate node
        [leafNode, rightNode] = dom(targetNode).split(leafOffset + length) if leaf.length > leafOffset + length
        [leftNode, leafNode] = dom(targetNode).split(leafOffset) if leafOffset > 0
        targetNode = leafNode
        if leaf.formats[name]?
          while !format.match(targetNode)
            targetNode = targetNode.parentNode
          format.remove(targetNode)
        else
          while targetNode.parentNode != @node
            formats = @formatter.check(targetNode)
            if _.all(formats, (value, key) =>
              @formatter.compare(name, key) <= 0
            )
              dom(leafNode.nextSibling).splitBefore(targetNode.parentNode) if leafNode.nextSibling?
              dom(leafNode).splitBefore(targetNode.parentNode)
              format.add(targetNode, value)
              break
            else if _.all(formats, (value, key) =>
              @formatter.compare(name, key) >= 0
            )
              targetNode = targetNode.parentNode
            else
              formats = Object.keys(leaf.formats)
              formats.push(name)
              formats.sort(@formatter.compare)
              dom(leafNode.nextSibling, true).splitBefore(@node) if leafNode.nextSibling?
              dom(leafNode, true).splitBefore(@node)
              while leafNode.parentNode != @node
                dom(leafNode.parentNode).unwrap()
              _.each(formats, (format) ->
                value = if format == name then value else leaf.formats[name]
                leafNode = format.add(leafNode, value)
              )
              break
      length -= leaf.length - leafOffset
      leafOffset = 0
      leaf = nextLeaf
    this.rebuild()

  insertAt: (offset, insert, value) ->
    [leaf, leafOffset] = this.findLeafAt(offset)
    [prevNode, nextNode] = dom(leaf.node).split(leafOffset)
    nextNode = dom(nextNode).splitBefore(@node).get() if nextNode
    node = if _.isString(insert) then document.createTextNode(insert) else insert.create(value)
    @node.insertBefore(node, nextNode)
    this.rebuild()

  optimize: ->
    Normalizer.optimizeLine(@node)
    this.rebuild()

  rebuild: (force = false) ->
    if !force and @outerHTML? and @outerHTML == @node.outerHTML
      if _.all(@leaves.toArray(), (leaf) =>
        return dom(leaf.node).isAncestor(@node)
      )
        return false
    @node = Normalizer.normalizeNode(@node)
    if dom(@node).length() == 0 and !@node.querySelector(dom.DEFAULT_BREAK_TAG)
      @node.appendChild(document.createElement(dom.DEFAULT_BREAK_TAG))
    @leaves = new LinkedList()
    @formats = _.reduce(@doc.formats, (formats, format, name) =>
      if format.type == Formatter.types.LINE
        if Formatter.match(format, @node)
          formats[name] = Formatter.value(format, @node)
        else
          delete formats[name]
      return formats
    , @formats)
    this.buildLeaves(@node, {})
    this.resetContent()
    return true

  resetContent: ->
    @node.id = @id unless @node.id == @id
    @outerHTML = @node.outerHTML
    @length = 1
    @delta = new Delta()
    _.each(@leaves.toArray(), (leaf) =>
      @length += leaf.length
      # TODO use constant for embed type
      if dom.EMBED_TAGS[leaf.node.tagName]?
        @delta.insert(1, leaf.formats)
      else
        @delta.insert(leaf.text, leaf.formats)
    )
    @delta.insert('\n', @formats)


module.exports = Line
