#
# ページ属性
#

debug = require('debug')('gyazz:attr')

mongoose = require 'mongoose'

module.exports = (app) ->

  attrSchema = new mongoose.Schema {
    wiki: String
    title: String
    attr:
      repimage: String
  }, {
    collection: "Attrs"
  }

  attrSchema.statics.attr = (wiki, title, callback) ->
    debug "Attrs.attr"
    @find
      wiki:wiki
      title:title
    .exec (err, results) ->
      callback false, results[0]?.attr

  mongoose.model 'Attr', attrSchema

