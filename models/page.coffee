#
# Gyazzページのデータ, アクセス情報
#
 
debug    = require('debug')('gyazz:page')
_        = require 'underscore'
mongoose = require 'mongoose'

module.exports = (app) ->
  
  Access = mongoose.model 'Access'
  
  pageSchema = new mongoose.Schema
    wiki: String
    title: String
    text: String
    timestamp: Date

  # Pages.json() 指定されたページを取得
  pageSchema.statics.json = (wiki, title, param, callback) ->
    @find
      wiki: wiki
      title:title
    .sort
      timestamp: -1
    .exec (err, results) ->
      if param.version # Nバージョン前のデータを取得
        callback err, results[param.version]
        return
      if param.age # 履歴画像上ドラッグで古いデータを取得
        days = Math.ceil(Math.exp(param.age * Math.log(1.5)))              # だいたい何日前のデータか計算
        time = new Date(results[0].timestamp - days * 24 * 60 * 60 * 1000) # その日付を取得
        oldpage = _.find(results, (result) -> result.timestamp < time)     # それより古いデータを取得
        oldpage = results[results.length - 1] unless oldpage               # なければ最古のものを取得
        callback err, oldpage if oldpage
        return
      callback err, results[0] # 最新バージョンを取得

  # インデクス作成が必要
  # % mongo gyazz
  # db.pages.ensureIndex({ timestamp: 1 })
  # db.access.ensureIndex({ timestamp: 1 })

  # Pages.mlist() 更新順にページタイトルのリストを取得
  pageSchema.statics.mlist = (wiki, callback) ->
    timesort this, wiki, callback

  # Pages.alist() アクセス順にページタイトルのリストを取得
  pageSchema.statics.alist = (wiki, callback) ->
    timesort Access, wiki, callback
    
  timesort = (db, wiki, callback) ->
    db.find
      wiki: wiki
    .sort
      timestamp: -1
    .exec (err, results) ->
      if err
        console.log err
        return
      list = []
      titles = {}
      results.map (result) ->
        title = result.title
        unless titles[title]
          titles[title] = true
          list.push title
      callback err, list

  # Pages.access() すべてのアクセス/変更時刻の配列を得る
  pageSchema.statics.access = (wiki, title, callback) ->
    debug "page.access(#{wiki},#{title})"
    Access.find
      wiki:  wiki
      title: title
    .exec (err, results) => # this を継承させる
      access_history = results.map (result) ->
        result.timestamp
      access_log = accumulate_log access_history
      this.find
        wiki: wiki
        title:title
      .sort # 更新順にソート
        timestamp: -1
      .exec (err, results) ->
        modify_history = results.map (result) ->
          result.timestamp
        modify_log = accumulate_log modify_history
        visualize access_log, modify_log, callback

  MAX = 25
  MAXH = 12
  
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

    # 新しく更新したものは背景を黄色くする
    hotcolors = [[255,255,0],[255,255,40],[255,255,80],[255,255,120],[255,255,160],[255,255,200]]
    bgcolor = [255,255,255]
    [0..5].reverse().map (i) ->
      bgcolor = hotcolors[i] if modify_log[i] > 0
    
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
