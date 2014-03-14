_ = require "underscore"

class Worker
  constructor: (@client, @name, @queueOpts, @exchangeName, @defaultTopic, @topics, @defaults) ->

  getTopics: -> @topics
  getDefaultTopic: -> @defaultTopic
  getQueue: (cb) ->
    return cb @queue if @queue

    @client.createQueue @name, @queueOpts, (@queue) =>
      cb @queue

  subscribe: (key, opts, fn) ->
    if typeof opts == "function"
      fn = opts
      opts = _.clone @defaults
    else if typeof key == 'function'
      fn = key
      key = @getDefaultTopic()
      opts = _.clone @defaults
    else
      opts = _.defaults opts, @defaults

    @getQueue =>
      @queue.bind @exchangeName, key
      @queue.subscribe opts, @onMessage(fn)

  onMessage: (fn) =>
    return (msg, headers, deliveryInfo) =>
      cb = => @queue.shift()
      fn msg, cb, headers, deliveryInfo

  unsubscribe: (key) ->
    @queue.unbind @exchangeName, key

module.exports = Worker
