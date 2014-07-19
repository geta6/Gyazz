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

module.exports = (app) ->
  app.get '/', (req, res) ->
    return res.render 'index',
      title: 'Express'

  # 普通にページアクセス
  app.get '/:wiki/:title', (req, res) ->
    debug "Get: wiki = #{req.params.wiki}, title=#{req.params.title}"
    return res.render 'page',
      title: req.params.title
      wiki:  req.params.wiki

  # 代表アイコン画像
  app.get '/:wiki/:title/icon', (req, res) ->
    debug "Getting #{req.params.wiki}/#{req.params.title}/icon"
    Attrs.attr req.params.wiki, req.params.title, (err, result) ->
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

  #  ページ内容取得
  app.get '/:wiki/:title/json', (req, res) ->
    debug "Getting #{req.params.wiki}/#{req.params.title}/json"
    debug JSON.stringify req.query # { suggest, version, age }
    Pages.json req.params.wiki, req.params.title, req.query, (err, page) ->
      if err
        return res.send
          error: 'An error has occurred'
      data =  page?.text.split(/\n/) or []
      # 行ごとの古さを計算する
      Lines.timestamps req.params.wiki, req.params.title, data, (err, timestamps) ->
        # データ返信
        res.send
          date: page?.timestamp
          age: timestamps
          data: data

  # repimageなどのページ属性
  app.get '/:wiki/:title/attr', (req, res) ->
    Attrs.attr req.params.wiki, req.params.title, (err, result) ->
      debug "Getting related info===="
      if err
        return res.send
          error: 'An error has occurred'
      res.send result

  # 関連ページの配列 repimageも一緒に返す
  app.get '/:wiki/:title/related', (req, res) ->
    debug 'Getting wiki/title/related2'
    Pairs.related req.params.wiki, req.params.title, (err, titles) ->
      debug "Getting related info===="
      if err
        return res.send
          error: 'An error has occurred'
      repimage = {}
      repimages = 0
      for title in titles
        Attrs.find
          wiki:  req.params.wiki
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
  app.get '/:wiki/:title/modify.png', (req, res) ->
    debug "modify: wiki = #{req.params.wiki}, title=#{req.params.title}"

    Pages.access req.params.wiki, req.params.title, (err, data) ->
      png = new PNG
      png.png data, (pngres) ->
        res.set('Content-Type', 'image/png')
        res.send pngres

  # データ書込み
  app.post '/__write', (req, res) ->
    debug "__write: "
    newpage = new Pages
    newpage.wiki = req.body.name
    newpage.title = req.body.title
    newpage.text = req.body.data
    newpage.timestamp = new Date
    newpage.save (err) ->
      if err
        debug "Write error"
      res.send "noconflict"
    
  # ページリスト
  app.get '/:wiki', (req, res) ->
    debug "Get: wiki = #{req.params.wiki}"

    list = Pages.mlist req.params.wiki, (err, list) ->
      res.render 'search',
        wiki:  req.params.wiki
        q:     ''
        pages: list
