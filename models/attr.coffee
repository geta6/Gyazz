#
# ページ属性
#

debug = require('debug')('gyazz:attr')

mongoose = require 'mongoose'

module.exports = (app) ->

  attrSchema = new mongoose.Schema
    wiki:
      type: String
      validate: [
        (v) ->
          return mongoose.model('Page').isValidName(v)
        'Invalid WiKi name'
      ]
    title:
      type: String
      validate: [
        (v) ->
          return mongoose.model('Page').isValidName(v)
        'Invalid WiKi name'
      ]
    attr:
      repimage: String

  attrSchema.statics.attr = (wiki, title, callback) ->
    debug "Attrs.attr"
    @find
      wiki:wiki
      title:title
    .exec (err, results) ->
      callback false, results[0]?.attr

  mongoose.model 'Attr', attrSchema

