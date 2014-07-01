//
// Gyazzページのデータ
//
(function(){

  var mongoose = require('mongoose');

  module.exports = function(app) {

    var Gyazz;
    var pageSchema = new mongoose.Schema({
      wiki: String,
      title: String,
      text: String,
      timestamp: Date
    });

    return Gyazz = mongoose.model('pages', pageSchema);
  };

}).call(this);
