#
# メインコントローラモジュール
#

debug    = require('debug')('gyazz:main')
mongoose = require 'mongoose'
PNG      = require '../lib/png'

Pages  = mongoose.model 'Page'
Pairs  = mongoose.model 'Pair'
Attrs  = mongoose.model 'Attr'
Access = mongoose.model 'Access'
Lines  = mongoose.model 'Line'

writetime = {}

module.exports = (app) ->
  app.get '/', (req, res) ->
    return res.render 'index',
      title: 'Express'

  app.get /^\/([^\/]+)\/(.*)\/__edit$/, (req, res) ->
    wiki  = req.params[0]
    title = req.params[1]
    return res.render 'edit',
      title:   title
      wiki:    wiki
      version: req.query.version

  # 代表アイコン画像
  app.get /^\/([^\/]+)\/(.*)\/icon$/, (req, res) ->
    wiki  = req.params[0]
    title = req.params[1]
    debug "Getting #{wiki}/#{title}/icon"
    Attrs.attr wiki, title, (err, result) ->
      if err
        return res.send
          error: 'icon: An error has occurred'
      image = result.repimage
      if image
        if image.match /^https?:\/\/.+\.(png|jpe?g|gif)$/i
          res.redirect image
        else
          res.redirect "http://gyazo.com/#{image}.png"
      else
        res.send 404, "image not found"

  #  ページ内容取得 (apiとしてだけ)用意
  app.get /^\/([^\/]+)\/(.*)\/json$/, (req, res) ->
    wiki  = req.params[0]
    title = req.params[1]
    debug "Getting #{wiki}/#{title}/json"
    debug JSON.stringify req.query # { suggest, version, age }
    Pages.json wiki, title, req.query, (err, page) ->
      if err
        return res.send
          error: 'An error has occurred'
      data =  page?.text.split(/\n/) or []
      # 行ごとの古さを計算する
      Lines.timestamps wiki, title, data, (err, timestamps) ->
        # データ返信
        res.send
          date:        page?.timestamp
          timestamps:  timestamps
          data:        data

  # repimageなどのページ属性
  app.get /^\/([^\/]+)\/(.*)\/attr$/, (req, res) ->
    wiki  = req.params[0]
    title = req.params[1]
    Attrs.attr wiki, title, (err, result) ->
      debug "Getting related info===="
      if err
        return res.send
          error: 'An error has occurred'
      res.send result

  # 関連ページの配列 repimageも一緒に返す
  app.get /^\/([^\/]+)\/(.*)\/related$/, (req, res) ->
    wiki  = req.params[0]
    title = req.params[1]
    debug 'Getting wiki/title/related2'
    Pairs.related wiki, title, (err, titles) ->
      debug "Getting related info===="
      if err
        return res.send
          error: 'An error has occurred'
      repimage = {}
      repimages = 0
      for title in titles
        Attrs.find
          wiki:  wiki
          title: title
        .exec (err, results) ->
          if err
            return res.send
              error: 'An error has occured'
          result = results[0] || {}
          attr = result['attr'] || {}
          title = result['title']  # title ではダメ!!!!!!!!!
          repimage[title] = attr.repimage
          repimages += 1
          if repimages == titles.length
            result = []
            for title2 in titles
              result.push
                title: title2
                repimage: repimage[title2]
            debug result.length
            res.send result

  # ページ変更履歴とアクセス履歴からPNGを生成する
  app.get /^\/([^\/]+)\/(.*)\/modify.png$/, (req, res) ->
    wiki  = req.params[0]
    title = req.params[1]
    debug "modify: wiki = #{wiki}, title=#{title}"

    Pages.access wiki, title, (err, data) ->
      png = new PNG
      png.png data, (pngres) ->
        res.set('Content-Type', 'image/png')
        res.send pngres

  # 普通にページアクセス
  app.get /^\/([^\/]+)\/(.+)$/, (req, res) ->
    wiki  = req.params[0]
    title = req.params[1]
    debug "Get: wiki = #{wiki}, title=#{title}"
    # アクセス記録
    Access.update
      wiki:      wiki
      title:     title
      timestamp: new Date
    , (err) ->
      if err
        debug "Access write error"
      return res.render 'page',
        title: title
        wiki:  wiki

  # データ書込み (apiとしてだけ用意)
  app.post '/__write', (req, res) ->
    debug "__write: "
    wiki  = req.body.name
    title = req.body.title
    text  = req.body.data
    curtime = new Date
    lasttime = writetime["#{wiki}::#{title}"]
    if !lasttime || curtime > lasttime
      writetime["#{wiki}::#{title}"] = curtime
      Pages.update
        wiki:      wiki
        title:     title
        text:      text
        timestamp: curtime
      , (err) ->
        if err
          debug "Write error"
        res.send "noconflict"
        text.split(/\n/).forEach (line) -> # 新しい行ならば生成時刻を記録する
          Lines.find
            wiki:  wiki
            title: title
            line:  line
          .exec (err, results) ->
            if err
              debug "line read error"
            if results.length == 0
              Lines.update
                wiki:      wiki
                title:     title
                line:      line
                timestamp: curtime
              , (err) ->
                if err
                  debug "line write error"
    
  # ページリスト
  app.get '/:wiki/', (req, res) ->
    wiki = req.params.wiki
    debug "Get: wiki = #{wiki}"

    Pages.alist req.params.wiki, (err, list) ->
      res.render 'search',
        wiki:  req.params.wiki
        q:     ''
        pages: list
        

