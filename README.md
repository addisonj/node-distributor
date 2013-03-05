## Distributor
Resource based distribution of messages

### What?
If you do SOA, you will probably get to a point where others need to be informed of changes to a certain resource. Distributor makes it easy.

### How?

```JavaScript
// producer
var Distributor = require("distributor").Distributor

var distributor = new Distributor("amqp://localhost:5672", "service_name", "exchange_name")
// or
var distributor = new Distributor({...amqp connection options...}, "service_name", "exchange_name")

postsResoutce = disributor.register("posts")
postsResource.publish({beep: "boop"})
postsResource.publish({beep: "loop"}, opts, function(err) {
})
postsResource.registerSubTopic("comments")
postsResource.publishComments({name: "Bob", message: "hi"})
// get your resources out
writeFile("resourceDefinitions.json", disributor.getDefinition())

  
// consumer

var Client = require("distributor").Client
// fetch your resource definition
var resourceDefintions = readFile("resourceDefinitions.json")

var client = new Client(resourceDefinitions)

// want a work queue?
worker = client.posts.createWorker("shared_queue_name")
worker.subscribe(function(msg, cb) { // subscribe on the default topic, or specify another topic (routing key)
  // ack when done
  cb()
})

// or pub sub instead?
worker = client.posts.createSubscriber() // doesn't take a name, exclusive queue to each client
worker.subscribe("service_name.posts.comments", function(msg, cb) {
  cb()
})

// want a global worker instead
worker = client.createSubsciber()
// subscribes to "service_name.#" by deafult
worker.subscribe(function(msg, cb) {
  cb()
})
```

### API
```JavaScript
Distributor(connectionString, serviceName, exchangeName, connectionOpts)
connectionString - either amqp connectionString (amqp://..) or an options hash to be passed to node-amqp
serviceName - the high level name for the service (used when creating the topics)
exchangeName - the name of the exchange you want to use
connectionOpts (not required) - extra options to pass to node-amqp

distributor.register resourceName, exchangeName
resourceName - the name of the resources that you want to send messages on (posts, comments, etc)
exchangeName (optional) - a different exchange to publish too
```
###
### Advanced
If you want to tweak default options/values to rabbitmq
```Javascript
var distributor = require("distributor")
distributor.defaults.publish.deliveryMode = 1


// changing ack behavior on a worker
worker.onMessage = function(userHandlerFn) {
  var self = this
  // don't require user to call back, auto ack
  return function(msg, headers, deliverInfo) {
    userHandlerFn msg
    self.queue.shift()
  }
}
```

### Defaults
Distributor defaults to reliability, which means publish and consumer confirms are enabled

### Questions? Feature Requests?
Open a pull request!

### License
MIT
