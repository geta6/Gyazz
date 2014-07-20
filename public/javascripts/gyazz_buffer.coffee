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
  editline: -1           # 現在選択してる行の番号
  init: (arg) ->
    this.data = if typeof arg == 'string' then arg.split /\n/ else arg
    
  # 空白行を削除
  deleteblankdata: ->
    @data = _.filter @data, (line) ->
      typeof line == "string" && !line.match /^ *$/

  # n行目のインデントを計算
  line_indent: (n) ->
    _indent @data[n]
      
  # 最大のインデント値を取得
  maxindent: ->
    Math.max (@data.map (line) -> _indent line)...

  #maxindent: ->
  #  indents = this.data.map (line) -> _indent line
  #  _.reduce indents, ((x, y) -> Math.max(x, y)), 0

  # n行目からブロック移動しようとするときのブロック行数
  movelines: (n) ->
    ind = this.line_indent n
    last = _.find [n+1...this.data.length], (i) =>
      this.line_indent(i) <= ind
    (last ||= this.data.length) - n

  # インデントが自分と同じか自分より深い行を捜す。
  # ひとつもなければ -1 を返す。
  # 引数にeditlineを指定するように仕様が変わっている
  destline_up: (n) ->
    ind_editline = this.line_indent n
    foundline = -1
    if n > 0
      _.find [n-1..0], (i) =>
        ind = this.line_indent i
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
    ind_editline = this.line_indent n
    foundline = -1
    _.find [n+1...this.data.length], (i) =>
      ind = this.line_indent i
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
    if this.editline >= 0 && this.editline < this.data.length-1
      dest = _.find [this.editline+1...this.data.length], (i) ->
        doi[i] >= -zoomlevel
      if dest
        setTimeout =>
          this.editline = dest
          deleteblankdata()
          writedata()
          display()
        , 1

  # カーソルを上に移動
  cursor_up: ->
    if this.editline > 0
      dest = _.find [this.editline-1..0], (i) ->
        doi[i] >= -zoomlevel
      if dest != undefined
        setTimeout =>
          this.editline = dest
          deleteblankdata()
          writedata()
          display()
        , 1

  # カーソルの行を下に移動
  line_down: ->
    if this.editline >= 0 && this.editline < this.data.length-1
      l = this.editline
      [this.data[l], this.data[l+1]] = [this.data[l+1], this.data[l]]
      #current_line_data = this.data[this.editline]
      #this.data[this.editline] = this.data[this.editline+1]
      #this.data[this.editline+1] = current_line_data
      setTimeout =>
        this.editline += 1
        deleteblankdata()
        writedata() #####
        display()
      , 1
  
  # カーソルの行を上に移動
  line_up: ->
    if this.editline > 0
      l = this.editline
      [this.data[l], this.data[l-1]] = [this.data[l-1], this.data[l]]
      #current_line_data = this.data[this.editline]
      #this.data[this.editline] = this.data[this.editline-1]
      #this.data[this.editline-1] = current_line_data
      setTimeout =>
        this.editline -= 1
        deleteblankdata()
        writedata() #####
        display()
      , 1
  
  # editlineのブロックを下に移動
  block_down: ->
    if this.editline >= 0 && this.editline < this.data.length - 1
      m = this.movelines this.editline
      dst = this.destline_down this.editline
      if dst >= 0
        m2 = this.movelines dst
        tmp = []
        [0...m].forEach  (i) => tmp[i] = this.data[this.editline+i]
        [0...m2].forEach (i) => this.data[this.editline+i] = this.data[dst+i]
        [0...m].forEach  (i) => this.data[this.editline+m2+i] = tmp[i]
        this.editline += m2
        deleteblankdata()    ######## ここに必要?
        writedata()          ######## 通信モジュールに移動すべき
        display()

  # editlineのブロックを上に移動
  block_up: ->
    if this.editline > 0 && this.editline < this.data.length
      m = this.movelines this.editline
      dst = this.destline_up this.editline
      if dst >= 0
        m2 = this.editline - dst
        tmp = []
        [0...m2].forEach (i) => tmp[i] = this.data[dst+i]
        [0...m].forEach (i)  => this.data[dst+i] = this.data[this.editline+i]
        [0...m2].forEach (i) => this.data[dst+m+i] = tmp[i]
        this.editline = dst
        deleteblankdata() ########
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
    [0...this.data.length].forEach (i) =>
      if this.spaces[i] > 0 && this.spaces[i] == lastspaces && this.line_indent(i) == lastindent
        # 連続パタン続行中
      else
        if lastspaces > 1 && i-beginline > 1  # 同じパタンの連続を検出
          if condition beginline, i, this.editline
            process.call @, beginline, i-beginline, this.line_indent(beginline)
        beginline = i

      lastspaces = this.spaces[i]
      lastindent = this.line_indent(i)

    if lastspaces > 1 && this.data.length-beginline > 1 #  同じパタンの連続を検出
      if condition beginline, this.data.length
        #alert "condition met"
        process.call @, beginline, this.data.length-beginline, this.line_indent(beginline)

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
      [0..this.spaces[begin]].forEach (i) =>
        # 要素のidはtag()でつけられている
        id = "#e" + line + "_" + (i + this.line_indent(line))
        pos[line][i] = $(id).offset().left
      [0..this.spaces[begin]].forEach (i) ->
        width[line][i] = pos[line][i+1]-pos[line][i]
  
    [0...this.spaces[begin]].forEach (i) -> # 桁ごとに最大幅を計算 範囲 あってる????
      max = 0
      [begin...begin+lines].forEach (line) ->
        max = width[line][i] if width[line][i] > max
      maxwidth[i] = max
  
    colpos = pos[begin][0]
    [0..this.spaces[begin]].forEach (i) => # 最大幅ずつずらして表示
      [begin...begin+lines].forEach (line) =>
        id = "#e" + line + "_" + (i + this.line_indent(line))
        $(id).css('position','absolute').css('left',colpos)
      colpos += maxwidth[i]

  #
  # editline周辺の行の行と桁を入れ換える
  #
  transpose: () ->
    return if this.editline < 0
    _similarlines.call @, _do_transpose, _transpose_condition # thisを伝播させる

  _transpose_condition =  (beginline,limit,editline) ->
    editline >= beginline && editline < limit
    
  # begin番目からlines個の行の行と桁を入れ換え
  _do_transpose = (beginline, lines, indent) ->
    cols = this.spaces[beginline] + 1
    newlines = []
    [0...cols].forEach (i) ->
      newlines[i] = _indentstr indent

    [0...lines].forEach (y) =>
      matched2 = []
      matched3 = []
      s = this.data[beginline+y]
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
    this.data.splice beginline, lines
    [0...newlines.length].forEach (i) =>
      this.data.splice beginline+i, 0, newlines[i]
  
    writedata()            ############
    this.editline = -1
    display true           ############
    # transpose後に行選択しておきたいが、前の行データが残っててうまくいかない
