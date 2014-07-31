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
    @findOne
      wiki:wiki
      title:title
    .exec (err, result) ->
      return callback err if err
      return callback "not found" unless result
      callback null, result.attr

  mongoose.model 'Attr', attrSchema

