_ = require 'underscore'

class GyazzBuffer
  
  # levelの長さの空白文字列
  _indentstr = (level) ->
    ([0...level].map (x) -> " ").join('')
    
  # 文字列のインデントを計算
  _indent = (line) ->
    line.match(/^( *)/)[1].length

  data: []               # テキストデータ
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

  # editlineのブロックを下に移動
  block_down: ->
    if this.editline >= 0 && this.editline < this.data.length - 1
      m = this.movelines this.editline
      dst = this.destline_down this.editline
      if dst >= 0
        m2 = this.movelines dst
        tmp = []
        [0...m].map  (i) => tmp[i] = this.data[this.editline+i]
        [0...m2].map (i) => this.data[this.editline+i] = this.data[dst+i]
        [0...m].map  (i) => this.data[this.editline+m2+i] = tmp[i]
        this.editline += m2
        # deleteblankdata();

  # editlineのブロックを上に移動
  block_up: ->
    if this.editline > 0 && this.editline < this.data.length
      m = this.movelines this.editline
      dst = this.destline_up this.editline
      if dst >= 0
        m2 = this.editline - dst
        tmp = []
        [0...m2].map (i) => tmp[i] = this.data[dst+i]
        [0...m].map (i)  => this.data[dst+i] = this.data[this.editline+i]
        [0...m2].map (i) => this.data[dst+m+i] = tmp[i]
        this.editline = dst
        # deleteblankdata()
        # writedata()

if false
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
 b.editline = 3
 console.log b.block_up()
 console.log "-----"
 console.log b.data
# console.log "-----"
# console.log b.block_down
# console.log "-----"
# console.log b.block_down
# console.log "-----"
# console.log b.block_down
# console.log "-----"
# console.log b.block_down
# console.log "-----"
# console.log b.block_down
# console.log "-----"
# console.log b.block_down
# console.log "-----"
# console.log b.block_down
# console.log "-----"

