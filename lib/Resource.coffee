_ = require "underscore"
defaults = require "./defaultOpts"

{capitialize} = require "./util"
class Resource
  constructor: (@routingKey, @exchange) ->
    @keys = [@routingKey]

  registerSubTopic: (subTopic) ->
    newKey = "#{@routingKey}.#{subTopic}"
    @keys.push newKey
    pub = (message, opts, cb) =>  @_publish newKey, message, opts, cb
    @["publish#{capitialize(subTopic)}"] = pub

  # both opts and cb are optional
  _publish: (name, message, opts, cb) ->
    if typeof opts == "function"
      cb = opts
      opts = _.clone defaults.publish
    else
      cb = cb || ->
      opts = _.clone (opts|| defaults.publish), defaults.publish

    @exchange.publish name, message, opts, cb

  publish: (message, opts, cb) ->
    @_publish @routingKey, message, opts, cb

  getInfo: ->
    info = {
      exchange: @exchange.name
      defaultTopic: @routingKey
      topics: @keys
    }
    return info

module.exports = Resource
