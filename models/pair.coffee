#
# リンク情報
#

debug = require('debug')('gyazz:pair')

mongoose = require 'mongoose'

module.exports = (app) ->

  pairSchema = new mongoose.Schema {
    wiki: String,
    title1: String,
    title2: String
  }, {
    collection: "Pairs" # Mongooseは勝手に小文字の複数形にするので大文字を使うときはこういう指定が必要
  }

  pairSchema.statics.related = (page) ->
    debug "Pairs.related"
    Pairs.find {'wiki':page.wiki, 'title1':page.title}, (err, results) ->
      for pair in results
        debug pair.title2

    Pairs.find {'wiki':page.wiki, 'title2':page.title}, (err, results) ->
      for pair in results
        debug pair.title1

  Pairs = mongoose.model 'Pairs', pairSchema
