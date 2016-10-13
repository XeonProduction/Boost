S            = require 'string'
SteamUser    = require 'steam-user'
SteamTotp    = require 'steam-totp'
Promise      = require 'bluebird'
moment       = require 'moment'
EventEmitter = require 'events'

module.exports = class SteamAccount extends EventEmitter
  constructor: (@name, @password, @sentry, @secret, @games, @indent=0) ->
    options =
      promptSteamGuardCode: false
      dataDirectory: null
    @client = new SteamUser null, options
    @client.setSentry Buffer.from(@sentry, 'base64') if @sentry
    @client.on 'error', (err) => @emit 'clientError', err
    @client.on 'steamGuard', => @emit 'clientSteamGuard'
    @client.once 'steamGuard', => @steamGuardRequested = true

  logheader: =>
    S "[#{moment().format('DD-MM-YYYY HH:mm:ss')} - #{@name}]"
    .padRight @indent
    .s

  error: (err) =>
    @emit 'customError', err

  login: =>
    return Promise.resolve() if @client.client.loggedOn
    if @steamGuardRequested and not @secret
      return Promise.reject "Steamguard is requested!"

    new Promise (resolve, reject) =>
      @once 'clientError', reject
      @once 'clientSteamGuard', -> reject "Steam guard requested!"
      @client.once 'loggedOn', resolve
      if @secret
        SteamTotp.getAuthCode @secret, (err, code) =>
          @client.logOn accountName: @name, password: @password, twoFactorCode: code
      else
        @client.logOn accountName: @name, password: @password
    .timeout 2000
    .catch Promise.TimeoutError, ->
      Promise.reject "Timed out while login"
    .finally =>
      @removeAllListeners 'clientError'
      @removeAllListeners 'clientSteamGuard'
      @client.removeAllListeners 'loggedOn'

  logoff: =>
    return if not @client.client.loggedOn
    @client.gamesPlayed [730]
    @client.logOff()

  starting: =>
    @login()
    .then =>
      @client.setPersona SteamUser.EPersonaState.Online
      @client.gamesPlayed @games ? [730]
      console.log "#{@logheader()} If u love Xeon then your game will be boosted"
    .catch (err) => console.error "#{@logheader()} #{err}"

  restarting: =>
    @client.gamesPlayed [730]
    Promise.delay('510000').then @starting
