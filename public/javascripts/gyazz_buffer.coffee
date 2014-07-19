_ = require 'underscore'

class GyazzBuffer
  
  # levelの長さの空白文字列
  _indentstr = (level) ->
    ([0...level].map (x) -> " ").join('')
    
  # 文字列のインデントを計算
  _indent = (line) ->
    line.match(/^( *)/)[1].length

  data: []               # バッファデータ
  editline: -1           # 現在選択してる行の番号
  
  init: (arg) ->
    this.data = if typeof arg == 'string' then arg.split /\n/ else arg
    
  # 空白行を削除
  deleteblankdata: ->
    this.data = _.filter this.data, (line) ->
      typeof line == "string" && !line.match /^ *$/
      
  # 最大のインデント値を取得
  maxindent: ->
    indents = this.data.map (line) -> _indent(line)
    _.reduce indents, ((x, y) -> Math.max(x, y)), 0

  # n行目からブロック移動しようとするときのブロック行数
  movelines: (n) ->
    ind = _indent this.data[n]
    last = _.find [n+1...this.data.length], (i) =>
      _indent(this.data[i]) <= ind
    (last ||= this.data.length) - n

  # インデントが自分と同じか自分より深い行を捜す。
  # ひとつもなければ -1 を返す。
  # 引数にeditlineを指定するように仕様が変わっている
  destline_up: (n) ->
    ind_editline = _indent this.data[n]
    foundline = -1
    if n > 0
      _.find [n-1..0], (i) =>
        ind = _indent this.data[i]
        foundline = i if ind > ind_editline
        if ind == ind_editline
          foundline = i
          return true
        if ind < ind_editline
          return true
    foundline

  # インデントが自分と同じ行を捜す。
  # ひとつもなければ -1 を返す。
  destline_down: (n) ->
    ind_editline = _indent this.data[n]
    foundline = -1
    _.find [n+1...this.data.length], (i) =>
      ind = _indent this.data[i]
      if ind == ind_editline
        foundline = i
        return true
      if ind < ind_editline
        foundline = -1
        return true
    foundline



if true
 b = new GyazzBuffer()
 b.init [
   "a"
   " bcd"
   " efg"
   "b"
   "c"
   " d e f"
   "  g h i"
   "  j k l"
   ]

 console.log b.data
 console.log b.destline_down(0)
 console.log "-----"
 console.log b.destline_down(1)
 console.log "-----"
 console.log b.destline_down(2)
 console.log "-----"
 console.log b.destline_down(3)
 console.log "-----"
 console.log b.destline_down(4)
 console.log "-----"
 console.log b.destline_down(5)
 console.log "-----"
 console.log b.destline_down(6)
 console.log "-----"
 console.log b.destline_down(7)
 console.log "-----"




