#
# Gyazzタグの解析
#
tag = (s,line) ->
  # [[....]], [[[...]]]を[解析]
  return if typeof s != "string"
  matched = []
  s = s.replace /</g,'&lt'
  
  while m = s.match /^(.*)\[\[\[(([^\]]|\][^\]]|[^\]]\])*)\]\]\](.*)$/ # [[[....]]]
    [x, pre, inner, x, post] = m
    switch
      when t = inner.match /^(https?:\/\/[^ ]+) (.*)\.(jpg|jpeg|jpe|png|gif)$/i # [[[http:... ....jpg]]]
        matched.push "<a href='#{t[1]}'><img src='#{t[2]}.#{t[3]} border='none' target='_blank' height=80></a>"
      when t = inner.match /^(https?:\/\/.+)\.(jpg|jpeg|jpe|png|gif)$/i  # [[[http...jpg]]]
        matched.push "<a href='#{t[1]}.#{t[2]} target='_blank'><img src='#{t[1]}.#{t[2]} border='none' height=80></a>"
      else  # [[[abc]]]
        matched.push "<b>#{inner}</b>"
    s = "#{pre}<<<#{matched.length-1}>>>#{post}"

  while m = s.match /^(.*)\[\[(([^\]]|\][^\]]|[^\]]\])*)\]\](.*)$/ # [[....]]
    [x, pre, inner, x, post] = m
    switch
      when t = inner.match /^(http[^ ]+) (.*)\.(jpg|jpeg|jpe|png|gif)$/i # [[http://example.com/ http://example.com/abc.jpg]]
        matched.push "<a href='#{t[1]}' target='_blank'><img src='#{t[2]}.#{t[3]} border='none'></a>"
      when t = inner.match /^(http.+)\.(jpg|jpeg|jpe|png|gif)$/i # [[http://example.com/abc.jpg]
        matched.push "<a href='#{t[1]}.#{t[2]}' target='_blank'><img src='#{t[1]}.#{t[2]}' border='none'></a>"
      when t = inner.match /^(.+)\.(png|icon)$/i # ページ名.icon or ページ名.pngでアイコン表示
        link_to = null
        img_url = null
        if t[1].match /^@[\da-z_]+$/i
          screen_name = t[1].replace(/^@/,"")
          link_to = "http://twitter.com/#{screen_name}"
          img_url = "http://twiticon.herokuapp.com/#{screen_name}/mini"
        else
          link_to = "#{root}/#{name}/#{t[1]}"
          img_url = "#{link_to}/icon"
        matched.push "<a href='#{link_to}' class='link' target='_blank'><img src='#{img_url}' class='icon' height='24' border='0' alt='#{link_to}' title='#{link_to}' /></a>"
      when t = inner.match /^(.+)\.(png|icon|jpe?g|gif)[\*x×]([1-9][0-9]*)(|\.[0-9]+)$/ # (URL|ページ名).(icon|png)x個数 でアイコンをたくさん表示 ???? 上と共通では?
        link_to = null
        img_url = null
        switch
          when t[1].match /^@[\da-z_]+$/i
            screen_name = t[1].replace(/^@/,"")
            link_to = "http://twitter.com/#{screen_name}"
            img_url = "http://twiticon.herokuapp.com/#{screen_name}/mini"
          when t[1].match /^https?:\/\/.+$/
            img_url = link_to = "#{t[1]}.#{t[2]}
          else
            link_to = "#{root}/#{name}/#{t[1]}"
            img_url = "#{link_to}/icon"
        count = Number(t[3])
        icons = "<a href='#{link_to}' class='link' target='_blank'>"
        [0...count].map (i) ->
          icons += "<img src='#{img_url}' class='icon' height='24' border='0' alt='#{t[1]}' title='#{t[1]}' />"
        if t[4].length > 0
          odd = Number("0"+t[4])
          icons += "<img src='#{img_url}' class='icon' height='24' width='#{24*odd}' border='0' alt='#{link_to}' title='#{link_to}' />"
        icons += '</a>'
        matched.push icons
      when t = inner.match /^((http[s]?|javascript):[^ ]+) (.*)$/ # [[http://example.com/ example]]
        target = t[1].replace /"/g, '%22'
        matched.push "<a href='#{target}' target='_blank'>#{t[3]}</a>"
      when t = inner.match /^((http[s]?|javascript):[^ ]+)$/ # [[http://example.com/]]
        target = t[1].replace /"/g, '%22'
        matched.push "<a href='#{target}' class='link' target='_blank'>#{t[1]}</a>"
      when t = inner.match /^@([a-zA-Z0-9_]+)$/ # @名前 を twitterへのリンクにする
        matched.push "<a href='http://twitter.com/#{t[1]}' class='link' target='_blank'>@#{t[1]}</a>"
      when t = inner.match /^(.+)::$/ #  Wikiname:: で他Wikiに飛ぶ (2011 4/17)
        matched.push "<a href='#{root}/#{t[1]}' class='link' target='_blank' title='#{t[1]}'>#{t[1]}</a>"
      when t = inner.match /^(.+):::(.+)$/ #  Wikiname:::Title で他Wikiに飛ぶ (2010 4/27)
        wikiname = t[1]
        wikititle = t[2]
        url = "#{root}/#{wikiname}/#{encodeURIComponent(wikititle).replace(/%2F/g,"/")}"
        matched.push "<a href='#{url}' class='link' target='_blank' title='#{wikititle}'#{wikititle}</a>"
      when t = inner.match /^(.+)::(.+)$/ #  Wikiname::Title で他Wikiに飛ぶ (2010 4/27)
        wikiname = t[1]
        wikititle = t[2]
        wikiurl = "#{root}/#{wikiname}/"
        url = "#{root}/#{wikiname}/#{encodeURIComponent(wikititle).replace(/%2F/g,"/")}"
        matched.push "<a href='#{wikiurl}' class='link' target='_blank' title='#{wikiname}'>#{wikiname}" +
               "</a>::<a href='#{url}' class='link' target='_blank' title='#{wikititle}'>#{wikititle}</a>"
      when t = inner.match /^([a-fA-F0-9]{32})\.(\w+) (.*)$/ # (MD5).ext をmasui.sfcにリンク
        matched.push "<a href='http://masui.sfc.keio.ac.jp/#{t[1]}.#{t[2]}' class='link'>#{t[3]}</a>"

      # googlemapの表示
      # [[E135.0W35.0]] や [[W35.0.0E135.0.0Z12]] のような記法で地図を表示
      when inner.match /^([EW]\d+\.\d+[\d\.]*[NS]\d+\.\d+[\d\.]*|[NS]\d+\.\d+[\d\.]+[EW]\d+\.\d+[\d\.]*)(Z\d+)?$/
        o = parseloc(inner)
        s = """
          <div id='map' style='width:300px;height:300px'></div>
          <div id='line1' style='position:absolute;width:300px;height:4px;background-color:rgba(200,200,200,0.3);'></div>
          <div id='line2' style='position:absolute;width:4px;height:300px;background-color:rgba(200,200,200,0.3);'></div>
          <script type='text/javascript'>
          var mapOptions = {
            center: new google.maps.LatLng(#{o.lat},#{o.lng}),
            zoom: #{+o.zoom},
            mapTypeId: google.maps.MapTypeId.ROADMAP
          };
          var mapdiv = document.getElementById('map');
          var map = new google.maps.Map(mapdiv,mapOptions);
          var linediv1 = document.getElementById('line1');
          var linediv2 = document.getElementById('line2');
          google.maps.event.addListener(map, 'idle', function() {
            linediv1.style.top = mapdiv.offsetTop+150-2;
            linediv1.style.left = mapdiv.offsetLeft;
            linediv2.style.top = mapdiv.offsetTop;
            linediv2.style.left = mapdiv.offsetLeft+150-2;
          });
          google.maps.event.addListener(map, 'mouseup', function() {
          var latlng = map.getCenter();
          var o = {};
          o.lng = latlng.lng();
          o.lat = latlng.lat();
          o.zoom = map.getZoom();
          for(var i=0;i<data.length;i++){
            data[i] = data[i].replace(/\\[\\[([EW]\\d+\\.\\d+[\\d\\.]*[NS]\\d+\\.\\d+[\\d\\.]*|[NS]\\d+\\.\\d+[\\d\\.]+[EW]\\d+\\.\\d+[\\d\\.]*)(Z\\d+)?\\]\\]/,'[['+locstr(o)+']]');
          }
          writedata();
        });
        """
        matched.push s

      else
        matched.push "<a href='#{root}/#{name}/#{inner}' class='tag' target='_blank'>#{inner}</a>"

    s = pre + '<<<' + (matched.length-1) + '>>>' + post;

  elements = s.split ' '
  spaces[line] = elements.length - indent(line) - 1
  [0...elements.length].map (i) ->
    while a = elements[i].match /^(.*)<<<(\d+)>>>(.*)$/
      elements[i] = a[1] + matched[a[2]] + a[3]
  [0...elements.length].map (i) ->
    elements[i] = "<span id='e#{line}+'_'#{i}'>#{elements[i]}</span>" # 各要素にidをつける jQuery風にすべき***

  elements.join ' '
