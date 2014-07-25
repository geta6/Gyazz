socket = io()

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
    datastr = $('#contents').val().replace(/\n+$/,'')+"\n"
    socket.emit 'write',
      wiki:  wiki
      title: title
      data:  datastr
    $("#contents").css('background-color','#ffffff')
  , 3000
  $("#contents").css('background-color','#e0e0e0')
