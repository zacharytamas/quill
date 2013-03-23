Scribe = require('./scribe')


# TODO fix this entire file, esp findDeepestNode
class Scribe.Position
  @findDeepestNode: (editor, node, offset) ->
    # We are at right subtree, dive deeper
    isLineNode = Scribe.Line.isLineNode(node)
    nodeLength = Scribe.Utils.getNodeLength(node)
    if isLineNode && offset < nodeLength
      Scribe.Position.findDeepestNode(editor, node.firstChild, Math.min(offset, nodeLength))
    else if offset < nodeLength
      if node.firstChild?
        Scribe.Position.findDeepestNode(editor, node.firstChild, offset)
      else
        return [node, offset]
    else if node.nextSibling?               # Not at right subtree, advance to sibling
      offset -= nodeLength
      Scribe.Position.findDeepestNode(editor, node.nextSibling, offset)
    else if node.lastChild?
      return Scribe.Position.findDeepestNode(editor, node.lastChild, Scribe.Utils.getNodeLength(node.lastChild))
    else
      return [node, offset]

  @findLeafNode: (editor, node, offset) ->
    [node, offset] = Scribe.Position.findDeepestNode(editor, node, offset)
    if node.nodeType == node.TEXT_NODE
      offset = Scribe.Position.getIndex(node, offset, node.parentNode)
      node = node.parentNode
    return [node, offset]
  
  @getIndex: (node, index, offsetNode = null) ->
    while node != offsetNode and node.parentNode != node.ownerDocument.body
      while node.previousSibling?
        node = node.previousSibling
        index += Scribe.Utils.getNodeLength(node)
      node = node.parentNode
    return index


  # constructor: (Editor editor, Object node, Number offset) ->
  # constructor: (Editor editor, Number index) -> 
  constructor: (@editor, @leafNode, @offset) ->
    if _.isNumber(@leafNode)
      @offset = @index = @leafNode
      @leafNode = @editor.root.firstChild
    else
      @index = Scribe.Position.getIndex(@leafNode, @offset)
    [@leafNode, @offset] = Scribe.Position.findLeafNode(@editor, @leafNode, @offset)

  getLeaf: ->
    return @leaf if @leaf?
    @leaf = @editor.doc.findLeaf(@leafNode)
    return @leaf


module.exports = Scribe