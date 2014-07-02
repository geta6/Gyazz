//
// Gyazzページのデータ
//
(function(){

  var mongoose = require('mongoose');

  module.exports = function(app) {

    var Pages;
    var pageSchema = new mongoose.Schema({
      wiki: String,
      title: String,
      text: String,
      timestamp: Date
    }, {
      collection:"Pages" // Mongooseは勝手に小文字の複数形にするので大文字を使うときはこういう指定が必要
    });

    return Pages = mongoose.model('Pages', pageSchema);
  };

}).call(this);
