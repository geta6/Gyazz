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
    });

    return Pages = mongoose.model('pages', pageSchema);
  };

}).call(this);
