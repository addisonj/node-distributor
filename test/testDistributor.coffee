
assert = require "assert"
Distributor = require "../lib/Distributor"


describe "Distributor", ->

  it "should connect", (done) ->
    distribute = new Distributor("amqp://localhost:5672", "test_service", "test_service_exchange")
    distribute.register "testResource", (err, resource) ->
      assert.ifError err
      assert.ok resource
      assert.ok resource.exchange
      done()
