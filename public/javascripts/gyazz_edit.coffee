socket = io()
gt = new GyazzTag

$ ->
  opts = {version: version}
  
  socket.on 'pagedata', (res) =>
    if res.wiki == wiki && res.title == title
      $('#contents').val res.data.join("\n")

  socket.emit 'read',
    wiki:  wiki
    title: title
    opts:  opts

$(document).keyup (event) ->
  clearTimeout timeout if timeout?
  timeout = setTimeout ->
    contents = $('#contents').val()
    datastr = contents.replace(/\n+$/,'')+"\n"
    keywords = _.flatten contents.split(/\n/).map (line) =>
      gt.keywords(line, wiki, title, 0)
    socket.emit 'write',
      wiki:     wiki
      title:    title
      data:     datastr
      keywords: keywords
    $("#contents").css('background-color','#ffffff')
  , 3000
  $("#contents").css('background-color','#e0e0e0')
