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

    pageSchema.statics.latest = function(param,callback){
      Pages.find(param,{},{sort:{timestamp: -1},limit:1}, function(err, results){ // 最新のをひとつだけ取得
        callback(err,results);
      });
    };

    Pages = mongoose.model('Pages', pageSchema);

    return Pages;
  };

}).call(this);
