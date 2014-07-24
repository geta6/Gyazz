class GyazzSocket
  
  constructor: (gb, gd) ->
    @socket = io()
    @gb = gb
    @gd = gd
    
    @socket.on 'pagedata', (res) =>
      alert "pagedata received... data = #{res.data}"
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
  
window.GyazzSocket = GyazzSocket

  
