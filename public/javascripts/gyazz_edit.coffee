#
# 編集関係のものをまとめる
#

indent = (line) -> # line行目の先頭の空白文字の数
  return 0 if typeof data[line] != "string"
  data[line].match(/^( *)/)[1].length

indentstr = (level) ->  # levelの長さの空白文字列
  ([0...level].map (x) -> " ").join('')

addblankline = (line, indent) ->
  editline = line
  eline = line
  deleteblankdata()
  [data.length-1..editline].map (i) ->
    data[i+1] = data[i]
  data[editline] = indentstr(indent)

deleteblankdata = () -> # 空白行を削除
  [0...data.length].map (i) ->
    if typeof data[i] == "string" && data[i].match /^ *$/
      data.splice i, 1
  calcdoi()

maxindent = () ->
  maxind = 0
  [0...data.length].map (i) ->
    ind = indent i
    maxind = ind if ind > maxind
  maxind
