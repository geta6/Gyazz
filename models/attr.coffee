#
# ページ属性
#

debug = require('debug')('gyazz:attr')

mongoose = require 'mongoose'

module.exports = (app) ->

  attrSchema = new mongoose.Schema {
    wiki: String
    title: String
    repimage: String
  }, {
    collection: "Attrs"
  }

  attrSchema.statics.repimage = (wiki, title, callback) ->
    debug "Attrs.repimage"
<<<<<<< HEAD
    @find
      wiki:wiki
      title:title
    .exec (err, results) ->
      debug results
      callback false, results[0]?['attr']['repimage']

  mongoose.model 'Attr', attrSchema
=======
    Attrs.find {wiki:wiki, title:title}, (err, results) ->
      debug results
      callback false, results[0]['attr']['repimage']

  Attrs = mongoose.model 'Attrs', attrSchema
>>>>>>> master
