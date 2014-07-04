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
    Pairs = mongoose.model('Pairs', pairSchema);

    Pairs.test = function(){
      console.log("TESTTEST");
    };

    return Pairs;
  };

}).call(this);
