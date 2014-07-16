#
# 行の古さ
#

debug = require('debug')('gyazz:attr')

mongoose = require 'mongoose'

module.exports = (app) ->

  lineSchema = new mongoose.Schema
    wiki: String
    title: String
    line: String
    timestamp: Date

  lineSchema.statics.timestamp = (wiki, title, line, callback) ->
    debug "Lines.timestamp"
    @find
      wiki:wiki
      title:title
      line:line
    .exec (err, results) ->
      callback false, results[0]?.timestamp

  lineSchema.statics.timestamps = (wiki, title, data, callback) ->
    debug "Lines.timestamps wiki=#{wiki}, title=#{title}"
    @find
      wiki:wiki
      title:title
    .exec (err, results) ->
      timestamp = {}
      results.map (result) ->
        debug "timestamp = #{result.timestamp}"
        timestamp[result.line] = result.timestamp
      timestamps = []
      now = new Date
      data.map (line) ->
        m = line.match(/^\s*(.*)\s*$/) # 前後の空白を除去
        timestamps.push (now - timestamp[m[1]]) / 1000
      callback false, timestamps

  mongoose.model 'Line', lineSchema
