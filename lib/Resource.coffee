_ = require "underscore"
defaults = require "./defaultOpts"

{capitialize} = require "./util"
class Resource
  constructor: (@routingKey, @exchangeName, @distributor) ->
    @keys = [@routingKey]

  registerSubTopic: (subTopic) ->
    newKey = "#{@routingKey}.#{subTopic}"
    @keys.push newKey
    pub = (message, opts, cb) =>  @_publish newKey, message, opts, cb
    @["publish#{capitialize(subTopic)}"] = pub

  _getExchange: (cb) ->
    return cb @exchange if @exchange

    @distributor.createExchange @exchangeName, (@exchange) =>
      cb @exchange

  # both opts and cb are optional
  _publish: (name, message, opts, cb) ->
    if typeof opts == "function"
      cb = opts
      opts = _.clone defaults.publish
    else
      cb = cb || ->
      opts = _.clone (opts|| defaults.publish), defaults.publish

    @_getExchange (exchange) ->
      exchange.publish name, message, opts, cb

  # expose publishing with a name
  publishWithTopic: -> @_publish.apply @, arguments

  publish: (message, opts, cb) ->
    @_publish @routingKey, message, opts, cb

  getInfo: ->
    info = {
      exchange: @exchangeName
      defaultTopic: @routingKey
      topics: @keys
    }
    return info

module.exports = Resource
