#
# Gyazzページのデータ
#
 
debug = require('debug')('gyazz:page')
pair = require('./pair')

mongoose = require 'mongoose'

module.exports = (app) ->
  
  pageSchema = new mongoose.Schema {
    wiki: String
    title: String
    text: String
    timestamp: Date
  }, {
    collection: "Pages" # Mongooseは勝手に小文字の複数形にするので大文字を使うときはこういう指定が必要
  }

  #
  # Pageクラス(?)のクラスメソッド(?)みたいなものの定義。
  # インスタンスメソッド(?)は pageSchema.methods.???? = function() ... みたいに定義するらしい
  #
  pageSchema.statics.latest = (param,callback) ->
    Pages.find param, {}, {sort:{timestamp: -1},limit:1}, (err, results) ->  # 最新のをひとつだけ取得
      callback err, results[0]

  #
  # 関連ページをリストするインスタンスメソッドみたいなもの
  # page.related(callback) とする?
  #
  pageSchema.methods.related = (callback) ->
    Pairs = mongoose.model 'Pairs'
    Pairs.related this # 関連ページとウェイトを得る
    #                      ここで関連ページリストを得る?


  # return Pages = mongoose.model 'Pages', pageSchema
  Pages = mongoose.model 'Pages', pageSchema

