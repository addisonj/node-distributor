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
    return cb null, @_queues[name] if @_queues[name]

    @connection.queue name, opts, (queue) =>
      @_queues[name] = queue if name
      cb null, queue


  _createWorker: (name, exchange, queue_opts, sub_opts, topics, defaultTopic, cb) ->
    @createQueue name, queue_opts, (err, queue) ->
      return cb err if err
      cb null, new Worker queue, exchange, defaultTopic, topics, sub_opts

  _makeResource: (params) -> 
    resourceMethods = {
      createWorker: (name, opts, cb) =>
        if typeof opts == "function"
          cb = opts
          opts = _.clone defaults.queue_worker
        else
          opts = _.defaults opts, defaults.queue_worker

        @_createWorker name, params.exchange, opts, defaults.subscribe_worker, params.topics, params.defaultTopic, cb

      createSubscriber: (opts, cb) =>
        if typeof opts == "function"
          cb = opts
          opts = _.clone defaults.queue_subscriber
        else
          opts = _.defaults opts, defaults.queue_subscriber

        # by sending in null, we let the server create the queue
        @_createWorker "", params.exchange, opts, defaults.subscribe_subscriber, params.topics, params.defaultTopic, cb
    }
    return resourceMethods

  _process: (resources) ->
    for resource, params of resources
      @[resource] = @_makeResource params

module.exports = Client
