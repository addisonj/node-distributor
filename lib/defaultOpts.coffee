
module.exports = {
  exchange: {
    type: "topic"
    passive: false
    durable: true
    confirm: true
    autoDelete: false
    noDeclare: false
  }

  publish: {
    mandatory: false
    immediate: false
    deliveryMode: 2
  }

  queue_worker: {
    passive: false
    durable: true
    exclusive: false
    autoDelete: false
    arguments: {
      "x-ha-policy" : "all"
    }
  }

  queue_subscriber: {
    passive: false
    durable: true
    exclusive: true
    autoDelete: true
    arguments: {
      "x-ha-policy" : "all"
    }
  }

  subscribe_worker: {
    ack: true
    prefetchCount: 1
    exclusive: false
  }

  subscribe_subscriber: {
    ack: true
    prefetchCount: 20
    exclusive: true
  }

}
