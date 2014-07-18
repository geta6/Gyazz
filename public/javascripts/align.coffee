aligncolumns = () -> # 同じパタンの連続を検出して桁を揃える
  similarlines(align, () -> true)

align = (begin, lines, dummy) -> # begin番目からlines個の行を桁揃え
  pos = []
  width = []
  maxwidth = []
  [begin...begin+lines].map (line) -> # 表示されている要素の位置を取得
    pos[line] = []
    width[line] = []
    [0..spaces[begin]].map (i) ->
      id = "#e" + line + "_" + (i + indent(line))
      pos[line][i] = $(id).offset().left
    [0..spaces[begin]].map (i) ->
      width[line][i] = pos[line][i+1]-pos[line][i]

  [0...spaces[begin]].map (i) -> # 桁ごとに最大幅を計算 範囲 あってる????
    max = 0
    [begin...begin+lines].map (line) ->
      max = width[line][i] if width[line][i] > max
    maxwidth[i] = max
  
  colpos = pos[begin][0]
  [0..spaces[begin]].map (i) -> # 最大幅ずつずらして表示
    [begin...begin+lines].map (line) ->
      id = "#e" + line + "_" + (i + indent(line))
      $(id).css('position','absolute').css('left',colpos)
    colpos += maxwidth[i]

