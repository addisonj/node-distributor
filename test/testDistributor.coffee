
assert = require "assert"
Distributor = require "../lib/Distributor"
Client = require "../lib/Client"

definition = {
  resources: {
    testResource: {
      exchange: "test_service_exchange"
      defaultTopic: "test_service.testResource"
      topics: [
        "test_service.testResource"
        "test_service.testResource.comments"
      ]
    }
    alt_exchange: {
      exchange: "test_exchange_2"
      defaultTopic: "test_service.alt_exchange"
      topics: [
        "test_service.alt_exchange"
        "test_service.alt_exchange.boop"
      ]
    }
    res1: {
      exchange: "test_service_exchange"
      defaultTopic: "test_service.res1"
      topics: [
        "test_service.res1"
        "test_service.res1.foo"
      ]
    }
    res2: {
      exchange: "test_service_exchange"
      defaultTopic: "test_service.res2"
      topics: [
        "test_service.res2"
        "test_service.res2.bar"
      ]
    }
  }
  connectionInfo: {url: "amqp://localhost:5672"}
  serivceName: "test_service"
  exchange: "test_service_exchange"
}

distributor = new Distributor("amqp://localhost:5672", "test_service", "test_service_exchange")
client = new Client(definition)


describe "Distributor", ->

  it "should be able to register a resource", (done) ->
    resource = distributor.register "testResource"
    assert.ok resource
    assert.ok resource.exchangeName
    done()

  it "should work to publish a message", (done) ->
    resource = distributor.register "testResource"
    resource.publish {foo: "bar"}, (err) ->
      assert.ifError err
      resource.publish {baz: "herp"}, {deliveryMode: 1}, (err) ->
        assert.ifError err
        done()

  it "should be able to make subtopics", (done) ->
    resource = distributor.register "testResource"
    resource.registerSubTopic "comments"
    resource.publishComments {baz: "bah"}, (err) ->
      assert.ifError err
      done()

  it "should work with a different exchange", (done) ->
    resource = distributor.register "alt_exchange", "test_exchange_2"
    assert.ok resource
    resource.registerSubTopic "boop"
    assert.deepEqual {
      exchange: "test_exchange_2"
      defaultTopic: "test_service.alt_exchange"
      topics: [
        "test_service.alt_exchange"
        "test_service.alt_exchange.boop"
      ]
    }, resource.getInfo()
    resource.publish {hurp: "durp"}, (err) ->
      assert.ifError err
      done()

  it "should print out resources and its topic and exchanges", (done) ->
    res1 = distributor.register "res1"
    res1.registerSubTopic "foo"
    res2 = distributor.register "res2"
    res2.registerSubTopic "bar"
    assert.deepEqual distributor.getDefinition(), definition
    done()

  it "shoulnd't require a callback when publishing", (done) ->
    resource = distributor.register "testResource"
    resource.publish({1: 2})
    resource.publish({1: 3}, {deliveryMode: 1})
    resource.registerSubTopic "comments"
    resource.publishComments {baz: "bah"}
    done()



describe "Client", ->
  it "should have an object with each resource", ->
    assert.ok client.alt_exchange
    assert.ok client.res1
    assert.ok client.res2
    assert.ok client.testResource

  it "should be able to subscribe as a worker and recive messages when published", (done) ->
    resource = distributor.register "testResource"
    resource.registerSubTopic "clientTest"
    worker = client.testResource.createWorker "testQueue"
    msg1 = {boop: "beep"}
    msg2 = {boop: "meep"}
    count = 0
    worker.subscribe 'test_service.testResource.clientTest', (msg, cb) ->
      count++
      if count == 1
        assert.deepEqual msg, msg1
        cb()
      if count == 2
        assert.deepEqual msg, msg2
        cb()
        done()

    # we timeout to make sure the queue is created and bound
    setTimeout ->
      resource.publishClientTest msg1
      resource.publishClientTest msg2
    , 500

  it "should be able to subscribe two subscribeers and have them both get it", (done) ->
    resource = distributor.register "testResource"
    resource.registerSubTopic "clientTestPubSub"
    worker1 = client.testResource.createSubscriber()
    worker2 = client.testResource.createSubscriber()
    msg = {boop: "leep"}
    count = 0
    worker1.subscribe 'test_service.testResource.clientTestPubSub', (msg, cb) ->
      count++
      cb()
      if count == 2
        done()
    worker2.subscribe 'test_service.testResource.clientTestPubSub', (msg, cb) ->
      count++
      cb()
      if count == 2
        done()

    setTimeout ->
      resource.publishClientTestPubSub msg
    , 500

  it "should work to create a subscriber on the client", (done) ->
    worker = client.createSubscriber()
    resource = distributor.register "testResource"
    assert.ok worker
    assert.equal worker.defaultTopic, "test_service.#"
    # this will call back multiple times possibly, we don't care
    called = false
    worker.subscribe worker.defaultTopic, (msg, cb) ->
      if not called
        called = true
        done()


    setTimeout ->
      resource.publish "hello"
    , 500

  it "should work to create a worker on the client", (done) ->
    worker = client.createWorker("bah")
    resource = distributor.register "testResource"
    assert.ok worker
    assert.equal worker.defaultTopic, "test_service.#"
    # this will call back multiple times possibly, we don't care
    called = false
    worker.subscribe worker.defaultTopic, (msg, cb) ->
      if not called
        called = true
        done()


    setTimeout ->
      resource.publish "hello"
    , 500

  it "should work to create a worker on a sub topic", (done) ->
    worker = client.testResource.comments.createWorker "subTopicWorker"
    resource = distributor.register "testResource"
    resource.registerSubTopic 'comments'
    assert.ok worker
    assert.ok resource

    data = {hi: 'mom'}

    worker.subscribe (msg, cb) ->
      assert.ok msg
      assert.equal msg.hi, data.hi
      done()

    setTimeout ->
      resource.publishComments data
    , 500

  it "should also work to publish a message with any old topic", (done) ->
    worker = client.testResource.createWorker "randomWorker"
    resource = distributor.register "testResource"
    topic = "totally.random.key"
    data = {boo: 2}
    worker.subscribe topic, (msg, cb) ->
      assert.ok msg
      assert.equal msg.boo, data.boo
      done()

    setTimeout ->
      resource.publishWithTopic(topic, data)
    , 500

  it "should work to create a worker on the client and subscribe without specifying a topic", (done) ->
    worker = client.createWorker("bahbah")
    resource = distributor.register "testResource"
    assert.ok worker
    assert.equal worker.defaultTopic, "test_service.#"
    # this will call back multiple times possibly, we don't care
    called = false
    worker.subscribe (msg, cb) ->
      if not called
        called = true
        done()


    setTimeout ->
      resource.publish "hello"
    , 500
