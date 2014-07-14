#
# アクセス
#

debug = require('debug')('gyazz:access')
mongoose = require 'mongoose'

module.exports = (app) ->

  accessSchema = new mongoose.Schema
    wiki: String
    title: String
    timestamp: Date

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
