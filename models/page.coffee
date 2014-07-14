#
# Gyazzページのデータ, アクセス情報
#
 
debug    = require('debug')('gyazz:page')
mongoose = require 'mongoose'

Access = mongoose.model 'Access'

module.exports = (app) ->
  
  MAX = 25
  MAXH = 12
  
  pageSchema = new mongoose.Schema
    wiki: String
    title: String
    text: String
    timestamp: Date

  # Pages.latest() 最新ページを得る
  pageSchema.statics.latest = (wiki, title, callback) ->
    @find
      wiki: wiki
      title:title
    .sort
      timestamp: -1
    .limit 1
    .exec (err, results) ->
      callback err, results[0]

  # Pages.access() アクセス/変更情報を得る
  pageSchema.statics.access = (wiki, title, callback) ->
    debug "page.access(#{wiki},#{title})"
    origthis = this # ??????
    Access.find
      wiki:  wiki
      title: title
    .exec (err, results) ->
      access_history = results.map (result) ->
        result.timestamp
      access_log = accumulate_log access_history
      origthis.find
        wiki: wiki
        title:title
      .exec (err, results) ->
        modify_history = results.map (result) ->
          result.timestamp
        modify_log = accumulate_log modify_history
        visualize(access_log,modify_log,callback)

  accumulate_log = (history) ->
    now = new Date
    v = []
    history.map (t) ->
      d = (now - t) / 1000 / (60 * 60 * 24)
      d = 1 if d == 0
      ind = Math.floor (Math.log(d) / Math.log(1.5))
      ind = MAX-1 if ind >= MAX
      v[ind] = 0 unless v[ind]
      v[ind] += 1
    [0..MAX].map (i) ->
      v[i] = 0 unless v[i]
      Math.floor Math.log(v[i]+1.2) * 3
      # Math.floor Math.log(v[i]+0.9) * 3
    
  visualize = (access_log, modify_log, callback) ->
    data = []
    bgcolor = [255,255,255] # 新しいものを黄色くするコードがまだ入ってない
    [0...MAXH].map (y) ->
      data[y] = []
      [0...MAX].map (x) ->
        data[y][x] = bgcolor
    [0...MAX].map (i) ->
      d = access_log[i]
      d = MAXH if d >= MAXH
      #c = 8 - (access_log[i]/10)
      #c = 0 if c < 0
      [0...d].map (y) ->
        # data[MAXH-y-1][MAX-i-1] = [c*20, c*20, c*20]
        data[MAXH-y-1][MAX-i-1] = [128,128,128]
    [0...MAX].map (i) ->
      d = modify_log[i] / 2
      d = MAXH/2 if d >= MAXH/2
      [0...d].map (y) ->
        data[MAXH-y-1][MAX-i-1] = [0,0,0]
    callback false, data
      
#  # 関連ページをリストするインスタンスメソッドみたいなもの
#  pageSchema.methods.related = (callback) ->

  mongoose.model 'Page', pageSchema
