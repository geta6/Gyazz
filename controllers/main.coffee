#
# メインコントローラモジュール
#

debug    = require('debug')('gyazz:main')
mongoose = require 'mongoose'

Pages = mongoose.model 'Page'
Pairs = mongoose.model 'Pair'
Attrs = mongoose.model 'Attr'

module.exports = (app) ->
  app.get '/', (req, res) ->
    return res.render 'index',
      title: 'Express'

  app.get '/:wiki/:title', (req, res) ->
    debug "Getting /wiki/title: wiki = #{req.params.wiki}, title=#{req.params.title}"

    return res.render 'page',
      title: req.params.title
      wiki:  req.params.wiki

  #  ページ内容
  app.get '/:wiki/:title/json', (req, res) ->
    debug 'Getting wiki/title/json'
    debug JSON.stringify req.query # { suggest, version }
    Pages.latest req.params.wiki, req.params.title, (err, page) ->
      if err
        return res.send
          error: 'An error has occurred'
      res.send
        date: '20140101010101'
        age: page?.timestamp
        data: page?.text.split(/\n/) or []

  # 関連ページの配列
  app.get '/:wiki/:title/related', (req, res) ->
    debug 'Getting wiki/title/related'
    Pairs.related req.params.wiki, req.params.title, (err, result) ->
      debug "Getting related info===="
      if err
        return res.send
          error: 'An error has occurred'
      res.send result

  # repimageなどのページ属性
  app.get '/:wiki/:title/attr', (req, res) ->
    Attrs.attr req.params.wiki, req.params.title, (err, result) ->
      debug "Getting related info===="
      if err
        return res.send
          error: 'An error has occurred'
      res.send result

  # 関連ページの配列 repimageも含める
  app.get '/:wiki/:title/related2', (req, res) ->
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
