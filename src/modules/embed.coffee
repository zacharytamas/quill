Quill = require('../quill')
_     = Quill.require('lodash')


Embed =
  embeds:
    IMAGE:
      tag: 'IMG'
      attribute:
        src: null
        alt: null
        height: null
        width: null


_.each(Embed.embeds, (embed, name) ->
  Quill.registerEmbed(name.toLowerCase(), embed)
)


module.exports = Embed
