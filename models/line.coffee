#
# 行の古さ
#

debug = require('debug')('gyazz:attr')

mongoose = require 'mongoose'

module.exports = (app) ->

  lineSchema = new mongoose.Schema
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
    line: String
    timestamp:
      type: Date
      default: Date.now

  lineSchema.statics.timestamp = (wiki, title, line, callback) ->
    debug "Lines.timestamp"
    @find
      wiki:wiki
      title:title
      line:line
    .sort
      timestamp: -1
    .limit 1
    .exec (err, results) ->
      callback err, results[0]?.timestamp

  lineSchema.statics.timestamps = (wiki, title, data, callback) ->
    debug "Lines.timestamps wiki=#{wiki}, title=#{title}"
    @find
      wiki:wiki
      title:title
    .exec (err, results) ->
      timestamp = {}
      results.map (result) ->
        timestamp[result.line] = result.timestamp
      timestamps = []
      now = new Date
      data.map (line) ->
        m = line.match(/^\s*(.*)\s*$/) # 前後の空白を除去
        timestamps.push (now - timestamp[m[1]]) / 1000
      callback false, timestamps

  ## 行が新しければタイムスタンプを保存する
  lineSchema.statics.saveIfNewLine = (wiki, title, line, callback) ->
    @findOne
      wiki:  wiki
      title: title
      line:  line
    .exec (err, result) =>
      if err
        debug "saveNewLine error: #{err}"
        callback err
        return
      if result
        callback "line already exists"
        return
      line = new @
        wiki: wiki
        title: title
        line: line
      line.save (err) ->
        callback err


  mongoose.model 'Line', lineSchema
