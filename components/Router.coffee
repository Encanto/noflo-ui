noflo = require 'noflo'

buildContext = (url) ->
  routeData =
    route: ''
    subroute: 'open'
    runtime: null
    project: null
    graph: null
    component: null
    nodes: []

  if url is ''
    routeData.route = 'main'
    return routeData

  urlParts = url.split('/').map (part) -> decodeURIComponent part
  route = urlParts.shift()
  switch route
    when 'project'
      # Locally stored project
      routeData.route = 'storage'
      routeData.project = urlParts.shift()
      if urlParts[0] is 'component' and urlParts.length is 2
        # Opening a component from the project
        routeData.component = urlParts[1]
        return routeData
      # Opening a graph from the project
      routeData.graph = urlParts.shift()
      routeData.nodes = urlParts
      return routeData
    when 'example'
      return ctx =
        route: 'redirect'
        url: "gist/#{urlParts.join('/')}"
    when 'gist'
      # Example graph to be fetched from gists
      routeData.route = 'github'
      routeData.subroute = 'gist'
      routeData.graph = urlParts.shift()
      routeData.remote = urlParts
      return routeData
    when 'github'
      # Project to download and open from GitHub
      routeData.route = 'github'
      [owner, repo] = urlParts.splice 0, 2
      routeData.repo = "#{owner}/#{repo}"
      routeData.branch = 'master'
      return routeData unless urlParts.length
      if urlParts[0] is 'tree'
        # Opening a particular branch
        urlParts.shift()
        routeData.branch = urlParts.join '/'
        return routeData
      if urlParts[0] is 'blob'
        # Opening a particular file
        urlParts.shift()
        routeData.branch = urlParts.shift()
        if urlParts[0] is 'graphs'
          routeData.graph = urlParts[1]
        if urlParts[0] is 'components'
          routeData.component = urlParts[1]
      return routeData
    when 'runtime'
      # Graph running on a remote runtime
      routeData.route = 'runtime'
      routeData.runtime = urlParts.shift()
      routeData.nodes = urlParts
      return routeData

  # No route matched, redirect to main screen
  return ctx =
    route: 'redirect'
    url: ''

exports.getComponent = ->
  c = new noflo.Component
  c.inPorts.add 'in',
    datatype: 'object'
  c.outPorts.add 'route',
    datatype: 'object'
  c.outPorts.add 'redirect',
    datatype: 'string'
  c.outPorts.add 'missed',
    datatype: 'bang'

  noflo.helpers.WirePattern c,
    in: 'in'
    out: ['route', 'redirect', 'missed']
    forwardGroups: false
    async: true
  , (action, groups, out, callback) ->
    ctx = buildContext action.payload
    unless ctx
      out.missed.send
        payload: ctx
      return callback()

    if ctx.route is 'redirect'
      out.redirect.send "##{ctx.url}"
      return callback()

    action = "#{ctx.route}:#{ctx.subroute}"
    delete ctx.subroute
    out.route.send
      action: action
      payload: ctx
    callback()
