#
# データ書込み/読出し関連
#
class GyazzReadWrite
  
  _data_old = ''

  not_saved: false

  writedata: (data) ->
    datastr = data.join("\n").replace(/\n+$/,'')+"\n"
    return if JSON.stringify(data) == JSON.stringify(_data_old) # 何か変
    
    _data_old = data.concat()

    notifyBox.print("saving..", {progress: true}).show()
  
    $.ajax
      type: "POST"
      async: true
      url: "#{root}/__write"
      data:
        name:  name
        title: title
        data:  datastr
      beforeSend: (xhr,settings) ->
        true
      success: (msg) ->
        @not_saved = false
        $("#editline").css('background-color','#ddd')
        switch
          when msg.match /^conflict/
            # 再読み込み
            notifyBox.print("write conflict").show(1000)
            getdata() # ここで強制書き換えしてしまうのがマズい? (2011/6/17)
          when msg == 'protected'
            # 再読み込み
            notifyBox.print("このページは編集できません").show(3000)
            @getdata()
          when msg == 'noconflict'
            notifyBox.print("save success").show(1000)
          else
            notifyBox.print("Can't find old data - something's wrong.").show(3000)
            @getdata()
      error: ->
        notifyBox.print("write error").show(3000)

  getdata: (opts=null, callback=null) -> # 20050815123456.utf のようなテキストを読み出し
    opts = {} if opts == null || typeof opts != 'object'
    if typeof opts.version != 'number' || 0 > opts.version
      opts.version = 0
    $.ajax
      type: "GET"
      async: if opts.async? then opts.async else true
      url: "#{root}/#{name}/#{title}/json"
      data: opts
      success: (res) ->
        _data_old =   res['data'].concat()
        callback res if callback
      error: (XMLHttpRequest, textStatus, errorThrown) ->
        alert("getdata ERROR!")

window.GyazzReadWrite = GyazzReadWrite
