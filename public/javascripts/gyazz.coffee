#
# jQueryを利用して書き直し (2011/6/11 masui)
# CoffeeScriptに書き直し   (2014/7/20 masui)
#

#
#  以下はExpressでセットされる
#  var name =  '増井研';
#  var title = 'MIRAIPEDIA';
#  var root =  'http://masui.sfc.keio.ac.jp/Gyazz';
#

gb = new GyazzBuffer()
version = -1

dt = []        # 背景色
doi = []
zoomlevel = 0
cache =
  history : {} #  historyimageをなぞって表示するページ履歴 key:age, value:response

not_saved = false

datestr = ''
showold = false          # 過去データ表示モード

editTimeout = null       # 行長押しで編集モードになる時間
clearEditTimeout = () ->
  if editTimeout
    clearTimeout editTimeout
    editTimeout = null

KC =
  tab:   9
  enter: 13
  ctrlD: 17
  left:  37
  up:    38
  right: 39
  down:  40
  k:     75
  n:     78
  p:     80
  s:     83

authbuf = []

# $(document).ready()
$ ->
  $('#rawdata').hide()
  setup()
  getdata
    suggest: true # 1回目はsuggestオプションを付けてgetdata
  getrelated()

$(document).mouseup (event) ->
  clearEditTimeout()
  gb.eline = -1
  true

$(document).mousemove (event) ->
  clearEditTimeout()
  true

longmousedown = ->
  gb.editline = gb.eline
  calcdoi()
  display true

$(document).mousedown (event) ->
  y = event.pageY

  if gb.eline == -1  # 行以外をクリック
    writedata()
    gb.editline = gb.eline
    calcdoi()
    display true
  else
    clearEditTimeout()
    editTimeout = setTimeout longmousedown, 300
  true

$(document).keyup (event) ->
  input = $("#newtext")
  gb.data[gb.editline] = input.val()

#  keypressを定義しておかないとFireFox上で矢印キーを押してときカーソルが動いてしまう
$(document).keypress (event) ->
  kc = event.which
  if kc == KC.enter
    event.preventDefault()
  if kc == KC.enter
    # 1行追加
    # IME確定でもkeydownイベントが出てしまうのでここで定義が必要!
    if gb.editline >= 0
      gb.addblankline(gb.editline+1,gb.line_indent(gb.editline))
      # search()
      zoomlevel = 0
      calcdoi()
      display()
      return false
    # カーソルキーやタブを無効化
    if !event.shiftKey && (kc == KC.down || kc == KC.up || kc == KC.tab)
      return false

$(document).keydown (event) ->
  kc = event.which
  sk = event.shiftKey
  ck = event.ctrlKey
  cd = event.metaKey && !ck
    
  not_saved = true

  switch
    when ck && kc == KC.s && gb.editline >= 0 # Ctrl-Sでtranspose
      event.preventDefault()
      gb.transpose()
    when kc == KC.enter
      $('#query').val('')
      writedata()
    when kc == KC.down && sk # Shift+↓ = 下にブロック移動
      gb.block_down()
    when kc == KC.k && ck # Ctrl+K カーソルより右側を削除する
      input_tag = $("#newtext")
      if input_tag.val().match(/^\s*$/) && gb.editline < gb.data.length-1  # 行が完全に削除された時
        gb.data[gb.editline] = ""# 現在の行を削除
        gb.deleteblankdata()
        writedata()
        setTimeout ->
          # カーソルを行頭に移動
          input_tag = $("#newtext")
          input_tag[0].selectionStart = 0
          input_tag[0].selectionEnd = 0
        , 10
        return
      setTimeout ->  # Mac用。ctrl+kでカーソルより後ろを削除するまで待つ
        cursor_pos = input_tag[0].selectionStart
        if input_tag.val().length > cursor_pos  # ctrl+kでカーソルより後ろが削除されていない場合
          input_tag.val input_tag.val().substring(0, cursor_pos) # カーソルより後ろを削除
          input_tag.selectionStart = cursor_pos
          input_tag.selectionEnd = cursor_pos
      , 10
    when kc == KC.down && ck # 行を下に移動
      gb.line_down()
    when kc == KC.down && !sk || kc == KC.n && !sk && ck # 下にカーソル移動
      gb.cursor_down()
    when kc == KC.up && sk # 上にブロック移動
      gb.block_up()
    when kc == KC.up && ck && gb.editline > 0 # 行を上に移動
      gb.line_up()
    when (kc == KC.up && !sk) || (kc == KC.p && !sk && ck) # 上にカーソル移動
      gb.cursor_up()
    when kc == KC.tab && !sk || kc == KC.right && sk # indent
      if gb.editline >= 0 && gb.editline < gb.data.length
        gb.data[gb.editline] = ' ' + gb.data[gb.editline]
        writedata()
    when kc == KC.tab && sk || kc == KC.left && sk # undent
      if gb.editline >= 0 && gb.editline < gb.data.length
        s = gb.data[gb.editline]
        if s.substring(0,1) == ' '
          gb.data[gb.editline] = s.substring(1,s.length)
        writedata()
    when kc == KC.left && !sk && !ck && gb.editline < 0 # zoom out
      if -zoomlevel < gb.maxindent()
        zoomlevel -= 1
        display()
    when kc == KC.right && !sk && !ck && gb.editline < 0 # zoom in
      if zoomlevel < 0
        zoomlevel += 1
        display()
    when ck && kc == KC.left # 古いバージョンゲット
      version += 1
      getdata
        version:version
    when ck && kc == KC.right
      if version >= 0
        version -= 1
        getdata
          version:version
    when kc >= 0x30 && kc <= 0x7e && gb.editline < 0 && !cd && !ck
      $('#querydiv').css('visibility','visible').css('display','block')
      $('#query').focus()
      
  if not_saved
    $("#newtext").css('background-color','#f0f0d0')
 
 # 認証文字列をサーバに送る
tell_auth = ->
  authstr = authbuf.sort().join(",")
  $.ajax
    type: "POST",
    async: false,
    url: "#{root}/__tellauth",
    data:
      name: name,
      title: title,
      authstr: authstr

# こうすると動的に関数を定義できる (クロージャ)
# 行をクリックしたとき呼ばれる
linefunc = (n) ->
  (event) ->
    if writable
      gb.eline = n
    if do_auth
      authbuf.push(gb.data[n])
      tell_auth()
    if event.shiftKey
      gb.addblankline n, gb.line_indent(n)  # 上に行を追加
    search()
    true
#
# 初期化
#
setup = ->
  [0...1000].forEach (i) ->
    y = $('<div>').attr('id','listbg'+i)
    x = $('<span>').attr('id','list'+i).mousedown(linefunc(i))
    $('#contents').append(y.append(x))
    
  $('#querydiv').css('display','none')
  
  b = $('body')
  b.bind "dragover", (e) -> false
  b.bind "dragend",  (e) -> false
  b.bind "drop",     (e) -> # Drag&Dropでファイルをアップロード
    e.preventDefault() # デフォルトは「ファイルを開く」
    files = e.originalEvent.dataTransfer.files
    sendfiles files
    false
  
  $('#historyimage').hover (() ->
    showold = true
    ), () ->
    showold = false
    getdata()
  
  $('#historyimage').mousemove (event) ->
    imagewidth = parseInt($('#historyimage').attr('width'))
    age = Math.floor((imagewidth + $('#historyimage').offset().left - event.pageX) * 25 / imagewidth)

    show_history = (res) ->
      datestr = res['date']
      dt = res['age']
      gb.data = res['data']
      search()

    if cache.history[age]
      show_history(cache.history[age])
      return

    $.ajax
      type: "GET"
      async: false, # こうしないと履歴表示が大変なことになるのだが...
      url: "#{root}/#{name}/#{title}/json"
      data:
        age: age
      error: (XMLHttpRequest, textStatus, errorThrown) ->
        alert("ERROR!")
      success: (res) ->
        cache.history[age] = res
        show_history(res)

  $('#contents').mousedown (event) ->
    if gb.eline == -1  # 行以外をクリック
      writedata()

display = (delay) ->
  # $('#debug').text(searchmode)
  
  # zoomlevelに応じてバックグラウンドの色を変える
  $("body").css 'background-color', switch zoomlevel
    when 0  then "#eeeeff"
    when -1 then "#e0e0c0"
    when -2 then "#c0c0a0"
    else         "#a0a080"
  $('#datestr').text if version >= 0 || showold then datestr else ''
  $('#title').attr
    href: "#{root}/#{name}/#{title}/__edit/#{ if version >= 0 then version else 0 }"
  
  if delay # ちょっと待ってもう一度呼び出す!
    setTimeout display, 200
    return
  
  input = $("#newtext")
  if gb.editline == -1
    gb.deleteblankdata()
    input.css 'display', 'none'
  
  contline = -1
  if gb.data.length == 0
    gb.data = ["(empty)"]
    doi[0] = gb.maxindent()
  [0...gb.data.length].forEach (i) ->
    ind = gb.line_indent(i)
    xmargin = ind * 30
    
    t = $("#list"+i)
    p = $("#listbg"+i)
    if doi[i] >= -zoomlevel
      if i == gb.editline # 編集行
        t.css('display','inline').css('visibility','hidden')
        p.css('display','block').css('visibility','hidden')
        input.css('position','absolute')
        input.css('visibility','visible')
        input.css('left',xmargin+25)
        input.css('top',p.position().top)
        input.blur()
        input.val(gb.data[i]) # Firefoxの場合日本語入力中にこれが効かないことがあるような... blurしておけば大丈夫ぽい
        input.focus()
        input.mousedown(linefunc(i))
        setTimeout ->
          $("#newtext").focus()
        , 100  # 何故か少し待ってからfocus()を呼ばないとフォーカスされない...
      else
        lastchar = ''
        if i > 0 && typeof gb.data[i-1] == "string"
          lastchar = gb.data[i-1][gb.data[i-1].length-1]
        if gb.editline == -1 && lastchar == '\\' # 継続行
          if contline < 0
            contline = i-1
          s = ''
          [contline..i].forEach (j) ->
            s += gb.data[j].replace(/\\$/,'__newline__')
          $("#list"+contline).css('display','inline').css('visibility','visible')
            .html(tag(s,contline).replace(/__newline__/g,''))
          $("#listbg"+contline).css('display','inline').css('visibility','visible')
          t.css('visibility','hidden')
          p.css('visibility','hidden')
        else # 通常行
          contline = -1
          if typeof gb.data[i] == "string" && (m = gb.data[i].match(/\[\[(https:\/\/gist\.github\.com.*\?.*)\]\]/i))
            # gistエンベッド
            # https:#gist.github.com/1748966 のやり方
            gisturl = m[1]
            gistFrame = document.createElement("iframe")
            gistFrame.setAttribute("width", "100%")
            gistFrame.id = "gistFrame" + i
            gistFrame.style.border = 'none'
            gistFrame.style.margin = '0'
            t.children().remove() # 子供を全部消す
            t.append(gistFrame)
            gistFrameHTML = '<html><body onload="parent.adjustIframeSize(document.body.scrollHeight,'+i+
                ')"><scr' + 'ipt type="text/javascript" src="' + gisturl + '"></sc'+'ript></body></html>'
            # Set iframe's document with a trigger for this document to adjust the height
            gistFrameDoc = gistFrame.document
            if gistFrame.contentDocument
              gistFrameDoc = gistFrame.contentDocument
            else if gistFrame.contentWindow
              gistFrameDoc = gistFrame.contentWindow.document
            
            gistFrameDoc.open()
            gistFrameDoc.writeln(gistFrameHTML)
            gistFrameDoc.close()
          else
            t.css('display','inline').css('visibility','visible').css('line-height','').html(tag(gb.data[i],i))
            p.attr('class','listedit'+ind).css('display','block').css('visibility','visible').css('line-height','')
    else
      t.css('display','none')
      p.css('display','none')
    
    # 各行のバックグラウンド色設定
    $("#listbg"+i).css('background-color', if (version >= 0 || showold) then bgcol(dt[i]) else 'transparent')
    if version >= 0 # ツールチップに行の作成時刻を表示
      $("#list"+i).addClass('hover')
      date = new Date()
      createdate = new Date(date.getTime() - dt[i] * 1000)
      $("#list"+i).attr('title',createdate.toLocaleString())
      $(".hover").tipTip
        maxWidth: "auto" #ツールチップ最大幅
        edgeOffset: 5 #要素からのオフセット距離
        activation: "hover" #hoverで表示、clickでも可能
        defaultPosition: "bottom" #デフォルト表示位置
    else
      $("#listbg"+i).removeClass('hover')
  
  [gb.data.length...1000].forEach (i) ->
    $('#list'+i).css('display','none')
    $('#listbg'+i).css('display','none')
  
  input.css('display', if gb.editline == -1 then 'none' else 'block')
  
  gb.align()
  
  # リファラを消すプラグイン
  # http://logic.moo.jp/memo.php/archive/569
  # http://logic.moo.jp/data/filedir/569_3.js
  #
  #jQuery.kill_referrer.rewrite.init()
  follow_scroll()

adjustIframeSize = (newHeight,i) ->
  frame= document.getElementById("gistFrame"+i)
  frame.style.height = parseInt(newHeight) + "px"

data_old = []

writedata = (force) ->
  not_saved = false
  return if !writable

  datastr = gb.data.join("\n").replace(/\n+$/,'')+"\n"
  if !force && (JSON.stringify(gb.data) == JSON.stringify(data_old))
    search()
    return
    
  data_old = gb.data.concat()

  cache.history = {} # 履歴cacheをリセット

  notifyBox.print("saving..", {progress: true}).show()
  
  $.ajax
    type: "POST"
    async: true
    url: "#{root}/__write"
    data:
      name: name
      title: title
      data: datastr
    beforeSend: (xhr,settings) ->
      true
    success: (msg) ->
      $("#newtext").css('background-color','#ddd')
      switch
        when msg.match /^conflict/
          # 再読み込み
          notifyBox.print("write conflict").show(1000)
          getdata() # ここで強制書き換えしてしまうのがマズい? (2011/6/17)
        when msg == 'protected'
          # 再読み込み
          notifyBox.print("このページは編集できません").show(3000)
          getdata()
        when msg == 'noconflict'
          notifyBox.print("save success").show(1000)
        else
          notifyBox.print("Can't find old data - something's wrong.").show(3000)
          getdata()
    error: ->
      notifyBox.print("write error").show(3000)

getdata = (opts) -> # 20050815123456.utf のようなテキストを読み出し
  opts = {} if opts == null || typeof opts != 'object'
  if typeof opts.version != 'number' || 0 > opts.version
    opts.version = 0
  $.ajax
    type: "GET"
    async: true
    url: "#{root}/#{name}/#{title}/json"
    data: opts
    success: (res) ->
      datestr = res['date']
      dt = res['age']
      gb.data = res['data'].concat()
      data_old = res['data'].concat()
      search()

calcdoi = ->
  q = $('#query')
  pbs = new POBoxSearch(assocwiki_pobox_dict)
  re = null
  if q && q.val() != ''
    re = pbs.regexp q.val(), false
  maxind = gb.maxindent()
  [0...gb.data.length].forEach (i) ->
    if (if re then re.exec(gb.data[i]) else true)
      doi[i] = maxind - gb.line_indent(i)
    else
      doi[i] = 0 - gb.line_indent(i) - 1

search = (event) ->
  if event
    kc = event.which
  if event == null || kc != KC.down && kc != KC.up && kc != KC.left && kc != KC.right
    calcdoi()
    zoomlevel = 0
    display()
  false

# 編集中の行が画面外に移動した時に、ブラウザをスクロールして追随する
follow_scroll = ->
  # 編集中かどうかチェック
  return if gb.editline < 0
  return if showold
  
  currentLinePos = $("#newtext").offset().top
  return if !(currentLinePos && currentLinePos > 0)
  currentScrollPos = $("body").scrollTop()
  windowHeight = window.innerHeight
  
  # 編集中の行が画面内にある場合、スクロールする必要が無い
  return if currentScrollPos < currentLinePos && currentLinePos < currentScrollPos+windowHeight
  
  $("body").stop().animate({'scrollTop': currentLinePos - windowHeight/2}, 200)
