#
# リンク情報
#

debug = require('debug')('gyazz:pair')
_ = require 'underscore'

mongoose = require 'mongoose'

module.exports = (app) ->

  pairSchema = new mongoose.Schema {
    wiki: String,
    title1: String,
    title2: String
  }, {
    collection: "Pairs" # Mongooseは勝手に小文字の複数形にするので大文字を使うときはこういう指定が必要
  }

  # pageに関連するページの配列を得る
  pairSchema.statics.related = (page) ->
    debug "Pairs.related"
    related = {}
    Pairs.find {'wiki':page.wiki, 'title1':page.title}, (err, results) ->
      for pair in results
        related[pair.title2] = 1
    Pairs.find {'wiki':page.wiki, 'title2':page.title}, (err, results) ->
      for pair in results
        related[pair.title1] = 1

    _.keys(related)

  Pairs = mongoose.model 'Pairs', pairSchema
