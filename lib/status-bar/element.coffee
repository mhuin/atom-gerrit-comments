gerritClient = require './../gerrit-client'
GerritStatusBarView = require './view'

module.exports = new class GerritStatusBar
    initialize: ->
        gerritClient.onDidUpdateStatusbar (_labels) => @updateStatusBar(_labels)
        @view = new GerritStatusBarView

    destroy: ->

    updateStatusBar: (_labels) ->
        labels = _labels['labels']
        uri = _labels['uri']
        @view.setCounters(labels['Code-Review'], labels['Verified'], labels['Workflow'])
        @view.setReviewURI(uri)
