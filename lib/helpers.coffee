GitLogUtils = require 'git-log-utils'


module.exports =
  getPatchsetInfo: ->
    repo = atom.project.getRepositories()[0]
    return [] unless repo

    gerritRemote = repo.getConfigValue('remote.gerrit.url')
    return [] unless gerritRemote

    rawInfo = GitLogUtils.getCommitHistory(repo.repo.workingDirectory)[0]
    changeId = /Change-Id: (I[0-9a-fA-F]+)$/.exec(rawInfo['body'])
    return [changeId[1], rawInfo['id'], gerritRemote]
