_         = require('lodash')
dom       = require('../lib/dom')
Delta     = require('rich-text/lib/delta')
Document  = require('./document')
Line      = require('./line')
Selection = require('./selection')


class Editor
  @sources:
    API    : 'api'
    SILENT : 'silent'
    USER   : 'user'

  constructor: (@root, @quill, @options = {}) ->
    @root.setAttribute('id', @options.id)
    @doc = new Document(@root, @options)
    @delta = @doc.toDelta()
    @selection = new Selection(@doc, @quill)
    @timer = setInterval(_.bind(this.checkUpdate, this), @options.pollInterval)
    this.enable() unless @options.readOnly

  destroy: ->
    clearInterval(@timer)

  disable: ->
    this.enable(false)

  enable: (enabled = true) ->
    @root.setAttribute('contenteditable', enabled)

  applyDelta: (delta, source) ->
    localDelta = this._update()
    if localDelta
      delta = localDelta.transform(delta, true)
      localDelta = delta.transform(localDelta, false)
    if delta.ops.length > 0
      delta = this._trackDelta( =>
        index = 0
        range = @selection.getRange()
        _.each(delta.ops, (op) =>
          if _.isString(op.insert) or _.isNumber(op.insert)
            @doc.insertAt(index, op.insert, op.attributes)
            length = op.insert.length or 1
            range.shift(index, length)
            index += length
          else if _.isNumber(op.delete)
            @doc.deleteAt(index, op.delete)
            range.shift(index, -1 * op.delete)
          else if _.isNumber(op.retain)
            @doc.formatAt(index, op.retain, op.attributes)
            index += op.retain
        )
        @doc.optimizeLines()
        @selection.setRange(range, 'silent')
      )
      @delta = @doc.toDelta()
      @innerHTML = @root.innerHTML
      @quill.emit(@quill.constructor.events.TEXT_CHANGE, delta, source) if delta and source != Editor.sources.SILENT
    if localDelta and localDelta.ops.length > 0 and source != Editor.sources.SILENT
      @quill.emit(@quill.constructor.events.TEXT_CHANGE, localDelta, Editor.sources.USER)

  checkUpdate: (source = 'user') ->
    return clearInterval(@timer) unless @root.parentNode?
    delta = this._update()
    if delta
      @delta.compose(delta)
      @quill.emit(@quill.constructor.events.TEXT_CHANGE, delta, source)
    source = Editor.sources.SILENT if delta
    @selection.update(source)

  deleteAt: (start, end, source) ->
    this.applyDelta(new Delta().retain(start).delete(end - start), source)

  focus: ->
    if @selection.range?
      @selection.setRange(@selection.range)
    else
      @root.focus()

  formatAt: (start, end, attributes, source) ->
    this.applyDelta(new Delta().retain(start).retain(end - start, attributes), source)

  getBounds: (index) ->
    this.checkUpdate()
    [leaf, offset] = @doc.findLeafAt(index, true)
    throw new Error('Invalid index') unless leaf?
    containerBounds = @root.parentNode.getBoundingClientRect()
    side = 'left'
    if leaf.length == 0
      bounds = leaf.node.parentNode.getBoundingClientRect()
    else
      range = document.createRange()
      if offset < leaf.length
        range.setStart(leaf.node, offset)
        range.setEnd(leaf.node, offset + 1)
      else
        range.setStart(leaf.node, offset - 1)
        range.setEnd(leaf.node, offset)
        side = 'right'
      bounds = range.getBoundingClientRect()
    return {
      height: bounds.height
      left: bounds[side] - containerBounds.left,
      top: bounds.top - containerBounds.top
    }

  getDelta: ->
    return @delta

  insertAt: (index, value, attributes) ->
    this.applyDelta(new Delta().retain(index).insert(value, attributes), source)

  _trackDelta: (fn) ->
    fn()
    newDelta = @doc.toDelta()
    # TODO need to get this to prefer earlier insertions
    delta = @delta.diff(newDelta)
    return delta

  _update: ->
    return false if @innerHTML == @root.innerHTML
    delta = this._trackDelta( =>
      @selection.preserve(_.bind(@doc.rebuild, @doc))
      range = @selection.getRange()
      @doc.optimizeLines()
      @selection.setRange(range, 'silent')
    )
    @innerHTML = @root.innerHTML
    return if delta.ops.length > 0 then delta else false


module.exports = Editor
