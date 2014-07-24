debug    = require('debug')('readwrite:sockets')
mongoose = require 'mongoose'

Pages  = mongoose.model 'Page'
Lines  = mongoose.model 'Line'

module.exports = (app) ->
  io = app.get 'socket.io'

  writetime = {}

  io.on 'connection', (socket) ->
    debug "socket.io connected from client--------"
    socket.on 'read', (req) ->
      debug "readwrite.coffee: #{req.wiki}::#{req.title} read request from client"
      Pages.json req.wiki, req.title, req.opts, (err, page) ->
        if err
          debug "Pages error"
          return
        data =  page?.text.split(/\n/) or []
        # 行ごとの古さを計算する
        Lines.timestamps req.wiki, req.title, data, (err, timestamps) ->
          debug "readwrite.coffee: send data back to client"
          io.sockets.emit 'pagedata', { # 自分を含むあらゆる接続先にデータ送信
            wiki:        req.wiki
            title:       req.title
            date:        page?.timestamp
            timestamps:  timestamps
            data:        data
          }

    socket.on 'write', (req) ->
      debug "readwrite.coffee: #{req.wiki}::#{req.title} write request from client"
      wiki  = req.wiki
      title = req.title
      text  = req.data
      curtime = new Date
      lasttime = writetime["#{wiki}::#{title}"]
      if !lasttime || curtime > lasttime
        writetime["#{wiki}::#{title}"] = curtime
        newpage = new Pages
        newpage.wiki      = wiki
        newpage.title     = title
        newpage.text      = text
        newpage.timestamp = curtime
        newpage.save (err) ->
          if err
            debug "Write error"

          data = text.split(/\n/) or []
          Lines.timestamps wiki, title, data, (err, timestamps) ->
            debug "readwrite.coffee: send data back to client"
            socket.broadcast.emit 'pagedata', { # 自分以外のあらゆる接続先にデータ送信
              wiki:        wiki
              title:       title
              date:        curtime
              timestamps:  timestamps
              data:        data
            }
            
          text.split(/\n/).forEach (line) -> # 新しい行ならば生成時刻を記録する
            Lines.find
              wiki:  wiki
              title: title
              line:  line
            .exec (err, results) ->
              if err
                debug "line read error"
              if results.length == 0
                newline = new Lines
                newline.wiki      = wiki
                newline.title     = title
                newline.line      = line
                newline.timestamp = curtime
                newline.save (err) ->
                  if err
                    debug "line write error"
