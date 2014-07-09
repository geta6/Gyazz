#
# ExpressによるGyazzサーバのメインプログラム
#

express = require 'express'
path = require 'path'
debug = require('debug')('gyazz:app')

app = express()

# public以下のファイルはWikiデータとみなさないようにする
app.use express['static'] path.resolve('public')

# views/*.ejs を利用
app.set 'view engine', 'ejs'

pair = (require path.resolve 'models','pair')(app)
page = (require path.resolve 'models','page')(app)
main = (require path.resolve 'controllers','main')(app)

mongoose = require 'mongoose'
mongoose.connect 'mongodb://localhost/gyazz', (err) ->
  if err
    debug "mongoose connect failed"
    debug err
    process.exit 1
    return
  debug "connect MongoDB"

app.listen 3000
console.log 'Listening on port 3000...'

