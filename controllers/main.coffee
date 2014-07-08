#
# メインコントローラモジュール
#

mongoose = require('mongoose');

Pages = mongoose.model('Pages');

module.exports = (app) ->
  app.get '/', (req, res) ->
    res.render 'index',
      title: 'Express'

  app.get '/:wiki/:title', (req, res) ->
    console.log 'Getting wiki/title-------------'
    wiki = req.params.wiki
    title = req.params.title
    console.log "wiki = #{wiki}"
    console.log "title = #{title}"
    Pages.latest {'wiki':wiki, 'title':title}, (err,result) ->
      if err
        res.send {'error': 'An error has occurred'}
      else
        console.log 'Success: Getting GyazzData-----'
	# result.related wiki,title
        #  Pages.related(wiki,title) でも同じか?
        res.render 'page', { title: title, wiki:wiki}
        console.log result.timestamp

  #  / getdata() で呼ばれてJSONを返す
  app.get '/:wiki/:title/json', (req, res) ->
    console.log 'Getting wiki/title/json'
    wiki = req.params.wiki
    title = req.params.title
    
    console.log req.query # suggest, version
    Pages.latest {'wiki':wiki, 'title':title}, (err,result) ->
      if (err)
        res.send {'error': 'An error has occurred'}
      else
        res.send
          'date': '20140101010101',
          'age': result.timestamp,
          'data': result.text.split(/\n/)
