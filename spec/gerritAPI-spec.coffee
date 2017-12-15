GerritAPI = require '../lib/gerrit-api'


describe "Test GerritAPI class", ->
    it "should set authentication in the base URL when a user and password are provided (http)", ->
        gapi = new GerritAPI('http://fakegerrit/', 'user1', 'password1')
        expect(gapi.user).toEqual('user1')
        expect(gapi.password).toEqual('password1')
        expect(gapi.baseURL).toEqual('http://user1:password1@fakegerrit')

    it "should set authentication in the base URL when a user and password are provided (https)", ->
        gapi = new GerritAPI('https://fakegerrit/', 'user1', 'password1')
        expect(gapi.user).toEqual('user1')
        expect(gapi.password).toEqual('password1')
        expect(gapi.baseURL).toEqual('https://user1:password1@fakegerrit')

    it "should use an unauthenticated base URL if user, password are not provided", ->
        gapi = new GerritAPI('https://fakegerrit', null, null)
        expect(gapi.user).toBe(null)
        expect(gapi.password).toBe(null)
        expect(gapi.baseURL).toEqual('https://fakegerrit')

    it "should call the correct comments URL", ->
        spy = spyOn(GerritAPI.prototype, "_query")
        gapi = new GerritAPI('https://fakegerrit', null, null)
        gapi.getComments('Ideadbeef123', 'baddad321')
        expect(spy).toHaveBeenCalledWith('https://fakegerrit/changes/Ideadbeef123/revisions/baddad321/comments/')
