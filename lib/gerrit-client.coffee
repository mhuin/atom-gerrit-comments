fs = require 'fs'
{CompositeDisposable, Emitter} = require 'atom'
_ = require 'underscore-plus'
{getPatchsetInfo} = require './helpers'
Polling = require './polling'
yaml = require 'js-yaml'
GerritAPI = require './gerrit-api'


CONFIG_POLLING_INTERVAL = 'gerrit-comments.pollingInterval'
CONFIG_GERRITRC = 'gerrit-comments.gerritConfigFile'


module.exports = new class GerritClient

  initialize: ->
    @gerritRemote = 'XXX'
    @emitter = new Emitter
    @polling = new Polling
    @gapi = {}
    @polling.initialize()

    @URL_TEST_NODE ?= document.createElement('a')
    @gerrits = {}
    @updateConfig()

    @activeItemSubscription = atom.workspace.onDidChangeActivePaneItem =>
      @subscribeToActiveItem()
    @projectPathSubscription = atom.project.onDidChangePaths =>
      @subscribeToRepositories()
    @subscribeToRepositories()
    @subscribeToActiveItem()
    @subscribeToConfigChanges()

    @polling.onDidTick => @_tick()
    @updatePollingInterval()
    @polling.start()

  destroy: ->
    @URL_TEST_NODE = null
    @gerrits = {}

    @activeItemSubscription?.dispose()
    @projectPathSubscription?.dispose()

  subscribeToActiveItem: ->
    activeItem = @getActiveItem()

    @savedSubscription?.dispose()
    @savedSubscription = activeItem?.onDidSave? => @updateRepoBranch()

    @updateRepoBranch()

  subscribeToConfigChanges: ->
    @configSubscriptions?.dispose()
    @configSubscriptions = new CompositeDisposable

    @_subscribeConfig CONFIG_POLLING_INTERVAL, => @updatePollingInterval()
    @_subscribeConfig CONFIG_GERRITRC, => @updateConfig()

  _subscribeConfig: (configKey, cb) ->
    @configSubscriptions.add atom.config.onDidChange configKey, cb

  subscribeToRepositories: ->
    @repositorySubscriptions?.dispose()
    @repositorySubscriptions = new CompositeDisposable

    for repo in atom.project.getRepositories() when repo?
      @repositorySubscriptions.add repo.onDidChangeStatus ({path, status}) =>
        @updateRepoBranch() if path is @getActiveItemPath()
      @repositorySubscriptions.add repo.onDidChangeStatuses =>
        @updateRepoBranch()

  getActiveItem: ->
    atom.workspace.getActivePaneItem()

  getActiveItemPath: ->
    @getActiveItem()?.getPath?()

  _findRemoteAPIURL: ->
      try
        for server in @gerrits.servers
            if @gerritRemote.match(server.remote)
                return server
      catch
        return null

  updateGerritApi: ->
    gerritRemoteInfo = @_findRemoteAPIURL(@gerrits, @gerritRemote)
    if (gerritRemoteInfo isnt null)
        gapi = new GerritAPI(gerritRemoteInfo.url, gerritRemoteInfo.user, gerritRemoteInfo.password)
        return gapi
    return null

  updateConfig: ->
    configFile = atom.config.get('gerrit-comments.gerritConfigFile')
    try
        @gerrits = yaml.safeLoad(fs.readFileSync(configFile, 'utf8'))
    catch
        console.log "Could not load rc file: " + configFile
        @gerrits = {}
    @polling.forceIfStarted()

  updatePollingInterval: ->
    interval = atom.config.get(CONFIG_POLLING_INTERVAL)
    @polling.set(interval * 1000)

  updateRepoBranch: ->
    [changeId, revision, gerritRemote] = getPatchsetInfo()
    if changeId isnt @changeId or revision isnt @revision or gerritRemote isnt @gerritRemote
      @changeId = changeId
      @revision = revision
      @gerritRemote = gerritRemote
      @gapi = @updateGerritApi()
      @polling.forceIfStarted()

  onDidUpdateComments: (cb) ->
    @emitter.on('did-update-comments', cb)

  onDidUpdateStatusbar: (cb) ->
    @emitter.on('did-update-statusbar', cb)

  _fetchComments: ->
    unless @changeId and @revision and @gerritRemote
      # Case 1: This is not even from a gerrit
      return Promise.resolve([])
    return @gapi.getComments(@changeId, @revision)

  _fetchLabels: ->
    unless @changeId and @revision and @gerritRemote
      # Case 1: This is not even from a gerrit
      return Promise.resolve([])
    return @gapi.getLabels(@changeId, @revision)

  _tick: ->
    @updateRepoBranch() # Sometimes the branch name does not update

    if @changeId and @revision and @gerritRemote
      @_fetchComments()
      .then (comments) =>
        @emitter.emit('did-update-comments', comments)
      .then undefined, (err) =>
        try
          # yield [] so consumers still run
          return []
        catch error

          atom.notifications.addError 'Error fetching Pull Request data from GitHub',
            dismissable: true
            detail: 'Make sure you are connected to the internet?'
        # yield [] so consumers still run
        []
      @_fetchLabels()
      .then (labels) =>
        @emitter.emit('did-update-statusbar', labels)
      .then undefined, (err) =>
        try
          # yield [] so consumers still run
          return []
        catch error

          atom.notifications.addError 'Error fetching Pull Request data from GitHub',
            dismissable: true
            detail: 'Make sure you are connected to the internet?'
        # yield [] so consumers still run
        []
    else
      # No gerrit info
      @emitter.emit 'did-update-comments', []
      @emitter.emit 'did-update-statusbar', {}
