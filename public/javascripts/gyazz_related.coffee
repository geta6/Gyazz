# リンク先アイコン表示

class GyazzRelated
  getrelated: (x) ->
    $.ajax
      type: "GET"
      async: true
      url: "/#{wiki}/#{title}/related"
      success: (pages) ->
        pages.map (page) ->
          title = page.title
          repimage = page.repimage
          imageurl = if repimage && repimage.match(/^[0-9a-f]+$/)
            "//gyazo.com/#{repimage}.png"
          else
            repimage
          url = "/#{wiki}/#{title}"
          if repimage
            iconCSS =
              'background-image': "url(#{imageurl})"

            icontext = $('<span>').addClass('icontext overimage').text(title)
            div = $('<div>').addClass('icon').css(iconCSS).append(icontext)
            $('#links').append $("<a>").attr('href',url).attr('target','_blank').append(div)
          else
            md5 = MD5_hexhash title
            r = hex2 parseInt(md5.substr(0,2),16) * 0.5 + 16
            g = hex2 parseInt(md5.substr(2,2),16) * 0.5 + 16
            b = hex2 parseInt(md5.substr(4,2),16) * 0.5 + 16
            div1 = $('<div>').addClass('icontext').text(title)
            div2 = $('<div>').addClass('icon').css('background-color',"\##{r}#{g}#{b}").append(div1)
            $('#links').append($("<a>").attr
              href:   url
              target: '_blank'
              class:  'links'
            .append(div2))
        $('#links').append $('<br clear="all">')
      error: ->
        notifyBox.print("getrelated() fail").show(1000)

window.GyazzRelated = GyazzRelated
