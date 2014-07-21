#
# テキストバッファの編集関連
# 適宜HTMLを更新したりサーバと通信したりする必要あり
#

_ = require 'underscore' if typeof module != "undefined" && module.exports

class GyazzBuffer
  
  # levelの長さの空白文字列
  _indentstr = (level) ->
    ([0...level].map (x) -> " ").join('')
    
  # 文字列のインデントを計算
  _indent = (line) ->
    line.match(/^( *)/)[1].length

  data: []               # テキストデータ
  editline: -1           # 現在編集中の行番号
  eline: -1              # クリックした行の番号
  
  init: (arg) ->
    @data = if typeof arg == 'string' then arg.split /\n/ else arg
    
  # n行目のインデントを計算
  line_indent: (n) ->
    _indent @data[n]
      
  # 最大のインデント値を取得
  maxindent: ->
    Math.max (@data.map (line) -> _indent line)...

  # reduce を使うとこういう感じになるのだが、Coffeeだと上のような記法が可能らしい
  # maxindent: ->
  #   indents = @data.map (line) -> _indent line
  #   _.reduce indents, ((x, y) -> Math.max(x, y)), 0

  # 空白行を削除
  deleteblankdata: ->
    @data = _.filter @data, (line) ->
      typeof line == "string" && !line.match /^ *$/

  # 空白行を挿入
  addblankline: (line, indent) ->
    @editline = line
    @eline = line # ?????
    @deleteblankdata()
    [@data.length-1..@editline].forEach (i) =>
      @data[i+1] = @data[i]
    @data[@editline] = _indentstr indent
  
  # n行目からブロック移動しようとするときのブロック行数
  _movelines = (n) ->
    ind = @line_indent n
    last = _.find [n+1...@data.length], (i) =>
      @line_indent(i) <= ind
    (last ||= @data.length) - n

  # インデントが自分と同じか自分より深い行を捜す。
  # ひとつもなければ -1 を返す。
  # 引数にeditlineを指定するように仕様が変わっている
  _destline_up = (n) ->
    ind_editline = @line_indent n
    foundline = -1
    if n > 0
      _.find [n-1..0], (i) =>
        ind = @line_indent i
        foundline = i if ind > ind_editline
        if ind == ind_editline
          foundline = i
          return true
        if ind < ind_editline
          return true
    foundline

  # インデントが自分と同じ行を捜す。
  # ひとつもなければ -1 を返す。
  _destline_down = (n) ->
    ind_editline = @line_indent n
    foundline = -1
    _.find [n+1...@data.length], (i) =>
      ind = @line_indent i
      if ind == ind_editline
        foundline = i
        return true
      if ind < ind_editline
        foundline = -1
        return true
    foundline
    
  #########################################################################
  #
  #   行移動 / ブロック移動
  #
  #########################################################################

  # カーソルを下に移動
  cursor_down: ->
    if @editline >= 0 && @editline < @data.length-1
      dest = _.find [@editline+1...@data.length], (i) ->
        doi[i] >= -zoomlevel
      if dest
        setTimeout =>
          @editline = dest
          @deleteblankdata()
          writedata()
          display()
        , 1

  # カーソルを上に移動
  cursor_up: ->
    if @editline > 0
      dest = _.find [@editline-1..0], (i) ->
        doi[i] >= -zoomlevel
      if dest != undefined
        setTimeout =>
          @editline = dest
          @deleteblankdata()
          writedata()
          display()
        , 1

  # カーソルの行を下に移動
  line_down: ->
    if @editline >= 0 && @editline < @data.length-1
      l = @editline
      [@data[l], @data[l+1]] = [@data[l+1], @data[l]]
      setTimeout =>
        @editline += 1
        @deleteblankdata()
        writedata() #####
        display()
      , 1
  
  # カーソルの行を上に移動
  line_up: ->
    if @editline > 0
      l = @editline
      [@data[l], @data[l-1]] = [@data[l-1], @data[l]]
      setTimeout =>
        @editline -= 1
        @deleteblankdata()
        writedata() #####
        display()
      , 1
  
  # editlineのブロックを下に移動
  block_down: ->
    if @editline >= 0 && @editline < @data.length - 1
      m = _movelines.call @, @editline
      dst = _destline_down.call @, @editline
      if dst >= 0
        m2 = _movelines.call @, dst
        tmp = []
        [0...m].forEach  (i) => tmp[i] = @data[@editline+i]
        [0...m2].forEach (i) => @data[@editline+i] = @data[dst+i]
        [0...m].forEach  (i) => @data[@editline+m2+i] = tmp[i]
        @editline += m2
        @deleteblankdata()    ######## ここに必要?
        writedata()          ######## 通信モジュールに移動すべき
        display()

  # editlineのブロックを上に移動
  block_up: ->
    if @editline > 0 && @editline < @data.length
      m = _movelines.call @, @editline
      dst = _destline_up.call @, @editline
      if dst >= 0
        m2 = @editline - dst
        tmp = []
        [0...m2].forEach (i) => tmp[i] = @data[dst+i]
        [0...m].forEach (i)  => @data[dst+i] = @data[@editline+i]
        [0...m2].forEach (i) => @data[dst+m+i] = tmp[i]
        @editline = dst
        @deleteblankdata() ########
        writedata()       ########
        display()

  #########################################################################
  #
  #   桁揃え、行桁交換
  #
  #########################################################################

  spaces: []  # 行に空白がいくつ含まれているか (桁揃えに利用)

  _similarlines = (process, condition) -> # 同じパタンの連続行の処理
    beginline = 0
    lastspaces = -1
    lastindent = -1
    [0...@data.length].forEach (i) =>
      if @spaces[i] > 0 && @spaces[i] == lastspaces && @line_indent(i) == lastindent
        # 連続パタン続行中
      else
        if lastspaces > 1 && i-beginline > 1  # 同じパタンの連続を検出
          if condition beginline, i, @editline
            process.call @, beginline, i-beginline, @line_indent(beginline)
        beginline = i

      lastspaces = @spaces[i]
      lastindent = @line_indent(i)

    if lastspaces > 1 && @data.length-beginline > 1 #  同じパタンの連続を検出
      if condition beginline, @data.length
        #alert "condition met"
        process.call @, beginline, @data.length-beginline, @line_indent(beginline)

  #
  # 桁揃え
  #
  align: () -> # 同じパタンの連続を検出して桁を揃える
    _similarlines.call @, _do_align, () -> true

  _do_align = (begin, lines, dummy) -> # begin番目からlines個の行を桁揃え
    pos = []
    width = []
    maxwidth = []
    [begin...begin+lines].forEach (line) => # 表示されている要素の位置を取得
      pos[line] = []
      width[line] = []
      [0..@spaces[begin]].forEach (i) =>
        # 要素のidはtag()でつけられている
        id = "#e" + line + "_" + (i + @line_indent(line))
        pos[line][i] = $(id).offset().left
      [0..@spaces[begin]].forEach (i) ->
        width[line][i] = pos[line][i+1]-pos[line][i]
  
    [0...@spaces[begin]].forEach (i) -> # 桁ごとに最大幅を計算 範囲 あってる????
      max = 0
      [begin...begin+lines].forEach (line) ->
        max = width[line][i] if width[line][i] > max
      maxwidth[i] = max
  
    colpos = pos[begin][0]
    [0..@spaces[begin]].forEach (i) => # 最大幅ずつずらして表示
      [begin...begin+lines].forEach (line) =>
        id = "#e" + line + "_" + (i + @line_indent(line))
        $(id).css('position','absolute').css('left',colpos)
      colpos += maxwidth[i]

  #
  # editline周辺の行の行と桁を入れ換える
  #
  transpose: () ->
    return if @editline < 0
    _similarlines.call @, _do_transpose, _transpose_condition # thisを伝播させる

  _transpose_condition =  (beginline,limit,editline) ->
    editline >= beginline && editline < limit
    
  # begin番目からlines個の行の行と桁を入れ換え
  _do_transpose = (beginline, lines, indent) ->
    cols = @spaces[beginline] + 1
    newlines = []
    [0...cols].forEach (i) ->
      newlines[i] = _indentstr indent

    # !!! タグ処理は gyazz_tag.coffee でやるべきではないか?
    # tag_split() みたいなメソッドがいるのではないだろうか
    #
    [0...lines].forEach (y) =>
      matched2 = []
      matched3 = []
      s = @data[beginline+y]
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
    
      [0...elements.length].forEach (i) -> # 行桁入れ換え
        while a = elements[i].match /^(.*)<<3<(\d+)>3>>(.*)$/
          elements[i] = a[1] + "[[[" + matched3[a[2]] + "]]]" + a[3]
        while a = elements[i].match /^(.*)<<2<(\d+)>2>>(.*)$/
          elements[i] = a[1] + "[[" + matched2[a[2]] + "]]" + a[3]
      [0...elements.length].forEach (i) ->
        newlines[i] += " " if y != 0
        newlines[i] += elements[i]
      
    # data[] の beginlineからlines行をnewlines[]で置き換える
    @data.splice beginline, lines
    [0...newlines.length].forEach (i) =>
      @data.splice beginline+i, 0, newlines[i]
  
    writedata()            ############
    @editline = -1
    display true           ############
    # transpose後に行選択しておきたいが、前の行データが残っててうまくいかない
