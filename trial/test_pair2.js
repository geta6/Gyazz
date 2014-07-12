var pairs = require('../models/pair')();

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

Pairs = mongoose.model('Pairs');

Pairs.find({'wiki':'増井研', 'title2':'shokai'},{},{sort:{timestamp: -1},limit:10}, function(err, results){ // 最新のをひとつだけ取得
  if (err) {
    console.log('error');
  } else {
    console.log(results);
  }
});

