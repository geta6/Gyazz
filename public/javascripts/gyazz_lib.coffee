# _ = require 'underscore' if typeof module != "undefined" && module.exports

# 16進2桁
window.hex2 = (v) ->
  v = Math.floor(v)
  v = 255 if v >= 256
  ("0" + v.toString(16)).slice(-2)

# 古さから背景色作成
window.bgcol = (t) ->
  table = [
    [0,                                  256,256,256]
    [10,                                 240,240,240]
    [10*10,                              220,220,220]
    [10*10*10,                           200,200,200]
    [10*10*10*10,                        180,180,180]
    [10*10*10*10*10,                     160,160,160]
    [10*10*10*10*10*10,                  140,140,140]
    [10*10*10*10*10*10*10,               120,120,120]
    [10*10*10*10*10*10*10*10,            100,100,100]
    [10*10*10*10*10*10*10*10*10,          80, 80, 80]
    [10*10*10*10*10*10*10*10*10*10,       60, 60, 60]
    [10*10*10*10*10*10*10*10*10*10*10,    40, 40, 40]
  ]
  t1 = t2 = 0
  ind = _.find [0...table.length-1], (i) ->
    t1 = table[i][0]
    t2 = table[i+1][0]
    t >= t1 && t <= t2
  if ind
    r = Math.floor ((t - t1) * table[ind+1][1] + (t2 - t) * table[ind][1]) / (t2 - t1)
    g = Math.floor ((t - t1) * table[ind+1][2] + (t2 - t) * table[ind][2]) / (t2 - t1)
    b = Math.floor ((t - t1) * table[ind+1][3] + (t2 - t) * table[ind][3]) / (t2 - t1)
    "#{hex2(r)}#{hex2(g)}#{hex2(b)}"
  else
    "#000000"

window.sendfiles = (files) ->
  [0...files.length].forEach (i) ->
    file = files[i]
    sendfile file, (filename) ->
      gb.editline = gb.data.length
      if filename.match(/\.(jpg|jpeg|png|gif)$/i)
        gb.data[gb.editline] = "[[[#{root}/upload/#{filename}]]]"
      else
        gb.data[gb.editline] = "[[#{root}/upload/#{filename} #{file.name}]]"
      writedata()
      gb.editline = -1
      display true

window.sendfile = (file, callback) ->
  fd = new FormData
  fd.append 'uploadfile', file
  notifyBox.print("uploading..", {progress: true}).show()
  $.ajax
    url: root + "/__upload"
    type: "POST"
    data: fd
    processData: false
    contentType: false
    dataType: 'text'
    error: (XMLHttpRequest, textStatus, errorThrown) ->
      # 通常はここでtextStatusやerrorThrownの値を見て処理を切り分けるか、
      # 単純に通信に失敗した際の処理を記述します。
      alert 'upload fail'
      notifyBox.print("upload fail").show(3000)
      this # thisは他のコールバック関数同様にAJAX通信時のオプションを示します。
    success: (data) ->
      notifyBox.print("upload success!!").show(1000)
      callback(data)
  false
