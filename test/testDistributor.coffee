
assert = require "assert"
Distributor = require "../lib/Distributor"
Client = require "../lib/Client"

resourceList = {
  testResource: {
    exchange: "test_service_exchange"
    defaultTopic: "test_service.testResource"
    topics: [
      "test_service.testResource"
      "test_service.testResource.comments"
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
  alt_exchange: {
    exchange: "test_exchange_2"
    defaultTopic: "test_service.alt_exchange"
    topics: [
      "test_service.alt_exchange"
      "test_service.alt_exchange.boop"
    ]
  }
}

distributor = new Distributor("amqp://localhost:5672", "test_service", "test_service_exchange")
client = new Client("amqp://localhost:5672", resourceList)


describe "Distributor", ->

  it "should be able to register a resource", (done) ->
    distributor.register "testResource", (err, resource) ->
      assert.ifError err
      assert.ok resource
      assert.ok resource.exchange
      done()

  it "should work to publish a message", (done) ->
    distributor.register "testResource", (err, resource) ->
      resource.publish {foo: "bar"}, (err) ->
        assert.ifError err
        resource.publish {baz: "herp"}, {deliveryMode: 1}, (err) ->
          assert.ifError err
          done()

  it "should be able to make subtopics", (done) ->
    distributor.register "testResource", (err, resource) ->
      resource.registerSubTopic "comments"
      resource.publishComments {baz: "bah"}, (err) ->
        assert.ifError err
        done()

  it "should work with a different exchange", (done) ->
    distributor.createExchange "test_exchange_2", (exchange) ->
      assert.ok exchange
      distributor.register "alt_exchange", exchange, (err, resource) ->
        assert.ifError err
        assert.ok resource
        resource.registerSubTopic "boop"
        assert.deepEqual {
          exchange: exchange.name
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
    distributor.register "res1", (err, rec1) ->
      assert.ifError err
      rec1.registerSubTopic "foo"
      distributor.register "res2", (err, rec2) ->
        assert.ifError err
        rec2.registerSubTopic "bar"
        assert.deepEqual distributor.getResources(), resourceList
        done()


  it "shoulnd't require a callback when publishing", (done) ->
    distributor.register "testResource", (err, resource) ->
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
    distributor.register "testResource", (err, resource) ->
      resource.registerSubTopic "clientTest"
      client.testResource.createWorker "testQueue", (err, worker) ->
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

        resource.publishClientTest msg1
        resource.publishClientTest msg2

  it "should be able to subscribe two subscribeers and have them both get it", (done) ->
    distributor.register "testResource", (err, resource) ->
      resource.registerSubTopic "clientTestPubSub"
      client.testResource.createSubscriber (err, worker1) ->
        client.testResource.createSubscriber (err, worker2) ->
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

          # we need this to take a second so the bind happens
          setTimeout ->
            resource.publishClientTestPubSub msg
          , 500
