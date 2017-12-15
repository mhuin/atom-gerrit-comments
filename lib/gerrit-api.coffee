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
