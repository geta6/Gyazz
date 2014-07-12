var mongoose = require('mongoose');

//var pageSchema = new mongoose.Schema({
//  wiki: String,
//  title: String,
//  text: String,
//  timestamp: Date
//});

var pageSchema = new mongoose.Schema({
  wiki: String,
  title: String,
  text: String,
  timestamp: Date
}, { collection:"Pages"} );

var Pages = mongoose.model('Pages', pageSchema);

//var Pages = mongoose.model('Pages', pageSchema, { collection:"Pages" });

//    collection : collectionName,
//var Pages = mongoose.model(collectionName, {
//    collection : collectionName,
//    properties : [ 'userid', 'password', 'created_at' ],
//    methods    : {
//        ...
//    }
//});

mongoose.connect('mongodb://localhost/gyazz', function(err) {
  if (err) { return; }
  console.log("connect MongoDB");
});

Pages.find({'title':'shokai'},{},{sort:{timestamp: -1},limit:1}, function(err, results){ // 最新のをひとつだけ取得
  if (err) {
    console.log('ERROR');
  } else {
    console.log(results);
  }
});


