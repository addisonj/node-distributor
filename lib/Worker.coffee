_ = require "underscore"

class Worker
  constructor: (@queue, @exchangeName, @defaultTopic, @topics, @defaults) ->

  getTopics: -> @topics
  getDefaultTopic: -> @defaultTopic
  subscribe: (key, opts, fn) ->
    if typeof opts == "function"
      fn = opts
      opts = _.clone @defaults
    else
      opts = _.defaults opts, @defaults

    @queue.bind @exchangeName, key
    @queue.subscribe opts, @onMessage(fn)

  onMessage: (fn) =>
    return (msg, headers, deliveryInfo) =>
      cb = => @queue.shift()
      fn msg, cb, headers, deliveryInfo

  unsubscribe: (key) ->
    @queue.unbind @exchangeName, key

module.exports = Worker
