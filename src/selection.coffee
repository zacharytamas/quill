equal     = require('deep-equal')
Parchment = require('parchment')
platform  = require('./lib/platform')


class Range
  constructor: (@start, @end = @start) ->

  isCollapsed: ->
    return @start == @end

  shift: (index, length) ->
    [@start, @end] = [@start, @end].map((pos) ->
      return pos if index > pos
      if length >= 0
        return pos + length
      else
        return Math.max(index, pos + length)
    )


class Selection
  @Range: Range

  constructor: (@doc, @documentRoot = document) ->
    @root = @doc.domNode
    @lastRange = @savedRange = new Range(0, 0)  # savedRange is never null
    ['keyup', 'mouseup', 'mouseleave', 'touchend', 'touchleave'].forEach((eventName) =>
      @root.addEventListener(eventName, =>
        this.update()  # Do not pass event handler params
      )
    )
    this.update()

  checkFocus: ->
    return @documentRoot.activeElement == @root

  focus: ->
    return if this.checkFocus()
    @root.focus()
    this.setRange(@savedRange)

  getBounds: (index) ->
    pos = @doc.findPath(index).pop()
    return null unless pos?
    containerBounds = @root.parentNode.getBoundingClientRect()
    side = 'left'
    if pos.blot.getLength() == 0
      bounds = pos.blot.parent.domNode.getBoundingClientRect()
    else if pos.blot instanceof Parchment.Embed
      bounds = pos.blot.domNode.getBoundingClientRect()
      side = 'right' if pos.offset > 0
    else
      range = document.createRange()
      if pos.offset < pos.blot.getLength()
        range.setStart(pos.blot.domNode, pos.offset)
        range.setEnd(pos.blot.domNode, pos.offset + 1)
        side = 'left'
      else
        range.setStart(pos.blot.domNode, pos.offset - 1)
        range.setEnd(pos.blot.domNode, pos.offset)
        side = 'right'
      bounds = range.getBoundingClientRect()
    return {
      height: bounds.height
      left: bounds[side] - containerBounds.left
      top: bounds.top - containerBounds.top
    }

  getNativeRange: ->
    selection = @documentRoot.getSelection()
    return null unless selection?.rangeCount > 0
    nativeRange = selection.getRangeAt(0)
    if nativeRange.startContainer != @root &&
       !(nativeRange.startContainer.compareDocumentPosition(@root) & Node.DOCUMENT_POSITION_CONTAINS)
      return null
    if !nativeRange.collapsed && nativeRange.endContainer != @root &&
       !(nativeRange.endContainer.compareDocumentPosition(@root) & Node.DOCUMENT_POSITION_CONTAINS)
      return null
    return nativeRange

  getRange: ->
    convert = (node, offset) =>
      if !(node instanceof Text)
        if offset >= node.childNodes.length
          blot = Parchment.findBlot(node)
          return blot.offset(@doc) + blot.getLength()
        else
          node = node.childNodes[offset]
          offset = 0
      blot = Parchment.findBlot(node)
      return blot.offset(@doc) + offset
    if this.checkFocus()
      nativeRange = this.getNativeRange()
      return null unless nativeRange?
      start = convert(nativeRange.startContainer, nativeRange.startOffset)
      end = if nativeRange.collapsed then start else convert(nativeRange.endContainer, nativeRange.endOffset)
      return new Range(Math.min(start, end), Math.max(start, end)) # Handle backwards ranges
    else
      return null

  onUpdate: (range) ->

  prepare: (format, value) ->
    this.update()
    range = this.getRange()
    pos = @doc.findPath(range.start).pop()
    target = pos.blot.split(pos.offset)
    cursor = Parchment.create('cursor')
    target.parent.insertBefore(cursor, target)
    cursor.format(format, value)
    # Cursor will not blink if we make selection
    this.setNativeRange(cursor.domNode.firstChild, 1)

  scrollIntoView: ->
    return unless @range
    startBounds = this.getBounds(@range.start)
    endBounds = if @range.isCollapsed() then startBounds else this.getBounds(@range.end)
    containerBounds = @root.parentNode.getBoundingClientRect()
    containerHeight = containerBounds.bottom - containerBounds.top
    if containerHeight < endBounds.top + endBounds.height
      [line, offset] = @doc.findLineAt(@range.end)
      line.node.scrollIntoView(false)
    else if startBounds.top < 0
      [line, offset] = @doc.findLineAt(@range.start)
      line.node.scrollIntoView()

  setNativeRange: (startNode, startOffset, endNode = startNode, endOffset = startOffset) ->
    selection = @documentRoot.getSelection()
    return unless selection
    if startNode?
      # Need to focus before setting or else in IE9/10 later focus will cause a set on 0th index on line div
      # to be set at 1st index
      @root.focus() unless this.checkFocus()
      nativeRange = this.getNativeRange()
      # TODO do we need to avoid setting on same range?
      if !nativeRange? or
         startNode != nativeRange.startContainer or
         startOffset != nativeRange.startOffset or
         endNode != nativeRange.endContainer or
         endOffset != nativeRange.endOffset
        # IE9 requires removeAllRanges() regardless of value of
        # nativeRange or else formatting from toolbar does not work
        selection.removeAllRanges()
        range = document.createRange()
        range.setStart(startNode, startOffset)
        range.setEnd(endNode, endOffset)
        selection.addRange(range)
    else
      selection.removeAllRanges()
      @root.blur()
      # setRange(null) will fail to blur in IE10/11 on Travis+SauceLabs (but not local VMs)
      document.body.focus() if platform.isIE()

  setRange: (range) ->
    convert = (index) =>
      pos = @doc.findPath(index).pop()
      if pos.blot instanceof Parchment.Embed
        node = pos.blot.domNode.parentNode
        return [node, [].indexOf.call(node.childNodes, pos.blot.domNode) + pos.offset]
      else
        return [pos.blot.domNode, pos.offset]
    if range?
      [startNode, startOffset] = convert(range.start)
      if range.isCollapsed()
        this.setNativeRange(startNode, startOffset)
      else
        [endNode, endOffset] = convert(range.end)
        this.setNativeRange(startNode, startOffset, endNode, endOffset)
    else
      this.setNativeRange(null)
    this.update()

  update: (args...) ->
    oldRange = @lastRange
    @lastRange = this.getRange()
    @savedRange = @lastRange if @lastRange?
    if !equal(oldRange, @lastRange)
      this.onUpdate(@lastRange, args...)


module.exports = Selection
