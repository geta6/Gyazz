debug    = require('debug')('readwrite:sockets')

module.exports = (app) ->
  io = app.get 'socket.io'

  io.on 'connection', (socket) ->
    console.log "socket.io connected from client--------"
    socket.on 'page update', (msg) ->
      console.log "message from client"
      console.log "  wiki = #{msg.wiki}"
      console.log "  title = #{msg.title}"
      console.log "  date = #{msg.date}"
      io.sockets.emit 'gyazz update notification', # broadcast
        wiki:  msg.wiki
        title: msg.title
        text:  "Gyazz page #{msg.wiki}::#{msg.title} updated!!"
        
      # socket.emit 'chat message', 'REPLY MESSAGE' # 個別に返す場合
      # socket.broadcast.emit 'msg push', "BROADCAST MESSAGE"

    socket.on 'disconnect', ->
      console.log 'disconnected'

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
