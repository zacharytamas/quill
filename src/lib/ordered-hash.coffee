class OrderedHash
  constructor: ->
    @keys = []
    @hash = {}

  forEach: (fn) ->
    @keys.forEach((key) =>
      fn(key, @hash[key])
    )

  get: (key) ->
    return @hash[key]

  remove: (key) ->
    @keys.splice(@keys.indexOf(key), 1)
    delete @hash[key]

  set: (key, value) ->
    this.remove(key) if @hash[key]?
    @keys.push(key)
    @hash[key] = value


module.exports = OrderedHash
