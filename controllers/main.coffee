#
# メインコントローラモジュール
#

debug    = require('debug')('gyazz:main')
mongoose = require 'mongoose'

Pages = mongoose.model 'Pages'
Pairs = mongoose.model 'Pairs'

module.exports = (app) ->
  app.get '/', (req, res) ->
    return res.render 'index',
      title: 'Express'

  app.get '/:wiki/:title', (req, res) ->
    wiki = req.params.wiki
    title = req.params.title
    debug "Getting /wiki/title: wiki = #{wiki}, title=#{title}"

    return res.render 'page',
      title: req.params.title
      wiki:  req.params.wiki
     
#    Pages.latest {'wiki':wiki, 'title':title}, (err,result) ->
#      if err
#        res.send
#          'error': 'An error has occurred'
#      else
#        debug 'Success: Getting GyazzData-----'
#        result.related (dummy) ->
#          debug 'kkkkkkkkkkkkkkkkkkkkk'
#
#       	# result.related wiki,title
#        #  Pages.related(wiki,title) でも同じか?
#
#      res.render 'page',
#        title: title
#        wiki:  wiki
#
#      debug result.timestamp

  #  / getdata() で呼ばれてJSONを返す
  app.get '/:wiki/:title/json', (req, res) ->
    debug 'Getting wiki/title/json'
    wiki = req.params.wiki
    title = req.params.title
    
    debug JSON.stringify req.query # { suggest, version }
    Pages.latest wiki, title, (err, page) ->
      if err
        return res.send
          error: 'An error has occurred'
      return res.send
        date: '20140101010101'
        age: page?.timestamp
        data: page?.text.split(/\n/) or []

  app.get '/:wiki/:title/related', (req, res) ->
    debug 'Getting wiki/title/related'
    wiki = req.params.wiki
    title = req.params.title
    
    Pairs.related wiki, title, (err,result) ->
      debug "Getting related info===="
      if err
        return res.send
          error: 'An error has occurred'
      return res.send
        date: '20140101xxxxxx'



