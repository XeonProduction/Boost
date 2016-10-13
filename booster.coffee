_            = require 'lodash'
jsonfile     = require 'jsonfile'
moment       = require 'moment'
Promise      = require 'bluebird'
SteamAccount = require './steamaccount.coffee'

try
  database = jsonfile.readFileSync 'database.json'
catch e
  console.log "Error reading database.json!"
  process.exit 0

pad = 24 + _.maxBy(_.keys(database), 'length').length
accounts = _.map database, ({password, sentry, secret, games}, name) ->
  new SteamAccount name, password, sentry, secret, games, pad

restarting  = ->
  console.log 'Your boost has started'
  Promise.map accounts, _.method 'restarting'
  .delay 1800000
  .finally restarting

console.log 'Your boost has started'
Promise.map accounts, _.method 'starting'
.delay 1750000
.then restartBoost
