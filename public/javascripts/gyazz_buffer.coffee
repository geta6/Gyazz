#
# テキストバッファの編集関連
# 適宜HTMLを更新したりサーバと通信したりする必要あり
#

# _ = require 'underscore' if typeof module != "undefined" && module.exports

class GyazzBuffer

  tag = new GyazzTag

  constructor: (rw, gd) ->
    @rw = rw
    @gd = gd
    
  # levelの長さの空白文字列
  _indentstr = (level) ->
    ([0...level].map (x) -> " ").join('')
    
  # 文字列のインデントを計算
  _indent = (line) ->
    line.match(/^( *)/)[1].length

  _spaces = []           # 行に含まれている空白文字の数

  _data = []             # テキストデータ
  doi: []
  
  editline: -1           # 現在編集中の行番号

  zoomlevel: 0

  seteditline: (line) ->
    @editline = line
    @gd.display @, true

  setdata: (data) ->
    _data = data

  data: ->
    _data

  setline: (str) ->
    _data[@editline] = str

  calcdoi: (query) ->
    q = $('#filter')
    pbs = new POBoxSearch(assocwiki_pobox_dict)
    re = null
    if q && q.val() != ''
      re = pbs.regexp q.val(), false
    maxind = @maxindent()
    [0..._data.length].forEach (i) =>
      if (if re then re.exec(_data[i]) else true)
        @doi[i] = maxind - @line_indent(i)
      else
        @doi[i] = 0 - @line_indent(i) - 1
  
  init: (arg) ->
    _data = if typeof arg == 'string' then arg.split /\n/ else arg
    
  # n行目のインデントを計算
  line_indent: (n) ->
    _indent _data[n]
      
  # 最大のインデント値を取得
  maxindent: ->
    Math.max (_data.map (line) -> _indent line)...

  # reduce を使うとこういう感じになるのだが、Coffeeだと上のような記法が可能らしい
  # maxindent: ->
  #   indents = _data.map (line) -> _indent line
  #   _.reduce indents, ((x, y) -> Math.max(x, y)), 0

  # 空白行を削除
  deleteblankdata: ->
    _data = _.filter _data, (line) ->
      typeof line == "string" && !line.match /^ *$/

  # 空白行を挿入
  addblankline: (line, indent) ->
    @editline = line
    # @eline = line # ?????
    @deleteblankdata()
    [_data.length-1..@editline].forEach (i) =>
      _data[i+1] = _data[i]
    _data[@editline] = _indentstr indent
  
  # n行目からブロック移動しようとするときのブロック行数
  _movelines = (n) ->
    ind = @line_indent n
    last = _.find [n+1..._data.length], (i) =>
      @line_indent(i) <= ind
    (last ||= _data.length) - n

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
    _.find [n+1..._data.length], (i) =>
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
    if @editline >= 0 && @editline < _data.length-1
      dest = _.find [@editline+1..._data.length], (i) =>
        @doi[i] >= -@zoomlevel
      if dest
        setTimeout =>
          @editline = dest
          @deleteblankdata()
          @rw.writedata _data
          @gd.display @
        , 1

  # カーソルを上に移動
  cursor_up: ->
    if @editline > 0
      dest = _.find [@editline-1..0], (i) =>
        @doi[i] >= -@zoomlevel
      if dest != undefined
        setTimeout =>
          @editline = dest
          @deleteblankdata()
          @rw.writedata _data
          @gd.display @
        , 1

  # カーソルの行を下に移動
  line_down: ->
    if @editline >= 0 && @editline < _data.length-1
      l = @editline
      [_data[l], _data[l+1]] = [_data[l+1], _data[l]]
      setTimeout =>
        @editline += 1
        @deleteblankdata()
        @rw.writedata _data  #####
        @gd.display @
      , 1
  
  # カーソルの行を上に移動
  line_up: ->
    if @editline > 0
      l = @editline
      [_data[l], _data[l-1]] = [_data[l-1], _data[l]]
      setTimeout =>
        @editline -= 1
        @deleteblankdata()
        @rw.writedata _data  #####
        @gd.display @
      , 1
  
  # editlineのブロックを下に移動
  block_down: ->
    if @editline >= 0 && @editline < _data.length - 1
      m = _movelines.call @, @editline
      dst = _destline_down.call @, @editline
      if dst >= 0
        m2 = _movelines.call @, dst
        tmp = []
        [0...m].forEach  (i) => tmp[i] = _data[@editline+i]
        [0...m2].forEach (i) => _data[@editline+i] = _data[dst+i]
        [0...m].forEach  (i) => _data[@editline+m2+i] = tmp[i]
        @editline += m2
        @deleteblankdata()    ######## ここに必要?
        @rw.writedata _data    ######## 通信モジュールに移動すべき
        @gd.display @

  # editlineのブロックを上に移動
  block_up: ->
    if @editline > 0 && @editline < _data.length
      m = _movelines.call @, @editline
      dst = _destline_up.call @, @editline
      if dst >= 0
        m2 = @editline - dst
        tmp = []
        [0...m2].forEach (i) => tmp[i] = _data[dst+i]
        [0...m].forEach (i)  => _data[dst+i] = _data[@editline+i]
        [0...m2].forEach (i) => _data[dst+m+i] = tmp[i]
        @editline = dst
        @deleteblankdata() ########
        @rw.writedata _data ########
        @gd.display @

  #########################################################################
  #
  #   インデント
  #
  #########################################################################

  # インデント
  indent: ->
    if @editline >= 0 && @editline < _data.length
      _data[@editline] = ' ' + _data[@editline]
      @rw.writedata _data
      @gd.display @

  # アンデント
  undent: ->
    if @editline >= 0 && @editline < _data.length
      s = _data[@editline]
      if s.substring(0,1) == ' '
        _data[@editline] = s.substring(1,s.length)
      @rw.writedata _data
      @gd.display @

  #########################################################################
  #
  #   ズーミング
  #
  #########################################################################

  # ズームイン
  zoomin: ->
    if @zoomlevel < 0
      @zoomlevel += 1
      @gd.display @

  # ズームアウト
  zoomout: ->
    if -@zoomlevel < @maxindent()
      @zoomlevel -= 1
      @gd.display @

  #########################################################################
  #
  #   右側消去
  #
  #########################################################################

  kill: ->
    input = $("#editline")
    if input.val().match(/^\s*$/) && @editline < _data.length-1  # 行が完全に削除された時
      _data[@editline] = ""# 現在の行を削除
      @deleteblankdata()
      @rw.writedata _data
      setTimeout ->
        # カーソルを行頭に移動
        # input = $("#editline")
        input[0].selectionStart = 0
        input[0].selectionEnd = 0
      , 10
      return
    setTimeout ->  # Mac用。ctrl+kでカーソルより後ろを削除するまで待つ
      cursor_pos = input[0].selectionStart
      if input.val().length > cursor_pos  # ctrl+kでカーソルより後ろが削除されていない場合
        input.val input_tag.val().substring(0, cursor_pos) # カーソルより後ろを削除
        input.selectionStart = cursor_pos
        input.selectionEnd = cursor_pos
    , 10
    
  #########################################################################
  #
  #   桁揃え、行桁交換
  #
  #########################################################################

  _similarlines = (process, condition) -> # 同じパタンの連続行の処理
    beginline = 0
    lastspaces = -1
    lastindent = -1

    _spaces = _data.map (line) -> # 行に空白がいくつ含まれているか
      tag.split(line).length - _indent(line) - 1
    
    [0..._data.length].forEach (i) =>
      if _spaces[i] > 0 && _spaces[i] == lastspaces && @line_indent(i) == lastindent
        # 連続パタン続行中
      else
        if lastspaces > 1 && i-beginline > 1  # 同じパタンの連続を検出
          if condition beginline, i, @editline
            process.call @, beginline, i-beginline, @line_indent(beginline)
        beginline = i

      lastspaces = _spaces[i]
      lastindent = @line_indent(i)

    if lastspaces > 1 && _data.length-beginline > 1 #  同じパタンの連続を検出
      if condition beginline, _data.length
        process.call @, beginline, _data.length-beginline, @line_indent(beginline)

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
      [0.._spaces[begin]].forEach (i) =>
        # 要素のidはtag()でつけられている
        id = "#e" + line + "_" + (i + @line_indent(line))
        pos[line][i] = $(id).offset().left
      [0.._spaces[begin]].forEach (i) ->
        width[line][i] = pos[line][i+1]-pos[line][i]
  
    [0..._spaces[begin]].forEach (i) -> # 桁ごとに最大幅を計算 範囲 あってる????
      max = 0
      [begin...begin+lines].forEach (line) ->
        max = width[line][i] if width[line][i] > max
      maxwidth[i] = max
  
    colpos = pos[begin][0]
    [0.._spaces[begin]].forEach (i) => # 最大幅ずつずらして表示
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
    cols = _spaces[beginline] + 1
    newlines = []
    [0...cols].forEach (i) ->
      newlines[i] = _indentstr indent

    [0...lines].forEach (y) =>
      s = _data[beginline+y]
      s = s.replace(/^\s*/,'').replace(/</g,'&lt')
      a = tag.split(s)
      [0...a.length].forEach (i) ->
        newlines[i] += " " if y != 0
        newlines[i] += a[i]
      
    # data[] の beginlineからlines行をnewlines[]で置き換える
    _data.splice beginline, lines
    [0...newlines.length].forEach (i) =>
      _data.splice beginline+i, 0, newlines[i]
  
    @rw.writedata _data        ############
    @editline = -1
    @gd.display @, true           ############
    # transpose後に行選択しておきたいが、前の行データが残っててうまくいかない

window.GyazzBuffer = GyazzBuffer
