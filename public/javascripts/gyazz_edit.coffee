socket = io.connect "#{location.protocol}//#{location.hostname}?wiki=#{wiki}&title=#{title}"
gt = new GyazzTag

$ ->
  opts = {version: version}
  
  socket.on 'pagedata', (res) =>
    $('#contents').val res.data.join("\n")

  socket.on 'connect', ->
    socket.emit 'read',
      opts:  opts

  socket.once 'pagedata', ->
    $(document).keyup (event) ->
      clearTimeout timeout if timeout?
      timeout = setTimeout ->
        contents = $('#contents').val()
        datastr = contents.replace(/\n+$/,'')+"\n"
        keywords = _.flatten contents.split(/\n/).map (line) =>
          gt.keywords(line, wiki, title, 0)
        socket.emit 'write',
          data:     datastr
          keywords: keywords
        $("#contents").css('background-color','#ffffff')
      , 3000
      $("#contents").css('background-color','#e0e0e0')
