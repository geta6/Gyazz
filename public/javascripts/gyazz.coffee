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
#

gs = new GyazzSocket   # socket.io
gd = new GyazzDisplay  # display()
gb = new GyazzBuffer   # Gyazzテキスト編集関連
gr = new GyazzRelated  # 関連ページ取得
gu = new GyazzUpload   # アップロード処理
gt = new GyazzTag

# 依存関係を設定
gd.init gt
gb.init gs, gd, gt
gs.init gb, gd
gu.init gb

historycache = {}            # 履歴cache
clickline = -1               # マウスクリックして押してるときだけ行番号が入る

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
  window.root = "http://#{location.host}"

  $('#rawdata').hide()

  [0...1000].forEach (i) ->
    y = $('<div>').attr('id',"listbg#{i}")
    x = $('<span>').attr('id',"list#{i}").mousedown(linefunc(i,gb))
    $('#contents').append(y.append(x))
    
  b = $('body')
  b.bind "dragover", (e) -> false
  b.bind "dragend",  (e) -> false
  b.bind "drop",     (e) -> # Drag&Dropでファイルをアップロード
    e.preventDefault() # デフォルトは「ファイルを開く」
    files = e.originalEvent.dataTransfer.files
    gu.sendfiles files
    false
  
  $('#filterdiv').css('display','none')
  $("#filter").keyup (event) ->
    $('#filterdiv').css('display','none') if $('#filter').val() == ''
    gb.refresh()

  $('#historyimage').hover (() ->
    gd.showold = true
    ), () ->
    gd.showold = false
    gs.getdata
      async: false  # ヒストリ表示をきっちり終了させるのに必要...?
    , (res) ->
      gb.data    = res.data.concat()
      gb.datestr = res.date
      gd.display gb

  $('#historyimage').mousemove (event) ->
    imagewidth = parseInt($('#historyimage').attr('width'))
    age = Math.floor((imagewidth + $('#historyimage').offset().left - event.pageX) * 25 / imagewidth)

    if historycache[age]
      show_history historycache[age]
    else
      gs.getdata
        async: false # こうしないと履歴表示が大変なことになるのだが...
        age:   age
      , (res) ->
        historycache[age] = res
        show_history res
        gb.data    = res.data.concat()
        gb.datestr = res.date
        gd.display gb

  $('#contents').mousedown (event) ->
    if clickline == -1  # 選択行がないとき
      gs.writedata gb.data
    true
    
  gs.getdata
    async: false
    suggest: true # 1回目はsuggestオプションを付けてデータ取得
  , (res) ->
    gb.timestamps = res.timestamps
    gb.data       = res.data.concat()
    gb.datestr    = res.date
    gb.refresh()
    
  gr.getrelated()

longmousedown = ->
  gb.editline = clickline
  gd.display gb, true

$(document).mouseup (event) ->
  clearTimeout longPressTimeout?
  clickline = -1
  true

$(document).mousemove (event) ->
  clearTimeout longPressTimeout?
  true

$(document).mousedown (event) ->
  if clickline == -1  # 行以外をクリック
    gs.writedata gb.data
    gb.seteditline clickline
  else
    clearTimeout longPressTimeout?
    if gb.editline != clickline # #27
      longPressTimeout = setTimeout longmousedown, 300
  true
  
$(document).keyup (event) ->
  gb.data[gb.editline] = $("#editline").val()

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
      gb.refresh()
      # gd.display gb #######
      return false
    # カーソルキーやタブを無効化
    if !event.shiftKey && (kc == KC.down || kc == KC.up || kc == KC.tab)
      return false

getversion = (n) ->
  if gd.version + n >= -1
    gd.version += n
    gs.getdata
      version:gd.version
    , (res) ->
      gb.data = res.data.concat()
      gb.datestr = res.date
    gb.refresh()
          
$(document).keydown (event) ->
  kc = event.which
  sk = event.shiftKey
  ck = event.ctrlKey
  cd = event.metaKey && !ck
    
  # rw.not_saved = true

  switch
    when ck && kc == KC.s && gb.editline >= 0 # Ctrl-Sでtranspose
      event.preventDefault()
      gb.transpose()
    when kc == KC.enter
      $('#filter').val('')
      gs.writedata gb.data
    when kc == KC.down && sk # Shift+↓ = 下にブロック移動
      gb.block_down()
    when kc == KC.k && ck # Ctrl+K カーソルより右側を削除する
      gb.kill()
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
      gb.indent()
    when kc == KC.tab && sk || kc == KC.left && sk # undent
      gb.undent()
    when kc == KC.left && !sk && !ck && gb.editline < 0 # zoom out
      gb.zoomout()
    when kc == KC.right && !sk && !ck && gb.editline < 0 # zoom in
      gb.zoomin()
    when ck && kc == KC.left # 古いバージョンゲット
      getversion 1
    when ck && kc == KC.right
      getversion -1
    when kc >= 0x30 && kc <= 0x7e && gb.editline < 0 && !cd && !ck
      $('#filterdiv').css('display','block')
      $('#filter').focus()
      
  #if rw.not_saved
  #  $("#editline").css('background-color','#f0f0d0')
 
# 行クリックで呼ばれる関数をクロージャで定義
window.linefunc = (n,gb) ->
  (event) ->
    clickline = n
    if event.shiftKey
      gb.addblankline n, gb.line_indent(n)  # 上に行を追加
    true
    
show_history = (res) ->
  gb.datestr =    res.date
  gb.timestamps = res.timestamps
  gb.data =       res.data
  gb.refresh()

window.adjustIframeSize = (newHeight, i) ->
  frame= document.getElementById("gistFrame"+i)
  frame.style.height = parseInt(newHeight) + "px"
