class GyazzUpload
  init: (gb) ->
    @gb = gb
    
  sendfiles: (files) ->
    [0...files.length].forEach (i) ->
      file = files[i]
      _sendfile.call @, file, (filename) ->
        @gb.editline = @gb.data.length
        if filename.match(/\.(jpg|jpeg|png|gif)$/i)
          @gb.data[@gb.editline] = "[[[#{root}/upload/#{filename}]]]"
        else
          @gb.data[@gb.editline] = "[[#{root}/upload/#{filename} #{file.name}]]"
        writedata()
        @gb.editline = -1
        display gb, true

  _sendfile = (file, callback) ->
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

window.GyazzUpload = GyazzUpload
