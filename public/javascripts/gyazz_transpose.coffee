#
# 行/桁入れ換え
#

spaces = []  # 行に空白がいくつ含まれているか (桁揃えに利用)

similarlines = (process, condition) -> # 同じパタンの連続行の処理
  beginline = 0
  lastspaces = -1
  lastindent = -1
  [0...gb.data.length].map (i) ->
    if spaces[i] > 0 && spaces[i] == lastspaces && indent(i) == lastindent # cont
    else
      if lastspaces > 1 && i-beginline > 1  # 同じパタンの連続を検出
        if condition beginline, i
          process beginline, i-beginline, indent(beginline)
      beginline = i

    lastspaces = spaces[i]
    lastindent = indent(i)

  if lastspaces > 1 && gb.data.length-beginline > 1 #  同じパタンの連続を検出
    if condition beginline, gb.data.length
      process beginline, gb.data.length-beginline, indent(beginline)

transpose_condition = (beginline,limit) ->
  window.editline >= beginline && window.editline < limit

transpose = () ->
  return if window.editline < 0
  similarlines do_transpose, transpose_condition

do_transpose = (beginline, lines, indent) ->  # begin番目からlines個の行の行と桁を入れ換え
  cols = spaces[beginline] + 1
  newlines = []
  [0...cols].map (i) ->
    newlines[i] = indentstr()
  
  [0...lines].map (y) ->
    matched2 = []
    matched3 = []
    s = gb.data[beginline+y]
    s = s.replace /^\s*/, ''
    s = s.replace /</g, '&lt'
    while m = s.match /^(.*)\[\[\[(([^\]]|\][^\]]|[^\]]\])*)\]\]\](.*)$/ # [[[....]]]
      [x, pre, inner, x, post] = m
      matched3.push inner
      s = pre + '<<3<' + (matched3.length-1) + '>3>>' + post
    while m = s.match /^(.*)\[\[(([^\]]|\][^\]]|[^\]]\])*)\]\](.*)$/ # [[....]]
      [x, pre, inner, x, post] = m
      matched2.push inner
      s = pre + '<<2<' + (matched2.length-1) + '>2>>' + post
    elements = s.split ' '
    
    [0...elements.length].map (i) -> # 行桁入れ換え
      while a = elements[i].match /^(.*)<<3<(\d+)>3>>(.*)$/
        elements[i] = a[1] + "[[[" + matched3[a[2]] + "]]]" + a[3]
      while a = elements[i].match /^(.*)<<2<(\d+)>2>>(.*)$/
        elements[i] = a[1] + "[[" + matched2[a[2]] + "]]" + a[3]
    [0...elements.length].map (i) ->
      newlines[i] += " " if y != 0
      newlines[i] += elements[i]
      
  # data[] の beginlineからlines行をnewlines[]で置き換える
  gb.data.splice beginline, lines
  [0...newlines.length].map (i) ->
    gb.data.splice beginline+i, 0, newlines[i]
  
  writedata()
  window.editline = -1
  display true
