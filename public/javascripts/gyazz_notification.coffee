#
# 右下の通知Box
#
$ ->
  window.notifyBox = new ((target) ->
    img = $("<img>").attr("src","/progress.png").hide()
    textBox = $("<span>").css({margin: "5px"})
  
    box = $("<div>").addClass("notifyBox").css
      position: "fixed"
      right: "10px"
      bottom: "10px"
      "background-color": "#EEE"
    .append(textBox).append(img)
  
    $("html").append(box)
  
    self = this
    this.print = (str, opts) ->
      opts = {} unless opts
      textBox.text str
      if opts.progress
        img.show()
      else
        img.hide()
      self
  
    this.show = (timeout) ->
      box.show()
      if typeof timeout == 'number' && timeout > 0
        setTimeout () ->
          box.fadeOut 800
        , timeout

      self
  
    this.hide = () ->
      box.hide()
      self

    self
    )()
