
assert = require "assert"
Distributor = require "../lib/Distributor"


describe "Distributor", ->

  distributor = null
  before (done) ->
    distributor = new Distributor("amqp://localhost:5672", "test_service", "test_service_exchange")
    distributor.on "error", (err) ->
    done()


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
        done()
