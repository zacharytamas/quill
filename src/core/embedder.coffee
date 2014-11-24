_   = require('lodash')
dom = require('../lib/dom')
Formatter = require('./formatter')


Embedder =
  embeds:
    IMAGE:
      tag: 'IMG'
      attribute: 'src'

  create: (embed, value) ->
    node = document.createElement(embed.tag or dom.DEFAULT_INLINE_TAG)
    return Formatter.add(embed, node, value)

  value: (embed, node) ->
    return Formatter.value(embed, node)


module.exports = Embedder
