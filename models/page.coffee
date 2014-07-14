#
# Gyazzページのデータ
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

  # Pageクラス(?)のクラスメソッド(?)みたいなものの定義。
  pageSchema.statics.latest = (wiki, title, callback) ->
    @find
      wiki: wiki
      title:title
    .sort
      timestamp: -1
    .limit 1
    .exec (err, results) ->
      callback err, results[0]  # 最新のをひとつだけ取得

  log = (history) ->
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
      #Math.floor Math.log(v[i]+0.9) * 3
    
  pageSchema.statics.access = (wiki, title, callback) ->
    debug "page.access(#{wiki},#{title})"
    origthis = this
    Access.find
      wiki:  wiki
      title: title
    .exec (err, results) ->
      access_history = results.map (result) ->
        result.timestamp
      alog = log access_history
      origthis.find
        wiki: wiki
        title:title
      .exec (err, results) ->
        modify_history = results.map (result) ->
          result.timestamp
        mlog = log modify_history
        visualize(alog,mlog,callback)

  visualize = (alog,mlog,callback) ->
    data = []
    bgcolor = [255,255,255]
    [0...MAXH].map (y) ->
      data[y] = []
      [0...MAX].map (x) ->
        data[y][x] = bgcolor
    [0...MAX].map (i) ->
      d = alog[i]
      d = MAXH if d >= MAXH
      c = 8 - (alog[i]/10)
      c = 0 if c < 0
      [0...d].map (y) ->
        data[MAXH-y-1][MAX-i-1] = [128,128,128]
    [0...MAX].map (i) ->
      d = mlog[i]
      d = MAXH if d >= MAXH
      c = 8 - (mlog[i]/10)
      c = 0 if c < 0
      [0...d].map (y) ->
        data[MAXH-y-1][MAX-i-1] = [0,0,0]
    callback false, data
      

#    data = [ # ダミー
#      [[0, 0, 0], [100, 100, 100], [200, 200, 200]],
#      [[0, 0, 0], [100, 100, 100], [200, 200, 200]],
#      [[0, 0, 0], [100, 100, 100], [200, 200, 200]]
#    ]
#    callback false, data
    
#  # 関連ページをリストするインスタンスメソッドみたいなもの
#  # page.related(callback) とする?
#  #
#  pageSchema.methods.related = (callback) ->
#    debug "pageSchema.meghods.related-------------------"
#    debug callback
#    Pairs = mongoose.model 'Pairs'
#    debug Pairs.related this # 関連ページとウェイトを得る
#    debug "vvvvvvvvvvvvvvvvvvvvvvvvvv"
#    callback 0
#    debug "^^^^^^^^^^^^^^^^^^^^^^^^^^^"
#    #                      ここで関連ページリストを得る?

  mongoose.model 'Page', pageSchema
