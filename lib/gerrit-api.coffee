rp = require 'request-promise'

module.exports = class GerritAPI
    constructor: (baseURL, user, password) ->
        @gerritURI = baseURL
        @user = user
        @password = password
        n1 = baseURL.indexOf('http://')
        n2 = baseURL.indexOf('https://')
        if (n1 >= 0 and @password.length > 0)
            @baseURL = 'http://' + @user + ':' + @password + '@' + @gerritURI.slice(7)
        else if (n2 >= 0 and @password? and @password.length > 0)
            @baseURL = 'https://' + @user + ':' + @password + '@' + @gerritURI.slice(8)
        else if (n1 < 0 and n2 < 0 and @password? and @password.length > 0)
            @baseURL = 'http://' + @user + ':' + @password + '@' + @gerritURI
        else
            @baseURL = @gerritURI
        if (@baseURL.endsWith('/'))
            @baseURL = @baseURL.slice(0,-1)

    _query: (queryURL) ->
        options = {
            uri: queryURL,
            transform: (body) ->
                return JSON.parse(body.slice(4, -1))
        }
        return rp(options)
            .catch((error) ->
                console.log(error))

    getComments: (reviewId, patchset) ->
        queryURL = @baseURL + '/changes/' + reviewId + '/revisions/' + patchset + '/comments/'
        return @_query(queryURL)

    _cleanVotes: (all) ->
        votes = {}
        for vote in all
            val = String(vote.value)
            votes[val] = (votes[val] || 0) + 1
        return votes

    getLabels: (reviewId, patchset) ->
        queryURL = @baseURL + '/changes/' + reviewId + '/revisions/' + patchset + '/review/'
        bURL = @gerritURI
        return @_query(queryURL).then((response) ->
            _labels = response.labels
            labels = {
                'labels': {'Code-Review': {}, 'Verified': {}, 'Workflow': {}},
                'uri': bURL + '/#/c/' + String(response._number) + '/'}
            for label in ['Code-Review', 'Verified', 'Workflow']
                _all = _labels[label].all
                for vote in _all
                    if (vote.value?)
                        val = ''
                        if (vote.value > 0)
                            val += '+'
                        val += String(vote.value)

                        if (not labels['labels'][label][val]?)
                            labels['labels'][label][val] = []
                        labels['labels'][label][val].push(vote.username)
            return labels
        )

    getReviewURI: (reviewId) ->
        queryURL = @baseURL + '/changes/' + reviewId
        bURL = @gerritURI
        return @_query(queryURL).then((response) ->
            bURL + '/#/c/' + String(response._number) + '/'
        )
