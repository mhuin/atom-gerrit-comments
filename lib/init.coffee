{CompositeDisposable} = require 'atom'

fs = require 'fs-plus'
path = require 'path'

default_gerritrc = '/root/.gerritrc'

module.exports = new class GerritComments
  config:
    gerritConfigFile:
      type: 'string'
      default: default_gerritrc
      title: 'Gerrit(s) configuration file'
      description: 'The location of  your configuration file.'
      order: 1
    pollingInterval:
      title: 'API polling interval'
      description: 'How often (in seconds) should updated comments be retreived'
      type: 'number'
      default: 60
      minimum: 20
      order: 2

  treeViewDecorator: null # Delayed instantiation

  activate: ->
    require('atom-package-deps').install('gerrit-comments')
    @subscriptions = new CompositeDisposable
    @gerritClient ?= require('./gerrit-client')
    @gerritClient.initialize()

    @treeViewDecorator ?= require('./tree-view-decorator')
    @treeViewDecorator.initialize()

    @gerritLinter ?= require('./gerrit-linter')
    @gerritLinter.initialize()
    @statusBar ?= require('./status-bar/element')
    @statusBar.initialize()

  deactivate: ->
    @gerritClient?.destroy()
    @treeViewDecorator?.destroy()
    @gerritLinter.destroy()
    @subscriptions.destroy()
    @statusBarTile?.destroy()

  consumeStatusBar: (statusBar) ->
    @statusBarTile = statusBar.addLeftTile
        item: atom.views.getView(@statusBar.view), priority: 5

  consumeLinter: (registry) ->
    atom.packages.activate('linter').then =>

      registry = atom.packages.getLoadedPackage('linter').mainModule.provideIndie()

      linter = registry({name: 'Gerrit Comments'})
      @gerritLinter.setLinter(linter)
      @subscriptions.add(linter)
