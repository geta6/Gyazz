#
# ExpressによるGyazzサーバのメインプログラム
#

express  = require 'express'
mongoose = require 'mongoose'
path     = require 'path'
debug    = require('debug')('gyazz:app')

## express modules
bodyParser = require 'body-parser' # POSTに必要?

## Config
package_json = require path.resolve 'package.json'
process.env.PORT ||= 3000

## server setup ##
module.exports = app = express()
app.use express.static path.resolve 'public'  # public以下のファイルはWikiデータとみなさないようにする
app.set 'view engine', 'jade'
app.locals.pretty = true                      # jade出力を整形する
app.use bodyParser.json()
app.use bodyParser.urlencoded()

http = require('http').Server(app)            # socket.io 対応
io = require('socket.io')(http)
app.set 'socket.io', io
app.set 'package', package_json

## load controllers, models, socket.io ##
components =
  models:      [ 'access', 'pair', 'page', 'attr', 'line' ]
  controllers: [ 'main' ]
  lib:         [ 'png' ]
  sockets:     [ 'readwrite' ]

for type, items of components
  for item in items
    debug "load #{type}/#{item}"
    require(path.resolve type, item)(app)

mongodb_uri = process.env.MONGOLAB_URI or
              process.env.MONGOHQ_URL or
              'mongodb://localhost/gyazz'

mongoose.connect mongodb_uri, (err) ->
  if err
    debug "mongoose connect failed"
    debug err
    process.exit 1
    return
  debug "connect MongoDB"

  http.listen process.env.PORT, ->
    console.log "listening on *:#{process.env.PORT}..."

