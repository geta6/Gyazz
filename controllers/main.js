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
      Pages.find({'wiki':wiki, 'title':title},{},{sort:{timestamp: -1},limit:1}, function(err, results){ // 最新のをひとつだけ取得
        if (err) {
          res.send({'error': 'An error has occurred'});
        } else {
          console.log('Success: Getting GyazzData-----');
          //res.render('index', { title: req.params.title });
          res.render('page', { title: title});
          console.log(results.length);
          console.log(results[0].timestamp);
          //console.log(results[results.length-1].timestamp);
          //res.render('index', { title: 'xxxx'});
        }
      });
    });
    
    app.get('/:wiki/:title/json',function(req, res) {
      console.log('Getting wiki/title/json');
      wiki = req.params.wiki;
      title = req.params.title;
      
      // var url_parts = url.parse(req.url,true);
      // console.log(url_parts.query);
      console.log(req.query); // suggest, version

      Pages.latest({'wiki':wiki, 'title':title}, function(err,results){
        if (err) {
          res.send({'error': 'An error has occurred'});
        } else {
          res.send({
            'date': '20140101010101',
            'age': results[0].timestamp,
            'data': results[0].text.split(/\n/)
          });
        }
      });
    });
  };
}).call(this);
