socket = io()

$ ->
  opts = {version: 0}
  
  socket.on 'pagedata', (res) =>
    # alert "pagedata received... data = #{res.data}"
    if res.wiki == name && res.title == title
      $('#contents').val res.data.join("\n")

  socket.emit 'read',
    wiki:  name
    title: title
    opts:  opts

$(document).keyup (event) ->
  clearTimeout timeout if timeout?
  timeout = setTimeout ->
    datastr = $('#contents').val().replace(/\n+$/,'')+"\n"
    socket.emit 'write',
      wiki:  name
      title: title
      data:  datastr
    $("#contents").css('background-color','#ffffff')
  , 2000
  $("#contents").css('background-color','#f0f0f0')
