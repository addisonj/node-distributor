_ = require "underscore"
amqp = require "amqp"
defaults = require "./defaultOpts"
{capitialize} = require "./util"
{EventEmitter} = require "events"
Worker = require "./Worker"

class Client extends EventEmitter
  constructor: (@description, connectionOverride, connectionOpts) ->

    @connectInfo = connectionOverride || description.connectionInfo
    @connection = amqp.createConnection @connectInfo, connectionOpts
    @connection.once "ready", =>
      @_isReady = true

    @connection.on "error", (err) => @emit "error", err
    @connection.on "closed", (arg) => @emit "closed", arg

    @_process description.resources
    @_queues = {}

  createQueue: ->
    return @_createQueue.apply @, arguments if @_isReady
    args = arguments

    @connection.once "ready", =>
      @_createQueue.apply @, args

  _createQueue: (name, opts, cb) ->
    @connection.queue name, opts, (queue) =>
      @_queues[name] = queue if name
      cb queue

  createWorker: (name, opts) ->
    if not opts
      opts = _.clone defaults.queue_worker
    else
      opts = _.defaults opts, defaults.queue_worker

    defaultTopic = "#{@description.serivceName}.#"
    topics = [defaultTopic]

    return new Worker @, name, opts, @description.exchange, defaultTopic, topics, defaults.subscribe_worker

  createSubscriber: (opts) ->
    if not opts
      opts = _.clone defaults.queue_worker
    else
      opts = _.defaults opts, defaults.queue_worker

    defaultTopic = "#{@description.serivceName}.#"
    topics = [defaultTopic]

    return new Worker @, "", opts, @description.exchange, defaultTopic, topics, defaults.subscribe_subscriber

  _makeResource: (params, defaultTopic) ->
    defaultTopic = defaultTopic or params.defaultTopic
    resourceMethods = {
      createWorker: (name, opts) =>
        if not opts
          opts = _.clone defaults.queue_worker
        else
          opts = _.defaults opts, defaults.queue_worker

        return new Worker @, name, opts, params.exchange, defaultTopic, params.topics, defaults.subscribe_worker

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

      for topic in params.topics
        topicRegEx = new RegExp "#{params.defaultTopic}[.]*"
        subTopic = topic.replace topicRegEx, ''
        @[resource][subTopic] = @_makeResource params, topic if subTopic

module.exports = Client
