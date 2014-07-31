#
# socket.ioを利用したデータ読み書き (サーバ側)
#

debug    = require('debug')('gyazz:sockets:readwrite')
mongoose = require 'mongoose'

Pages  = mongoose.model 'Page'
Lines  = mongoose.model 'Line'
Pairs  = mongoose.model 'Pair'

module.exports = (app) ->
  io = app.get 'socket.io'

  writetime = {}

  _busy = false

  io.on 'connection', (socket) ->
    debug "socket.io connected from client--------"

    ## 同じページを見ているクライアント毎にroomで分ける
    room = "#{socket.handshake.query.wiki}/#{socket.handshake.query.title}"
    socket.join room
    socket.once 'disconnect', ->
      socket.leave room

    socket.on 'read', (req) ->
      return if _busy && ! req.opts.force
      _busy = true
      debug "readwrite.coffee: #{req.wiki}::#{req.title} read request from client"
      Pages.findByName req.wiki, req.title, req.opts, (err, page) ->
        if err
          debug "Pages error"
          return
        data =  page?.text.split(/\n/) or []
        # 行ごとの古さを計算する
        Lines.timestamps req.wiki, req.title, data, (err, timestamps) ->
          debug "readwrite.coffee: send data back to client"
          # io.sockets.emit 'pagedata', { # 自分を含むあらゆる接続先にデータ送信
          socket.emit 'pagedata', { # 自分だけに返信
            wiki:        req.wiki
            title:       req.title
            date:        page?.timestamp
            timestamps:  timestamps
            data:        data
          }
          _busy = false

    # write処理時にリンク情報を更新する必要あり
    # データはgyazz_related.coffeeで使っている
    # pair.coffee でDBから取得している
    #
    socket.on 'write', (req) ->
      debug "readwrite.coffee: #{req.wiki}::#{req.title} write request from client"
      wiki     = req.wiki
      title    = req.title
      text     = req.data
      keywords = req.keywords
      curtime = new Date
      lasttime = writetime["#{wiki}::#{title}"]
      # console.log "Write! data=#{text}"
      if !lasttime || curtime > lasttime
        writetime["#{wiki}::#{title}"] = curtime

        Pairs.refresh wiki, title, keywords # リンク情報登録
        
        page = new Pages
        page.wiki      = wiki
        page.title     = title
        page.text      = text
        page.timestamp = curtime
        page.save (err) ->
          if err
            debug "Write error: #{err}"
            return

          socket.emit 'writesuccess' # クライアントだけに返す
          
          data = text.split(/\n/) or []
          Lines.timestamps wiki, title, data, (err, timestamps) ->
            debug "readwrite.coffee: send data back to client"
            io.sockets.to(room).emit 'pagedata', { # 同じページを見ている相手に送信
              wiki:        wiki
              title:       title
              date:        curtime
              timestamps:  timestamps
              data:        data
            }
            
          text.split(/\n/).forEach (linetext) -> # 新しい行ならば生成時刻を記録する
            Lines.find
              wiki:  wiki
              title: title
              line:  linetext
            .exec (err, results) ->
              if err
                debug "line read error"
                return
              if results.length == 0
                line = new Lines
                line.wiki      = wiki
                line.title     = title
                line.line      = linetext
                line.timestamp = curtime
                line.save (err) ->
                  if err
                    debug "line write error"
