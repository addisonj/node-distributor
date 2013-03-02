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
    @exchanges = {}

  createExchange: (name, opts, cb) ->
    if typeof opts == "function"
      cb = opts
      opts = _.clone defaults.exchange
    else
      opts = _.clone opts, defaults.exchange

    return cb @exchanges[name] if @exchanges[name]

    if @isReady
      @connection.exchange name, opts, cb
    else
      @connection.once "ready", =>
        @connection.exchange name, opts, cb

  register: (resourceName, exchangeName) ->
    exchangeName ||= @exchangeName

    return @resources[resourceName] if @resources[resourceName]

    newResource = new Resource "#{@serviceName}.#{resourceName}", exchangeName, @
    @resources[resourceName] = newResource
    return newResource

  getResources: ->
    resources = {}
    for name, resource of @resources
      resources[name] = resource.getInfo()

    return resources

module.exports = Distributor
