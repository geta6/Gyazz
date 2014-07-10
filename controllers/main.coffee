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

  #  / getdata() で呼ばれてJSONを返す
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

  app.get '/:wiki/:title/related', (req, res) ->
    debug 'Getting wiki/title/related'
    Pairs.related req.params.wiki, req.params.title, (err, result) ->
      debug "Getting related info===="
      if err
        return res.send
          error: 'An error has occurred'
      res.send result

  app.get '/:wiki/:title/attr', (req, res) ->
    Attrs.attr req.params.wiki, req.params.title, (err, result) ->
      debug "Getting related info===="
      if err
        return res.send
          error: 'An error has occurred'
      res.send result
