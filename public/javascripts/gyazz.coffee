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

rw =  new GyazzReadWrite     # サーバとのデータやりとり
gb =  new GyazzBuffer(rw)    # Gyazzテキスト編集関連
tag = new GyazzTag

version = -1             # ページの古さ
historycache = {}        # 編集履歴視覚化キャッシュ
showold = false          # 過去データ表示モード
clickline = -1           # マウスクリックして押してるときだけ行番号が入る
authbuf = []
not_saved = false
timestamps = []
datestr = ''

editTimeout = null       # 行長押しで編集モードに移行
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

$ -> # = $(document).ready()
  $('#rawdata').hide()

  [0...1000].forEach (i) ->
    y = $('<div>').attr('id',"listbg#{i}")
    x = $('<span>').attr('id',"list#{i}").mousedown(linefunc(i))
    $('#contents').append(y.append(x))
    
  $('#filterdiv').css('display','none')
  
  b = $('body')
  b.bind "dragover", (e) -> false
  b.bind "dragend",  (e) -> false
  b.bind "drop",     (e) -> # Drag&Dropでファイルをアップロード
    e.preventDefault() # デフォルトは「ファイルを開く」
    files = e.originalEvent.dataTransfer.files
    sendfiles files
    false
  
  $("#filter").keyup (event) ->
    search()

  $('#historyimage').hover (() ->
    showold = true
    ), () ->
    showold = false
    rw.getdata
      async: false  # ヒストリ表示をきっちり終了させるのに必要...?
    , (res) ->
      gb.data = res.data.concat()
      datestr = res.date
      display()

  $('#historyimage').mousemove (event) ->
    imagewidth = parseInt($('#historyimage').attr('width'))
    age = Math.floor((imagewidth + $('#historyimage').offset().left - event.pageX) * 25 / imagewidth)

    if historycache[age]
      show_history historycache[age]
    else
      rw.getdata
        async: false # こうしないと履歴表示が大変なことになるのだが...
        age:   age
      , (res) ->
        historycache[age] = res
        show_history res
        gb.data = res.data.concat()
        datestr = res.date
        search()
        display()

  $('#contents').mousedown (event) ->
    if clickline == -1  # 行以外をクリック
      rw.writedata gb.data
      not_saved = false
      search() # ??
      display()
    true

  rw.getdata
    async: false
    suggest: true # 1回目はsuggestオプションを付けてgetdata
  , (res) ->
    timestamps = res.timestamps
    gb.data = res.data.concat()
    datestr = res.date
    search()
    
  historycache = {} # 履歴cacheをリセット

  getrelated()

$(document).mouseup (event) ->
  clearEditTimeout()
  clickline = -1
  true

$(document).mousemove (event) ->
  clearEditTimeout()
  true

longmousedown = ->
  gb.seteditline clickline

$(document).mousedown (event) ->
  if clickline == -1  # 行以外をクリック
    rw.writedata gb.data
    not_saved = false
    gb.seteditline clickline
  else
    clearEditTimeout()
    editTimeout = setTimeout longmousedown, 300
  true
  
$(document).keyup (event) ->
  input = $("#editline")
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
      gb.zoomlevel = 0
      gb.calcdoi()
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
      $('#filter').val('')
      rw.writedata gb.data
      not_saved = false
    when kc == KC.down && sk # Shift+↓ = 下にブロック移動
      gb.block_down()
    when kc == KC.k && ck # Ctrl+K カーソルより右側を削除する
      input = $("#editline")
      if input.val().match(/^\s*$/) && gb.editline < gb.data.length-1  # 行が完全に削除された時
        gb.data[gb.editline] = ""# 現在の行を削除
        gb.deleteblankdata()
        rw.writedata gb.data
        not_saved = false
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
        rw.writedata gb.data
        not_saved = false
    when kc == KC.tab && sk || kc == KC.left && sk # undent
      if gb.editline >= 0 && gb.editline < gb.data.length
        s = gb.data[gb.editline]
        if s.substring(0,1) == ' '
          gb.data[gb.editline] = s.substring(1,s.length)
        rw.writedata gb.data
        not_saved = false
    when kc == KC.left && !sk && !ck && gb.editline < 0 # zoom out
      if -gb.zoomlevel < gb.maxindent()
        gb.zoomlevel -= 1
        display()
    when kc == KC.right && !sk && !ck && gb.editline < 0 # zoom in
      if gb.zoomlevel < 0
        gb.zoomlevel += 1
        display()
    when ck && kc == KC.left # 古いバージョンゲット
      version += 1
      rw.getdata
        version:version
      , (res) ->
        gb.data = res.data.concat()
        datestr = res.date
        
    when ck && kc == KC.right
      if version >= 0
        version -= 1
        rw.getdata
          version:version
        , (res) ->
          gb.data = res.data.concat()
          datestr = res.date

    when kc >= 0x30 && kc <= 0x7e && gb.editline < 0 && !cd && !ck
      $('#filterdiv').css('visibility','visible').css('display','block')
      $('#filter').focus()
      
  if not_saved
    $("#editline").css('background-color','#f0f0d0')
 
# 認証文字列をサーバに送る
tell_auth = ->

#  authstr = authbuf.sort().join(",")
#  $.ajax
#    type: "POST",
#    async: false,
#    url: "#{root}/__tellauth",
#    data:
#      name: name,
#      title: title,
#      authstr: authstr

# 行クリックで呼ばれる関数をクロージャで定義
linefunc = (n) ->
  (event) ->
    clickline = n
    if do_auth
      authbuf.push(gb.data[n])
      tell_auth()
    if event.shiftKey
      gb.addblankline n, gb.line_indent(n)  # 上に行を追加
    search()
    true
    
show_history = (res) ->
  datestr =     res.date
  timestamps =  res.timestamps
  gb.data =     res.data
  search()

window.display = (delay) ->
  # zoomlevelに応じてバックグラウンドの色を変える
  $("body").css 'background-color', switch gb.zoomlevel
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
  
  input = $("#editline")
  if gb.editline == -1
    gb.deleteblankdata()
    input.css 'display', 'none'
  
  contline = -1
  if gb.data.length == 0
    gb.data = ["(empty)"]
    gb.doi[0] = gb.maxindent()
    
  [0...gb.data.length].forEach (i) ->
    ind = gb.line_indent i
    xmargin = ind * 30
    
    t = $("#list#{i}")
    p = $("#listbg#{i}")
    if gb.doi[i] >= -gb.zoomlevel
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
        input.mousedown linefunc(i)
        setTimeout ->
          $("#editline").focus()
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
            .html(tag.expand(s,root,name,contline).replace(/__newline__/g,''))
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
            t.css
              display: 'inline'
              visibility: 'visible'
              'line-height': ''
            .html tag.expand(gb.data[i],root,name,i)
            p.attr "class", "listedit#{ind}" # addClassだとダメ!! 前のが残るのか?
            p.css
              display: 'block'
              visibility: 'visible'
              'line-height': ''
    else
      t.css 'display', 'none'
      p.css 'display', 'none'

    
    # 各行のバックグラウンド色設定
    $("#listbg#{i}").css('background-color', if (version >= 0 || showold) then bgcol(timestamps[i]) else 'transparent')
    if version >= 0 # ツールチップに行の作成時刻を表示
      $("#list#{i}").addClass('hover')
      date = new Date()
      createdate = new Date(date.getTime() - timestamps[i] * 1000)
      $("#list#{i}").attr 'title', createdate.toLocaleString()
      $(".hover").tipTip
        maxWidth: "auto" #ツールチップ最大幅
        edgeOffset: 5 #要素からのオフセット距離
        activation: "hover" #hoverで表示、clickでも可能
        defaultPosition: "bottom" #デフォルト表示位置
    else
      $("#listbg#{i}").removeClass('hover')
      
  [gb.data.length...1000].forEach (i) ->
    $("#list#{i}").css('display','none')
    $("#listbg#{i}").css('display','none')
  
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

window.search = (event) ->
  if event
    kc = event.which
  if event == null || kc != KC.down && kc != KC.up && kc != KC.left && kc != KC.right
    gb.zoomlevel = 0
    gb.calcdoi()
  false

# 編集中の行が画面外に移動した時に、ブラウザをスクロールして追随する
follow_scroll = ->
  # 編集中かどうかチェック
  return if gb.editline < 0
  return if showold
  
  currentLinePos = $("#editline").offset().top
  return if !(currentLinePos && currentLinePos > 0)
  currentScrollPos = $("body").scrollTop()
  windowHeight = window.innerHeight
  
  # 編集中の行が画面内にある場合、スクロールする必要が無い
  return if currentScrollPos < currentLinePos && currentLinePos < currentScrollPos+windowHeight
  
  $("body").stop().animate({'scrollTop': currentLinePos - windowHeight/2}, 200)
