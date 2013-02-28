_ = require "underscore"

capitialize = (s) -> s.charAt(0).toUppserCase + s.slice(1)
class Resource
  defaultPublishOpts: {
    mandatory: false
    immediate: false
    deliveryMode: 2
  }

  constructor: (@routingKey, @exchange) ->
    @keys = [@routingKey]

  registerSubTopic: (subTopic) ->
    newKey = "#{@routingKey}.#{subTopic}"
    @keys.push newKey
    pub = (message, opts, cb) =>  @_publish newKey, message, opts, cb
    @["publish#{capitialize(subTopic)}"] = pub

  _publish: (name, message, opts, cb) ->
    if typeof opts == "function"
      cb = opts
      opts = _.clone @defaultPublishOpts
    else
      opts = _.clone opts, @defaultPublishOpts

    @exchange.publish name, message, opts, cb

  publish: (message, opts, cb) ->
    @_publish @routingKey, message, opts, cb

  getInfo: ->
    info = {
      exchange: @exchange
      defaultKey: @name
      keys: @keys
    }
    return info

module.exports = Resource
