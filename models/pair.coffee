#
# リンク情報
#

debug    = require('debug')('gyazz:pair')
_        = require 'underscore'
mongoose = require 'mongoose'

module.exports = (app) ->

  pairSchema = new mongoose.Schema
    wiki: String
    title1: String
    title2: String

  # pageに関連するページの配列を得る
  pairSchema.statics.related = (wiki, title, callback) ->
    debug "Pair.related"
    e = false
    related = {}
    @find {wiki:wiki, title1:title}, (err, results) =>
      e ||= err
      for pair in results
        related[pair.title2] = 1
      @find {wiki:wiki, title2:title}, (err, results) ->
        e ||= err
        for pair in results
          related[pair.title1] = 1
        
        callback e, _.keys(related)

  # # あるページに関連するpairを全部消す
  # pairSchema.statics.remove = (wiki, title) ->
  #   debug "Pair.remove"
  #   @.remove { wiki:wiki', title1:title }, (err) ->
  #     @.remove { wiki:wiki', title2:title }, (err) ->
  #   
  # # あるページに関連するpairを登録する
  # pairSchema.statics.add = (wiki, title, relatedtitles) ->
  #   debug "Pair.add"
  #   relatedtitles.forEach (relatedtitle) ->
  #     Pairs.update
  #       wiki: wiki
  #       title1: title
  #       title2: relatedtitle
  #     , (err) ->
  #       if err
  #         debug "Pair write error"

  mongoose.model 'Pair', pairSchema
