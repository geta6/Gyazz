var express = require('express');
var path = require('path');

// var url = require('url');

// var router = express.Router();

var app = express();

// public以下のファイルはWikiデータとみなさないようにする
app.use(express.static(__dirname + '/public'));

// view engine setup
app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'ejs');

// // router.get('/', function(req, res) {
app.get('/', function(req, res) {
  res.render('index', { title: 'Express' });
});

app.get('/:wiki/:title',function(req, res) {
  console.log('Getting wiki/title');
  wiki = req.params.wiki;
  title = req.params.title;
  console.log("wiki= " + wiki);
  console.log("title= " + title);
  //Gyazz.find({wiki:req.params.wiki, title:req.params.title}, function(err, results) {
  //Gyazz.find({'title':title}, function(err, results) {
  Gyazz.find({'wiki':wiki, 'title':title},{},{sort:{timestamp: -1},limit:1}, function(err, results){ // 最新のをひとつだけ取得
    if (err) {
      res.send({'error': 'An error has occurred'});
    } else {
      console.log('Success: Getting GyazzData');
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
  console.log(req.query);

  Gyazz.find({'wiki':wiki, 'title':title},{},{sort:{timestamp: -1},limit:1}, function(err, results){ // 最新のをひとつだけ取得
    if (err) {
      res.send({'error': 'An error has occurred'});
    } else {
      // console.log(results[0].text);
      data = {};
      data['date'] = '20140101010101';
      data['age'] = results[0].timestamp;
      data['data'] = results[0].text.split(/\n/);
      res.send(JSON.stringify(data));

      // res.render('index', { title: results.length});
    }
  });
});

var mongoose = require('mongoose');
 
// Default Schemaを取得
var Schema = mongoose.Schema;
 
var PageSchema = new Schema({
  wiki: String,
  title: String,
  text: String,
  timestamp: Date
});

// モデル化。model('[登録名]', '定義したスキーマクラス')
mongoose.model('pages', PageSchema);

var Gyazz;
 
// mongodb://[hostname]/[dbname]
mongoose.connect('mongodb://localhost/gyazz');
 
// mongoDB接続時のエラーハンドリング
var db = mongoose.connection;
db.on('error', console.error.bind(console, 'connection error:'));
db.once('open', function() {
  console.log("Connected to 'gyazz' database");
  // 定義したときの登録名で呼び出し
  Gyazz = mongoose.model('pages');
  //populateDB();
});


app.listen(3000);
console.log('Listening on port 3000...');
