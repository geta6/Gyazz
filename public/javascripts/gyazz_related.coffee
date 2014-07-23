# リンク先アイコン表示

class GyazzRelated
  getrelated: (x) ->
    $.ajax
      type: "GET"
      async: true
      url: "#{root}/#{name}/#{title}/related"
      success: (pages) ->
        pages.map (page) ->
          title = page.title
          repimage = page.repimage
          imageurl = "http://Gyazo.com/#{repimage}.png"
          url = "/#{name}/#{title}"
          if repimage
            img = $('<img>').attr
              src: imageurl
              title: title
            .css
              'max-height':'64'
              border:'none'
              width:'64'
  
            center = $('<center>').append img
            div = $('<div>').addClass('icon').append(center)
            $('#links').append $("<a>").attr('href',url).attr('target','_blank').append(div)
          else
            md5 = MD5_hexhash title
            r = hex2 parseInt(md5.substr(0,2),16) * 0.5 + 16
            g = hex2 parseInt(md5.substr(2,2),16) * 0.5 + 16
            b = hex2 parseInt(md5.substr(4,2),16) * 0.5 + 16
            div1 = $('<div>').addClass('icontext').text(title)
            div2 = $('<div>').addClass('icon').css('background-color','#'+r+g+b).append(div1)
            $('#links').append($("<a>").attr
              href: url
              target: '_blank'
              class: 'links'
            .append(div2))
      error: ->
        notifyBox.print("getrelated() fail").show(1000)

window.GyazzRelated = GyazzRelated

