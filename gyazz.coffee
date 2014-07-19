#
# ExpressによるGyazzサーバのメインプログラム
#

express  = require 'express'
mongoose = require 'mongoose'
path     = require 'path'
debug    = require('debug')('gyazz:app')

bodyParser = require 'body-parser' # POSTに必要?

## Config
process.env.PORT ||= 3000


module.exports = app = express()

# public以下のファイルはWikiデータとみなさないようにする
app.use express.static path.resolve 'public'
app.set 'view engine', 'jade'
app.locals.pretty = true       # jade出力を整形する

# Express 3.xだとこういう感じだったとか?
# http://blackpresent.blog.fc2.com/blog-entry-20.html
# postデータを扱う際のおまじない ----
# app.use(express.bodyDecoder());//これだめ名称古い。
# app.use(express.bodyParser());//これももう使われない。
# app.use express.urlencoded()
# app.use express.json()

# Express 4.xだとこうなったとか?
# http://stackoverflow.com/questions/5710358/
# https://github.com/expressjs/body-parser
app.use bodyParser.json()
app.use bodyParser.urlencoded()

## load controllers, models, socket.io ##
components =
  models:      [ 'access', 'pair', 'page', 'attr', 'line' ]
  controllers: [ 'main' ]
  lib:         [ 'png' ]
  sockets:     [ ]

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

  app.listen process.env.PORT
  console.log "Listening on port #{process.env.PORT}..."
