_ = require "underscore"
amqp = require "amqp"
defaults = require "./defaultOpts"
{capitialize} = require "./util"
{EventEmitter} = require "events"
Worker = require "./Worker"

class Client extends EventEmitter
  constructor: (connString, resources, @connectOpts) ->
    @connectInfo = if typeof connString == "object" then connString else {url: connString}
    @connection = amqp.createConnection @connectInfo, @connectOpts
    @connection.once "ready", =>
      @_isReady = true

    @connection.on "error", (err) => @emit "error", err

    @_process resources
    @_queues = {}

  createQueue: ->
    return @_createQueue.apply @, arguments if @_isReady
    args = arguments

    @connection.once "ready", =>
      @_createQueue.apply @, args

  _createQueue: (name, opts, cb) ->
    return cb @_queues[name] if @_queues[name]

    @connection.queue name, opts, (queue) =>
      @_queues[name] = queue if name
      cb queue

  _makeResource: (params) -> 
    resourceMethods = {
      createWorker: (name, opts) =>
        if not opts
          opts = _.clone defaults.queue_worker
        else
          opts = _.defaults opts, defaults.queue_worker

        return new Worker @, name, opts, params.exchange, params.defaultTopic, params.topics, defaults.subscribe_worker

      createSubscriber: (opts) =>
        if not opts
          opts = _.clone defaults.queue_subscriber
        else
          opts = _.defaults opts, defaults.queue_subscriber

        return new Worker @, "", opts, params.exchange, params.defaultTopic, params.topics, defaults.subscribe_subscriber
    }
    return resourceMethods

  _process: (resources) ->
    for resource, params of resources
      @[resource] = @_makeResource params

module.exports = Client
