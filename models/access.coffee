#
# アクセス
#

debug = require('debug')('gyazz:access')
mongoose = require 'mongoose'

module.exports = (app) ->

  accessSchema = new mongoose.Schema
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
    timestamp:
      type: Date
      default: Date.now

  #accessSchema.statics.access = (wiki, title, callback) ->
  #  debug "Access.access"
  #  @find
  #    wiki:wiki
  #    title:title
  #  .exec (err, results) ->
  #    results.map (result) ->
  #      debug result.timestamp
  #      # callback false, results[0]?.attr

  mongoose.model 'Access', accessSchema
