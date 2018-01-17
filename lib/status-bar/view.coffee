{View, $} = require 'atom-space-pen-views'
_ = require 'underscore-plus'
{CompositeDisposable} = require 'atom'

subscriptions = new CompositeDisposable

module.exports =

class GerritStatusBarView extends View

  @content: () ->
    c = "gerrit-review-statusbar"
    title = "Click to open review."
    href = "https://gerrit-review.googlesource.com/q/status:open"
    @a class: "#{c} reviewlink", title: title, href: href, =>
      @div class: "#{c} inline-block code-review", =>
        @span " "
        @span "cr", class: "#{c} codereview-score", outlet: "codeReviewScore"
      @div class: "#{c} inline-block verified", =>
        @span " "
        @span "v", class: "#{c} verified-score", outlet: "verifiedScore"
      @div class: "#{c} inline-block workflow", =>
        @span " "
        @span "w", class: "#{c} workflow-score", outlet: "workflowScore"

  setReviewURI: (reviewURI, reviewInfo) ->
    el = document.querySelector(".gerrit-review-statusbar.reviewlink")
    $(el).attr("href", reviewURI)
    @reviewInfo.text reviewInfo

  setCounters: (crScores, verifiedScores, workflowScores) ->
    cs = 'CR '
    cs_tooltip = ''
    for score in _.keys(crScores).sort().reverse()
      if (crScores[score].length > 0)
        cs += score + ': ' + String(crScores[score].length) + '/'
        cs_tooltip += '<b>' + score + ':</b> ' + crScores[score].join(' ') + '\n'
    if (cs == 'CR ')
        cs = 'CR -'
        cs_tooltip = 'No reviews yet :('
    else
        cs = cs.slice(0,-1)
        cs_tooltip = cs_tooltip.slice(0,-1)
    @codeReviewScore.text cs
    subscriptions.add atom.tooltips.add(@codeReviewScore, {title: cs_tooltip})
    vs = 'V '
    vs_tooltip = ''
    for score in _.keys(verifiedScores).sort().reverse()
      if (verifiedScores[score].length > 0 and score != "0")
        vs += score + ': ' + String(verifiedScores[score].length) + '/'
        vs_tooltip += '<b>' + score + ':</b> ' + verifiedScores[score].join(' ') + ', '
    if (vs == 'V ')
        vs = 'V -'
        vs_tooltip = 'No CI result yet :('
    else
        vs = vs.slice(0,-1)
        vs_tooltip = vs_tooltip.slice(0,-2)
    @verifiedScore.text vs
    subscriptions.add atom.tooltips.add(@verifiedScore, {title: vs_tooltip})
    ws = 'W '
    ws_tooltip = ''
    for score in _.keys(workflowScores).sort().reverse()
      if (workflowScores[score].length > 0 and score != "0")
        ws += score + ': ' + String(workflowScores[score].length) + '/'
        ws_tooltip += '<b>' + score + ':</b> ' + workflowScores[score].join(' ') + ', '
    if (ws == 'W ')
        ws = 'W -'
        ws_tooltip = 'No workflow yet :('
    else
        ws = ws.slice(0,-1)
        ws_tooltip = ws_tooltip.slice(0,-2)
    @workflowScore.text ws
    subscriptions.add atom.tooltips.add(@workflowScore, {title: ws_tooltip})
