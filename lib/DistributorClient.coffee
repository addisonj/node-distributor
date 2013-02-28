request = require "request"
_ = require "underscore"

class DistributorClient

  constructor: (opts) ->
    if opts.resources
      @_processResources opts.resources
      

  @_processResources: (resources) ->

  fetchResource: (host, resourcePath, cb) ->
    if typeof resourcePath == "function"
      cb = resourcePath
      resourcePath = "/_resources"

    request {url: host + resourcePath, json: true}, (err, resp, body) ->
      return cb err if err
      return cb new Error("failed to fetch resources") if resp.statusCode != 200

      


