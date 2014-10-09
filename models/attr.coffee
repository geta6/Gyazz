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
      repimage:
        type: String
        validate: [
          (v) ->
            return true if v is null
            return /^https?:\/\/.+/.test(v) or /^[0-9a-z]+\.(png|jpe?g|gif)$/.test(v)
          'Invalid Image URL'
        ]

  attrSchema.statics.attr = (wiki, title, callback) ->
    @findOne
      wiki:wiki
      title:title
    .exec (err, result) ->
      return callback err if err
      return callback "not found" unless result
      callback null, result.attr

  mongoose.model 'Attr', attrSchema

