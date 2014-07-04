//
// メインコントローラモジュール
//
(function() {
  var Pages, debug, mongoose;

  mongoose = require('mongoose');

  Pages = mongoose.model('Pages');

  module.exports = function(app) {
    app.get('/', function(req, res) {
      res.render('index', { title: 'Express' });
    });

    app.get('/:wiki/:title',function(req, res) {
      console.log('Getting wiki/title-------------');
      wiki = req.params.wiki;
      title = req.params.title;
      console.log("wiki= " + wiki);
      console.log("title= " + title);
      Pages.latest({'wiki':wiki, 'title':title}, function(err,result){
        if (err) {
          res.send({'error': 'An error has occurred'});
        } else {
          console.log('Success: Getting GyazzData-----');
          //res.render('index', { title: req.params.title });
          res.render('page', { title: title});
          console.log(result.timestamp);
        }
      });
    });
    
    // getdata() で呼ばれてJSONを返す
    app.get('/:wiki/:title/json',function(req, res) {
      console.log('Getting wiki/title/json');
      wiki = req.params.wiki;
      title = req.params.title;
      
      // var url_parts = url.parse(req.url,true);
      // console.log(url_parts.query);
      console.log(req.query); // suggest, version

      Pages.latest({'wiki':wiki, 'title':title}, function(err,result){
        if (err) {
          res.send({'error': 'An error has occurred'});
        } else {
          res.send({
            'date': '20140101010101',
            'age': result.timestamp,
            'data': result.text.split(/\n/)
          });
        }
      });
    });
  };
}).call(this);
