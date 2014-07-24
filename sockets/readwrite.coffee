debug    = require('debug')('readwrite:sockets')
mongoose = require 'mongoose'

Pages  = mongoose.model 'Page'
Lines  = mongoose.model 'Line'

module.exports = (app) ->
  io = app.get 'socket.io'

  io.on 'connection', (socket) ->
    console.log "socket.io connected from client--------"

    socket.on 'read', (req) ->
      console.log "readwrite.coffee: #{req.wiki}::#{req.title} read request from client"
      Pages.json req.wiki, req.title, req.opts, (err, page) ->
        if err
          console.log "Pages error"
          return
        data =  page?.text.split(/\n/) or []
        # 行ごとの古さを計算する
        Lines.timestamps req.wiki, req.title, data, (err, timestamps) ->
          # データ返信
          console.log "readwrite.coffee: send data back to client"
          io.sockets.emit 'pagedata', {
            date:        page?.timestamp
            timestamps:  timestamps
            data:        data
          }


    #socket.on 'page update', (msg) ->
    #  console.log "message from client"
    #  console.log "  wiki = #{msg.wiki}"
    #  console.log "  title = #{msg.title}"
    #  console.log "  date = #{msg.date}"
    #  io.sockets.emit 'gyazz update notification', # broadcast
    #    wiki:  msg.wiki
    #    title: msg.title
    #    text:  "Gyazz page #{msg.wiki}::#{msg.title} updated!!"
    #    
    #  # socket.emit 'chat message', 'REPLY MESSAGE' # 個別に返す場合
    #  # socket.broadcast.emit 'msg push', "BROADCAST MESSAGE"

    #socket.on 'disconnect', ->
    #  console.log 'disconnected'

#   io.on 'connection', (socket) ->
#    debug 'new connection'
#
#    socket.on 'chat', (data) ->
#      debug data
#      message = new Message data
#      message.save (err) ->
#        debug err if err
#      io.sockets.emit 'chat', data  # broadcast
#      return
#
#    io.sockets.emit 'chat', {
#      from: "server"
#      body: "hello new client (id:#{socket.id})"
#    }
