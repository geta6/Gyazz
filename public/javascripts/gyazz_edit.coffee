#
# 編集関係のものをまとめる
#

indent = (line) -> # line行目の先頭の空白文字の数
  return 0 if typeof gb.data[line] != "string"
  gb.data[line].match(/^( *)/)[1].length

indentstr = (level) ->  # levelの長さの空白文字列
  ([0...level].map (x) -> " ").join('')

addblankline = (line, indent) ->
  gb.editline = line
  eline = line
  deleteblankdata()
  [gb.data.length-1..gb.editline].map (i) ->
    gb.data[i+1] = gb.data[i]
  gb.data[gb.editline] = indentstr(indent)

deleteblankdata = () -> # 空白行を削除
  [0...gb.data.length].map (i) ->
    if typeof gb.data[i] == "string" && gb.data[i].match /^ *$/
      gb.data.splice i, 1
  calcdoi()

maxindent = () ->
  maxind = 0
  [0...gb.data.length].map (i) ->
    ind = indent i
    maxind = ind if ind > maxind
  maxind
