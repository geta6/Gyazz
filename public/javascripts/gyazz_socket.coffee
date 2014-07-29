class GyazzSocket
  
  init: (gb, gd, gt) ->
    @socket = io.connect "#{location.protocol}//#{location.hostname}?wiki=#{wiki}&title=#{title}"
    @gb = gb
    @gd = gd
    @gt = gt

    @socket.on 'pagedata', (res) =>
      # alert "pagedata received... data = #{res.data}"
      if res.wiki == wiki && res.title == title
        _data_old =   res['data'].concat()
        @gb.data    = res.data.concat()
        @gb.datestr = res.date
        @gb.timestamps = res.timestamps
        @gb.refresh()
        
    @socket.on 'writesuccess', (res) =>
      notifyBox.hide()

  getdata: (opts=null, callback=null) =>
    opts = {} if opts == null || typeof opts != 'object'
    if typeof opts.version != 'number' || 0 > opts.version
      opts.version = 0
    @socket.emit 'read',
      wiki:  wiki
      title: title
      opts:  opts

  _oldstr = ""
  writedata: (data) ->
    datastr = data.join("\n").replace(/\n+$/,'')+"\n"
    if datastr == _oldstr
      return
    _oldstr = datastr
    notifyBox.print("saving..", {progress: true}).show()
    keywords = _.flatten data.map (line) =>
      @gt.keywords(line, wiki, title, 0)
    @socket.emit 'write',
      wiki:     wiki
      title:    title
      data:     datastr
      keywords: keywords
  
window.GyazzSocket = GyazzSocket
