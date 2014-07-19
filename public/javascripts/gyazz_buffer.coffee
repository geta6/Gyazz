_ = require 'underscore'

class GyazzBuffer
  _indentstr = (level) ->  # levelの長さの空白文字列
    ([0...level].map (x) -> " ").join('')
  _indent = (line) -> # 文字列のインデントを計算
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
 
 console.log b.movelines(0)
 console.log b.movelines(1)
 console.log b.movelines(2)
 console.log b.movelines(3)
 console.log b.movelines(4)
 console.log b.movelines(5)
 console.log b.movelines(6)
 console.log b.movelines(7)





