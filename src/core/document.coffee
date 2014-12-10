_          = require('lodash')
Delta      = require('rich-text/lib/delta')
dom        = require('../lib/dom')
Embedder   = require('./embedder')
Formatter  = require('./formatter')
Line       = require('./line')
LinkedList = require('../lib/linked-list')
Normalizer = require('../lib/normalizer')


class Document
  constructor: (@root, options = {}) ->
    @embeds = {}
    @formats = {}
    options.embeds.forEach(this.addEmbed.bind(this))
    options.formats.forEach(this.addFormat.bind(this))
    this.setHTML(@root.innerHTML)

  addEmbed: (name, embed) ->
    @embeds[name] = embed

  addFormat: (name, format) ->
    @formats[name] = format

  appendLine: (lineNode) ->
    return this.insertLineBefore(lineNode, null)

  insertAt: (index, value, attributes = {}) ->
    [line, offset] = this.findLineAt(index)
    if _.isString(insert)
      text = insert.replace(/\r\n?/g, '\n')
      lineTexts = text.split('\n')
      _.each(lineTexts, (lineText, i) =>
        if !line? or line.length <= offset    # End of document
          if i < lineTexts.length - 1 or lineText.length > 0
            line = this.appendLine(document.createElement(dom.DEFAULT_BLOCK_TAG))
            offset = 0
            line.insertText(offset, lineText, attributes)
            line.format(attributes)
            nextLine = null
        else
          line.insertText(offset, lineText, attributes)
          if i < lineTexts.length - 1       # Are there more lines to insert?
            nextLine = this.splitLine(line, offset + lineText.length)
            _.each(_.defaults({}, attributes, line.formats), (value, format) ->
              line.format(format, attributes[format])
            )
            offset = 0
        line = nextLine
      )
    else
      # TODO convert integer into name
      line.insertEmbed(offset, 'image', attributes['image'])

  formatAt: (start, end, attributes = {}) ->
    [line, offset] = this.findLineAt(index)
    while line? and length > 0
      formatLength = Math.min(length, line.length - offset - 1)
      line.formatText(offset, formatLength, name, value)
      length -= formatLength
      line.format(name, value) if length > 0
      length -= 1
      offset = 0
      line = line.next


  deleteAt: (index, length) ->
    [firstLine, offset] = this.findLineAt(index)
    curLine = firstLine
    mergeFirstLine = firstLine.length - offset <= length and offset > 0
    while curLine? and length > 0
      nextLine = curLine.next
      deleteLength = Math.min(curLine.length - offset, length)
      if offset == 0 and length >= curLine.length
        this.removeLine(curLine)
      else
        curLine.deleteText(offset, deleteLength)
      length -= deleteLength
      curLine = nextLine
      offset = 0
    this.mergeLines(firstLine, firstLine.next) if mergeFirstLine and firstLine.next


  findLeafAt: (index, inclusive) ->
    [line, offset] = this.findLineAt(index)
    return if line? then line.findLeafAt(offset, inclusive) else [null, offset]

  findLine: (node) ->
    while node? and !dom.BLOCK_TAGS[node.tagName]?
      node = node.parentNode
    line = if node? then @lineMap[node.id] else null
    return if line?.node == node then line else null

  findLineAt: (index) ->
    return [null, index] unless @lines.length > 0
    length = this.toDelta().length()     # TODO optimize
    return [@lines.last, @lines.last.length] if index == length
    return [null, index - length] if index > length
    curLine = @lines.first
    while curLine?
      return [curLine, index] if index < curLine.length
      index -= curLine.length
      curLine = curLine.next
    return [null, index]    # Should never occur unless length calculation is off

  getHTML: ->
    html = @root.innerHTML
    # Preserve spaces between tags
    html = html.replace(/\>\s+\</g, '>&nbsp;<')
    container = document.createElement('div')
    container.innerHTML = html
    _.each(container.querySelectorAll(".#{Line.CLASS_NAME}"), (node) ->
      dom(node).removeClass(Line.CLASS_NAME)
      node.removeAttribute('id')
    )
    return container.innerHTML

  insertLineBefore: (newLineNode, refLine) ->
    line = new Line(this, newLineNode)
    if refLine?
      @root.insertBefore(newLineNode, refLine.node) unless dom(newLineNode.parentNode).isElement()  # Would prefer newLineNode.parentNode? but IE will have non-null object
      @lines.insertAfter(refLine.prev, line)
    else
      @root.appendChild(newLineNode) unless dom(newLineNode.parentNode).isElement()
      @lines.append(line)
    @lineMap[line.id] = line
    return line

  mergeLines: (line, lineToMerge) ->
    if lineToMerge.length > 1
      dom(line.leaves.last.node).remove() if line.length == 1
      _.each(dom(lineToMerge.node).childNodes(), (child) ->
        line.node.appendChild(child) if child.tagName != dom.DEFAULT_BREAK_TAG
      )
    this.removeLine(lineToMerge)
    line.rebuild()

  optimizeLines: ->
    # TODO optimize algorithm (track which lines get dirty and only Normalize.optimizeLine those)
    _.each(@lines.toArray(), (line, i) ->
      line.optimize()
      return true    # line.optimize() might return false, prevent early break
    )

  rebuild: ->
    lines = @lines.toArray()
    lineNode = @root.firstChild
    lineNode = lineNode.firstChild if lineNode? and dom.LIST_TAGS[lineNode.tagName]?
    _.each(lines, (line, index) =>
      while line.node != lineNode
        if line.node.parentNode == @root or line.node.parentNode?.parentNode == @root
          # New line inserted
          lineNode = Normalizer.normalizeLine(lineNode)
          newLine = this.insertLineBefore(lineNode, line)
          lineNode = dom(lineNode).nextLineNode(@root)
        else
          # Existing line removed
          return this.removeLine(line)
      if line.outerHTML != lineNode.outerHTML
        # Existing line changed
        line.node = Normalizer.normalizeLine(line.node)
        line.rebuild()
      lineNode = dom(lineNode).nextLineNode(@root)
    )
    # New lines appended
    while lineNode?
      lineNode = Normalizer.normalizeLine(lineNode)
      this.appendLine(lineNode)
      lineNode = dom(lineNode).nextLineNode(@root)

  removeLine: (line) ->
    if line.node.parentNode?
      if dom.LIST_TAGS[line.node.parentNode.tagName] and line.node.parentNode.childNodes.length == 1
        dom(line.node.parentNode).remove()
      else
        dom(line.node).remove()
    delete @lineMap[line.id]
    @lines.remove(line)

  setHTML: (html) ->
    html = Normalizer.stripComments(html)
    html = Normalizer.stripWhitespace(html)
    @root.innerHTML = html
    @lines = new LinkedList()
    @lineMap = {}
    this.rebuild()

  splitLine: (line, offset) ->
    offset = Math.min(offset, line.length - 1)
    [lineNode1, lineNode2] = dom(line.node).split(offset, true)
    line.node = lineNode1
    line.rebuild()
    newLine = this.insertLineBefore(lineNode2, line.next)
    newLine.formats = _.clone(line.formats)
    newLine.resetContent()
    return newLine

  toDelta: ->
    lines = @lines.toArray()
    delta = new Delta()
    _.each(lines, (line) ->
      _.each(line.delta.ops, (op) ->
        delta.push(op)
      )
    )
    return delta


module.exports = Document
