#
# ページ属性
#

debug = require('debug')('gyazz:attr')

mongoose = require 'mongoose'

module.exports = (app) ->

  attrSchema = new mongoose.Schema
    wiki: String
    title: String
    repimage: String

  attrSchema.statics.repimage = (wiki, title, callback) ->
    debug "Attrs.repimage"
    @find
      wiki:wiki
      title:title
    .exec (err, results) ->
      debug results
      callback false, results[0]?['attr']['repimage']

  mongoose.model 'Attr', attrSchema

