amqp = require "amqp"
_ = require "underscore"
Resource = require "./Resource"
{EventEmitter} = require "events"
defaults = require "./defaultOpts"

class Distributor extends EventEmitter
  constructor: (connString, @serviceName, @exchangeName, @connectOpts) ->
    @connectInfo = if typeof connString == "object" then connString else {url: connString}
    @connection = amqp.createConnection @connectInfo, @connectOpts
    @connection.once "ready", =>
      @isReady = true

    @connection.on "error", (err) =>
      @emit "error", err
    
    @resources = {}

  createExchange: (name, opts, cb) ->
    if typeof opts == "function"
      cb = opts
      opts = _.clone defaults.exchange
    else
      opts = _.clone opts, defaults.exchange

    if @isReady
      @connection.exchange name, opts, cb
    else
      @connection.once "ready", =>
        @connection.exchange name, opts, cb

  _createDefaultExchange: (cb) ->
    return cb null, @exchange if @exchange

    @createExchange @exchangeName, (exchange) =>
      @exchange = exchange
      cb null, exchange
    
  register: (resourceName, exchange, cb) ->
    if typeof exchange != "function"
      return cb null, @resources[resourceName] if @resources[resourceName]
      return @_register resourceName, exchange, cb
    
    cb = exchange
    return cb null, @resources[resourceName] if @resources[resourceName]

    @_createDefaultExchange (err, exchange) =>
      return cb err if err
      @_register resourceName, exchange, cb

  _register: (resourceName, exchange, cb) ->
    newResource = new Resource "#{@serviceName}.#{resourceName}", exchange
    @resources[resourceName] = newResource
    cb null, newResource

  getResources: ->
    resources = {}
    for name, resource of @resources
      resources[name] = resource.getInfo()

    return resources

module.exports = Distributor
