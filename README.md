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

disributor.register("posts", function(err, postsResource) {
  postsResource.publish({beep: "boop"})
  postsResource.publish({beep: "loop"}, opts, function(err) {
  })
  postsResource.registerSubTopic("comments")
  postsResource.publishComments({name: "Bob", message: "hi"})
  // get your resources out
  writeFile("resourceDefinitions.json", disributor.getResources())
})

  
// consumer

var Client = require("distributor").Client
// fetch your resource definition
var resourceDefintions = readFile("resourceDefinitions.json")

var client = new Client("amqp://localhost:5672", resourceDefinitions)

// want a work queue?
client.posts.createWorker("shared_queue_name", function(err, worker) {
  worker.subscribe(worker.defaultTopic, function(err, cb) {
  })
})

// or pub sub instead?
client.posts.createSubscriber(function(err, worker) {
  worker.subscribe("service_name.exchange_name.comments", function(err, cb) {
  })
})
```

For more syntax, see the tests
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
