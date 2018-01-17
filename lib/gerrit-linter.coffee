fs = require 'fs'
path = require 'path'
{TextBuffer} = require 'atom'
_ = require 'underscore-plus'

gerritClient = require './gerrit-client'
{getPatchsetInfo} = require './helpers'

simplifyHtml = (html) ->
  DIV = document.createElement('div')
  DIV.innerHTML = html
  first = DIV.firstElementChild
  if first and first is DIV.lastElementChild and first.tagName.toLowerCase() is 'p'
    DIV.firstElementChild.innerHTML
  else
    DIV.innerHTML


module.exports = new class # This only needs to be a class to bind lint()

  initialize: ->
    gerritClient.onDidUpdateComments (comments) => @poll(comments)

  destroy: ->

  setLinter: (@linter) ->

  poll: (allComments) ->
    if allComments.length is 0
      @linter?.clearMessages()
      return
    repo = atom.project.getRepositories()[0]

    rootPath = path.join(repo.getPath(), '..')

    # Combine the comments by file
    filesMap = allComments

    allMessages = []

    for filePath, comments of filesMap
      do (filePath, comments) =>

        fileAbsolutePath = path.join(rootPath, filePath)

        # Get all the diffs since the last commit (TODO: Do not assume people push their commits immediately)
        # These are used to shift/remove comments in the gutter

        fileText = fs.readFileSync(fileAbsolutePath, 'utf-8') # HACK: Assumes the file is utf-8


        # Sort all the comments and combine multiple comments
        # that were made on the same line
        lineMap = {}
        _.forEach comments, (comment) ->
          position = comment.line
          lineMap[position] ?= []
          lineMap[position].push(comment)

        # Collapse multiple comments on the same line
        # into 1 message with newlines
        editorBuffer = new TextBuffer {text: fileText}
        lintWarningsOrNull = _.map lineMap, (commentsOnLine, position) =>
          position = parseInt(position)
          # Put a squiggly across the entire line by finding the line length
          if editorBuffer.getLineCount() <= position - 1
            lineLength = 1
          else
            lineLength = editorBuffer.lineLengthForRow(position - 1)

          text = commentsOnLine.map(({author, message}) =>
             "#{message}"
          ).join('\n')
          preview_limit = Math.min(text.indexOf('\n'), 15)
          text = text.slice(0, preview_limit) + ' (...)'
          markup = commentsOnLine.map(({author, message}) =>
             "![author.name](#{author.avatars[0].url}) **#{author.name}:**\n\n#{message}"
          ).join('\n\n')
          {
            icon: 'comment'
            severity: 'info'
            description: markup
            excerpt: text
            location:
              file: fileAbsolutePath
              position: [[position - 1, 0], [position - 1, lineLength]]
          }

        allMessages = allMessages.concat(lintWarningsOrNull.filter (lintWarning) -> !!lintWarning)
    @linter?.setAllMessages(allMessages)
