class GyazzSocket
  
  start: (gb, gd) ->
    @socket = io()
    @gb = gb
    @gd = gd
    
    @socket.on 'pagedata', (res) =>
      # alert "pagedata received... data = #{res.data}"
      _data_old =   res['data'].concat()
      @gb.data    = res.data.concat()
      @gb.datestr = res.date
      @gb.refresh()

  getdata: (opts=null, callback=null) =>
    opts = {} if opts == null || typeof opts != 'object'
    if typeof opts.version != 'number' || 0 > opts.version
      opts.version = 0
    @socket.emit 'read',
      wiki:  name
      title: title
      opts:  opts

  writedata: (data) ->
    notifyBox.print("saving..", {progress: true}).show()
    datastr = data.join("\n").replace(/\n+$/,'')+"\n"
    @socket.emit 'write',
      wiki:  name
      title: title
      data:  datastr
  
window.GyazzSocket = GyazzSocket

  
