Quill = require('../quill')
_     = Quill.require('lodash')


Embed =
  mappings:
    IMAGE: 1

  embeds:
    IMAGE:
      tag: 'IMG'
      attribute:
        src: null
        alt: null
        height: null
        width: null


_.each(Embed.embeds, (embed, name) ->
  Quill.registerEmbed(name.toLowerCase(), embed, Embed.mappings[name])
)


module.exports = Embed
