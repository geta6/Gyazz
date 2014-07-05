//
// リンク情報
//
(function(){

  var mongoose = require('mongoose');

  module.exports = function(app) {

    var Pairs;
    var pairSchema = new mongoose.Schema({
      wiki: String,
      title1: String,
      title2: String
    }, {
      collection:"Pairs" // Mongooseは勝手に小文字の複数形にするので大文字を使うときはこういう指定が必要
    });

    pairSchema.statics.related = function(page){
      console.log("Pairs.related");
      Pairs.find({'wiki':page.wiki, 'title1':page.title},function(err, results){
        for(var i=0;i<results.length;i++){
          console.log(results[i].title2);
        }
      });
      Pairs.find({'wiki':page.wiki, 'title2':page.title},function(err, results){
        for(var i=0;i<results.length;i++){
          console.log(results[i].title1);
        }
      });
    };

    return Pairs = mongoose.model('Pairs', pairSchema);
  };

}).call(this);
