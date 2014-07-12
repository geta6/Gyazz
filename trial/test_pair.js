//var express = require('express');
//var app = express();
//var pairs = require('./pair')(app);

var mongoose = require('mongoose');
mongoose.connect('mongodb://localhost/gyazz', function(err) {
  if (err) {
    console.error("mongoose connect failed");
    console.error(err);
    process.exit(1);
    return;
  }
  console.log("connect MongoDB");
});

var pairSchema = new mongoose.Schema({
  wiki: String,
  title1: String,
  title2: String
}, {
  collection:"Pairs" // Mongooseは勝手に小文字の複数形にするので大文字を使うときはこういう指定が必要
});

var Pairs = mongoose.model('Pairs', pairSchema);

Pairs.find({'wiki':'増井研', 'title1':'shokai'},{},{sort:{timestamp: -1},limit:1}, function(err, results){ // 最新のをひとつだけ取得
  if (err) {
    console.log('error');
  } else {
    console.log(results);
  }
});

