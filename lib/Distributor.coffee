amqp = require "amqp"
_ = require "underscore"
Resource = require "./Resource"
{EventEmitter} = require "events"

class Distributor
  defaultExchangeOpts: {
    type: "topic"
    passive: false
    durable: true
    confirm: true
    autoDelete: false
    noDeclare: false
  }

  constructor: (@connectionString, @serviceName, @exchangeName) ->
    @connection = amqp.createConnection {url: @connectionString}
    @connection.once "ready", =>
      @isReady = true
    
    @resources = {}

  createExchange: (name, opts, cb) ->
    if typeof opts == "function"
      cb = opts
      opts = _.clone @defaultExchangeOpts
    else
      opts = _.clone opts, @defaultExchangeOpts

    if @isReady
      @connection.exchange name, opts, cb
    else
      @connection.on "ready", =>
        @connection.exchange name, opts, cb

  _createDefaultExchange: (cb) ->
    return cb null, @exchange if @exchange

    @createExchange @exchangeName, (exchange) =>
      @exchange = exchange
      cb null, exchange
    
  register: (resourceName, exchange, cb) ->
    if typeof exchange != "function"
      return @_register resourceName, exchange, cb
    
    cb = exchange
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
