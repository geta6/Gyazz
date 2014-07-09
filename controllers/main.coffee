#
# メインコントローラモジュール
#

debug = require('debug')('gyazz:main')
mongoose = require 'mongoose'

Pages = mongoose.model 'Pages'
Pairs = mongoose.model 'Pairs'
Attrs = mongoose.model 'Attrs'

module.exports = (app) ->
  app.get '/', (req, res) ->
    res.render 'index',
      title: 'Express'

  app.get '/:wiki/:title', (req, res) ->
    wiki = req.params.wiki
    title = req.params.title
    debug "Getting /wiki/title: wiki = #{wiki}, title=#{title}"

    res.render 'page',
      title: req.params.title
      wiki:  req.params.wiki
     
  #  / getdata() で呼ばれてJSONを返す
  app.get '/:wiki/:title/json', (req, res) ->
    debug 'Getting wiki/title/json'
    wiki = req.params.wiki
    title = req.params.title
    
    debug req.query # { suggest, version }
    Pages.latest wiki, title, (err,result) ->
      if err
        res.send
          error: 'An error has occurred'
      else
        res.send
          date: '20140101010101'
          age: result.timestamp
          data: result.text.split(/\n/)

  app.get '/:wiki/:title/related', (req, res) ->
    #debug 'Getting wiki/title/related'
    wiki = req.params.wiki
    title = req.params.title
    
    Pairs.related wiki, title, (err,result) ->
      #debug "Getting related info===="
      if err
        res.send
          error: 'An error has occurred'
      else
        res.send result

  app.get '/:wiki/:title/repimage', (req, res) ->
    Attrs.repimage req.params.wiki, req.params.title, (err, result) ->
      res.send
        repimage: result



