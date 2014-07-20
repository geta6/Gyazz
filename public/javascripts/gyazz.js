//
// jQueryを利用して書き直したもの (2011/6/11)
// 

// 
//  以下の編集はSinatraでセットされる
//  var name =  '増井研';
//  var title = 'MIRAIPEDIA';
//  var root =  'http://masui.sfc.keio.ac.jp/Gyazz';
//  var do_auth = true;

gb = new GyazzBuffer();
// var data = []; GyazzBuffer内のものを使う
// var editline = -1;

var version = -1;

var eline = -1;

var dt = [];          // 背景色
var doi = [];
var zoomlevel = 0;
var cache = {
    history : { } // #historyimageをなぞって表示するページ履歴 key:age, value:response
};

var posy = [];

var datestr = '';
var showold = false;

var reloadTimeout = null;            // 放っておくとリロードするように
var reloadInterval = 10 * 60 * 1000; // 10分ごとにリロード

var editTimeout = null;

var searchmode = false;

var orig_md5; // getdata()したときのMD5

var KC = {
    tab:9, enter:13, ctrlD:17, left:37, up:38, right:39, down:40,
    k:75, n:78, p:80
};

var authbuf = [];

$(function(){
    $('#rawdata').hide();
    setup();
    getdata({suggest: true}); // 1回目はsuggestオプションを付けてgetdata
    getrelated();
});

// keypressを定義しておかないとFireFox上で矢印キーを押してときカーソルが動いてしまう
$(document).keypress(function(event){
    var kc = event.which;
    if(kc == KC.enter)  event.preventDefault();
    if(kc == KC.enter){
        // 1行追加 
        // IME確定でもkeydownイベントが出てしまうのでここで定義が必要!
        if(gb.editline >= 0){
            addblankline(gb.editline+1,indent(gb.editline));
	    search(); // 要るのか?
            zoomlevel = 0;
            calcdoi();
            display();
        }
        return false;
    }
    // カーソルキーやタブを無効化
    if(!event.shiftKey && (kc == KC.down || kc == KC.up || kc == KC.tab)){
        return false;
    }
});

$(document).mouseup(function(event){
    if(editTimeout) clearTimeout(editTimeout);
    eline = -1;
    return true;
});

$(document).mousemove(function(event){
    if(editTimeout) clearTimeout(editTimeout);
    return true;
});

function longmousedown(){
    gb.editline = eline;
    calcdoi();
    display(true);
}                 

$(document).mousedown(function(event){
    var y;
    if(reloadTimeout) clearTimeout(reloadTimeout);
    reloadTimeout = setTimeout(reload,reloadInterval);
    
    y = event.pageY;
    if(y < 40){
        searchmode = true;
        return true;
    }
    searchmode = false;
    
    if(eline == -1){ // 行以外をクリック
	    writedata();
        gb.editline = eline;
        calcdoi();
        display(true);
    }
    else {
        if(editTimeout) clearTimeout(editTimeout);
        editTimeout = setTimeout(longmousedown,300);
    }
    return true;
});

$(document).keyup(function(event){
    var input = $("input#newtext");
    gb.data[gb.editline] = input.val();
});

var not_saved = false;

$(document).keydown(function(event){
    if(reloadTimeout) clearTimeout(reloadTimeout);
    reloadTimeout = setTimeout(reload,reloadInterval);
    
    var kc = event.which;
    var sk = event.shiftKey;
    var ck = event.ctrlKey;
    var cd = event.metaKey && !ck;
    var i;
    var m,m2;
    var dst;
    var tmp = [];
    var current_line_data;

    if(searchmode) return true;
    
    not_saved = true;

    if(ck && kc == 0x53 && gb.editline >= 0){
        gb.transpose();
    }
    else if(kc == KC.enter){
        $('#query').val('');
        writedata();
    }
    else if(kc == KC.down && sk){ // Shift+↓ = 下にブロック移動
        gb.block_down();
    }
    else if(kc == KC.k && ck){ // Ctrl+K カーソルより右側を削除する
        var input_tag = $("input#newtext");
        if(input_tag.val().match(/^\s*$/) && gb.editline < gb.data.length-1){ // 行が完全に削除された時
            gb.data[gb.editline] = ""; // 現在の行を削除
            deleteblankdata();
            writedata();
            setTimeout(function(){
                // カーソルを行頭に移動
                input_tag = $("#newtext");
                input_tag[0].selectionStart = 0;
                input_tag[0].selectionEnd = 0;
            }, 10);
            return;
        }
        setTimeout(function(){ // Mac用。ctrl+kでカーソルより後ろを削除するまで待つ
            var cursor_pos = input_tag[0].selectionStart;
            if(input_tag.val().length > cursor_pos){ // ctrl+kでカーソルより後ろが削除されていない場合
                input_tag.val( input_tag.val().substring(0, cursor_pos) ); // カーソルより後ろを削除
                input_tag.selectionStart = cursor_pos;
                input_tag.selectionEnd = cursor_pos;
            }
        }, 10);
    }
    else if(kc == KC.down && ck && gb.editline >= 0 && gb.editline < gb.data.length-1){ // Ctrl+↓ = 下の行と入れ替え
        current_line_data = gb.data[gb.editline];
        gb.data[gb.editline] = gb.data[gb.editline+1];
        gb.data[gb.editline+1] = current_line_data;
        setTimeout(function(){
            gb.editline += 1;
            deleteblankdata();
            writedata();
        }, 1);
    }
    else if((kc == KC.down && !sk) || (kc == KC.n && !sk && ck)){ // ↓ = カーソル移動
        if(gb.editline >= 0 && gb.editline < gb.data.length-1){
            for(i=gb.editline+1;i<gb.data.length;i++){
                if(doi[i] >= -zoomlevel){
                    gb.editline = i;
                    deleteblankdata();
                    writedata();
                    break;
                }
            }
        }
    }
    else if(kc == KC.up && sk){ // 上にブロック移動
        gb.block_up();
    }
    else if(kc == KC.up && ck && gb.editline > 0){ // Ctrl+↑= 上の行と入れ替え
        current_line_data = gb.data[gb.editline];
        gb.data[gb.editline] = gb.data[gb.editline-1];
        gb.data[gb.editline-1] = current_line_data;
        setTimeout(function(){
            gb.editline -= 1;
            deleteblankdata();
            writedata();
        }, 1);
    }
    else if((kc == KC.up && !sk) || (kc == KC.p && !sk && ck)){ // 上にカーソル移動
        if(gb.editline > 0){
            for(i=gb.editline-1;i>=0;i--){
                if(doi[i] >= -zoomlevel){
                    gb.editline = i;
                    deleteblankdata();
                    writedata();
                    break;
                }
            }
        }
    }
    if(kc == KC.tab && !sk || kc == KC.right && sk){ // indent
        if(gb.editline >= 0 && gb.editline < gb.data.length){
            gb.data[gb.editline] = ' ' + gb.data[gb.editline];
            writedata();
        }
    }
    if(kc == KC.tab && sk || kc == KC.left && sk){ // undent
        if(gb.editline >= 0 && gb.editline < gb.data.length){
            var s = gb.data[gb.editline];
            if(s.substring(0,1) == ' '){
                gb.data[gb.editline] = s.substring(1,s.length);
            }
            writedata();
        }
    }
    if(kc == KC.left && !sk && !ck && gb.editline < 0){ // zoom out
        if(-zoomlevel < maxindent()){
            zoomlevel -= 1;
            display();
        }
    }
    if(kc == KC.right && !sk && !ck && gb.editline < 0){ // zoom in
        //if(zoomlevel < maxindent()){
        if(zoomlevel < 0){
            zoomlevel += 1;
            display();
        }
    }
    if(ck && kc == KC.left){ // 古いバージョンゲット
        version += 1;
        getdata({version:version});
    }
    else if(ck && kc == KC.right){
        if(version >= 0){
            version -= 1;
            getdata({version:version});
        }
    }
    else if(kc >= 0x30 && kc <= 0x7e && gb.editline < 0 && !cd && !ck){
        $('#querydiv').css('visibility','visible').css('display','block');
        $('#query').focus();
    }
    
    if(not_saved) $("input#newtext").css('background-color','#f0f0d0');
});

// 認証文字列をサーバに送る
function tell_auth(){
    var authstr = authbuf.sort().join(",");
    $.ajax({
        type: "POST",
        async: false,
        url: root + "/__tellauth",
        data: {
            name: name,
            title: title,
            authstr: authstr
        }
    });
}

// こうすると動的に関数を定義できる (クロージャ)
// 行をクリックしたとき呼ばれる
function linefunc(n){
    return function(event){
        if(writable){
            eline = n;
        }
        if(do_auth){
            authbuf.push(gb.data[n]);
            tell_auth();
        }
        if(event.shiftKey){
            addblankline(n,indent(n));  // 上に行を追加
	    search();
        }
    };
}

function setup(){ // 初期化
    for(var i=0;i<1000;i++){
        var y = $('<div>').attr('id','listbg'+i);
        var x = $('<span>').attr('id','list'+i).mousedown(linefunc(i));
        $('#contents').append(y.append(x));
    }
    reloadTimeout = setTimeout(reload,reloadInterval);
    
    $('#querydiv').css('display','none');
    
    b = $('body');
    b.bind("dragover", function(e) {
        return false;
    });
    b.bind("dragend", function(e) {
        return false;
    });
    b.bind("drop", function(e) {
        var files;
        e.preventDefault(); // デフォルトは「ファイルを開く」
        files = e.originalEvent.dataTransfer.files;
        sendfiles(files);
        return false;
    });
    
    $('#historyimage').hover(
        function(){
            showold = true;
        },
        function(){
            showold = false;
            getdata();
        }
    );
    
    $('#historyimage').mousemove(
        function(event){
            var imagewidth = parseInt($('#historyimage').attr('width'));
            var age = Math.floor((imagewidth + $('#historyimage').offset().left - event.pageX) * 25 / imagewidth);

            var show_history = function(res){
                datestr = res['date'];
                dt = res['age'];
                gb.data = res['data'];
		// $('#debug').text(data.length);
                // orig_md5 = MD5_hexhash(utf16to8(data.join("\n").replace(/\n+$/,'')+"\n"));
                search();
            };

            if(cache.history[age]){
                show_history(cache.history[age]);
                return;
            }
            $.ajax({
                type: "GET",
                async: false, // こうしないと履歴表示が大変なことになるのだが...
                url: root + "/" + name + "/" + title + "/json",
                data: {
                    age: age
                },
		error: function(XMLHttpRequest, textStatus, errorThrown) {
		    alert("ERROR!");
		    //$("#XMLHttpRequest").html("XMLHttpRequest : " + XMLHttpRequest.status);
		    //$("#textStatus").html("textStatus : " + textStatus);
		    //$("#errorThrown").html("errorThrown : " + errorThrown.message);
		},
                success: function(res){
		    //alert("success age = " + age);
                    cache.history[age] = res;
                    show_history(res);
                }
	    });
        }
    );

    $('#contents').mousedown(function(event){
        if(eline == -1){ // 行以外をクリック
            writedata();
        }
    });

}

function display(delay){
    // zoomlevelに応じてバックグラウンドの色を変える
    var bgcolor = zoomlevel == 0 ? '#eeeeff' :
            zoomlevel == -1 ? '#e0e0c0' :
            zoomlevel == -2 ? '#c0c0a0' : '#a0a080';
    $("body").css('background-color',bgcolor);
    $('#datestr').text(version >= 0 || showold ? datestr : '');
    $('#title').attr('href',root + "/" + name + "/" + title + "/" + "__edit" + "/" + (version >= 0 ? version : 0));
    
    var i;
    if(delay){ // ちょっと待ってもう一度呼び出す!
        setTimeout("display()",200);
        return;
    }
    
    var input = $("input#newtext");
    if(gb.editline == -1){
        deleteblankdata();
        input.css('display','none');
    }
    
    var contline = -1;
    if(gb.data.length == 0){
        gb.data = ["(empty)"];
        doi[0] = maxindent();
    }
    for(i=0;i<gb.data.length;i++){
        var x;
        var ind;
        ind = indent(i);
        xmargin = ind * 30;
        
        var t = $("#list"+i);
        var p = $("#listbg"+i);
        if(doi[i] >= -zoomlevel){
            if(i == gb.editline){ // 編集行
                t.css('display','inline').css('visibility','hidden');
                p.css('display','block').css('visibility','hidden');
                input.css('position','absolute');
                input.css('visibility','visible');
                input.css('left',xmargin+25);
                input.css('top',p.position().top);
                input.blur();
                input.val(gb.data[i]); // Firefoxの場合日本語入力中にこれが効かないことがあるような... blurしておけば大丈夫ぽい
                input.focus();
                input.mousedown(linefunc(i));
                setTimeout(function(){ $("input#newtext").focus(); }, 100); // 何故か少し待ってからfocus()を呼ばないとフォーカスされない...
            }
            else {
                var lastchar = '';
                if(i > 0 && typeof gb.data[i-1] === "string") lastchar = gb.data[i-1][gb.data[i-1].length-1];
                if(gb.editline == -1 && lastchar == '\\'){ // 継続行
                    if(contline < 0) contline = i-1;
                    s = '';
                    for(var j=contline;j<=i;j++){
                        s += gb.data[j].replace(/\\$/,'__newline__');
                    }
                    $("#list"+contline).css('display','inline').css('visibility','visible').html(tag(s,contline).replace(/__newline__/g,''));
                    $("#listbg"+contline).css('display','inline').css('visibility','visible');
                    //t.css('display','none');
                    //p.css('display','none');
                    t.css('visibility','hidden');
                    p.css('visibility','hidden');
                }
                else { // 通常行
                    contline = -1;
                    var m;
                    if(typeof gb.data[i] === "string" &&
                       ( m = gb.data[i].match(/\[\[(https:\/\/gist\.github\.com.*\?.*)\]\]/i) )){ // gistエンベッド
                        // https://gist.github.com/1748966 のやり方
                        var gisturl = m[1];
                        var gistFrame = document.createElement("iframe");
                        gistFrame.setAttribute("width", "100%");
                        gistFrame.id = "gistFrame" + i;
                        gistFrame.style.border = 'none';
                        gistFrame.style.margin = '0';
                        t.children().remove(); // 子供を全部消す
                        t.append(gistFrame);
                        var gistFrameHTML = '<html><body onload="parent.adjustIframeSize(document.body.scrollHeight,'+i+
                                ')"><scr' + 'ipt type="text/javascript" src="' + gisturl + '"></sc'+'ript></body></html>';
                        // Set iframe's document with a trigger for this document to adjust the height
                        var gistFrameDoc = gistFrame.document;
                        if (gistFrame.contentDocument) {
                            gistFrameDoc = gistFrame.contentDocument;
                        } else if (gistFrame.contentWindow) {
                            gistFrameDoc = gistFrame.contentWindow.document;
                        }
                        
                        gistFrameDoc.open();
                        gistFrameDoc.writeln(gistFrameHTML);
                        gistFrameDoc.close(); 
                    }
                    else {
                        t.css('display','inline').css('visibility','visible').css('line-height','').html(tag(gb.data[i],i));
                        p.attr('class','listedit'+ind).css('display','block').css('visibility','visible').css('line-height','');
                    }
                }
            }
        }
        else {
            t.css('display','none');
            p.css('display','none');
        }
        
        // 各行のバックグラウンド色設定
	//alert(dt[i]);
	//alert(bgcol(dt[i]));
        $("#listbg"+i).css('background-color',(version >= 0 || showold) ? bgcol(dt[i]) : 'transparent');
        if(version >= 0){ // ツールチップに行の作成時刻を表示
            $("#list"+i).addClass('hover');
            date = new Date();
            createdate = new Date(date.getTime() - dt[i] * 1000);
            $("#list"+i).attr('title',createdate.toLocaleString());
            $(".hover").tipTip({
                maxWidth: "auto", //ツールチップ最大幅
                edgeOffset: 5, //要素からのオフセット距離
                activation: "hover", //hoverで表示、clickでも可能 
                defaultPosition: "bottom" //デフォルト表示位置
            });
        }
        else {
            $("#listbg"+i).removeClass('hover');
        }
    }
    
    for(i=gb.data.length;i<1000;i++){
        $('#list'+i).css('display','none');
        $('#listbg'+i).css('display','none');
    }
    
    input.css('display',(gb.editline == -1 ? 'none' : 'block'));
    
    for(i=0;i<gb.data.length;i++){
        posy[i] = $('#list'+i).position().top;
        //posy[i] = $("#e" + i + "_0").offset().top;
    }
    //aligncolumns();
    gb.align();
    
    // リファラを消すプラグイン
    // http://logic.moo.jp/memo.php/archive/569
    // http://logic.moo.jp/data/filedir/569_3.js
    //
    //jQuery.kill_referrer.rewrite.init();
    follow_scroll();
}

function adjustIframeSize(newHeight,i) {
    var frame= document.getElementById("gistFrame"+i);
    frame.style.height = parseInt(newHeight) + "px";
}

var data_old = [];
function writedata(force){
    not_saved = false;
    if(!writable) return;

    var datastr = gb.data.join("\n").replace(/\n+$/,'')+"\n";
    if(!force && (JSON.stringify(gb.data) == JSON.stringify(data_old))){
        search();
        return;
    }
    data_old = gb.data.concat();

    cache.history = {}; // 履歴cacheをリセット

    notifyBox.print("saving..", {progress: true}).show();
    $.ajax({
        type: "POST",
        async: false,
        url: root + "/__write",
        data: {
            name: name,
            title: title,
            orig_md5: orig_md5,
            data: datastr
        },
        beforeSend: function(xhr,settings){
            return true;
        },
        success: function(msg){
            $("input#newtext").css('background-color','#ddd');
            //$("#debug").text(msg);
            if(msg.match(/^conflict/)){
                // 再読み込み
                notifyBox.print("write conflict").show(1000);
                getdata(); // ここで強制書き換えしてしまうのがマズい? (2011/6/17)
            }
            else if(msg == 'protected'){
                // 再読み込み
                notifyBox.print("このページは編集できません").show(3000);
                getdata();
            }
            else if(msg == 'noconflict'){
                notifyBox.print("save success").show(1000);
                getdata(); // これをしないとorig_md5がセットされない
                // orig_md5 = MD5_hexhash(utf16to8(datastr)); でいいのか?
            }
            else {
                notifyBox.print("Can't find old data - something's wrong.").show(3000);
                getdata();
            }
        },
        error: function(){
            notifyBox.print("write error").show(3000);
        }
    });
}

function getdata(opts){ // 20050815123456.utf のようなテキストを読み出し
    if(opts === null || typeof opts !== 'object') opts = {};
    if(typeof opts.version !== 'number' || 0 > opts.version) opts.version = 0;
    $.ajax({
        type: "GET",
        async: true,
        url: root + "/" + name + "/" + title + "/json",
        data: opts,
        success: function(res){
            datestr = res['date'];
            dt = res['age'];
            gb.data = res['data'].concat();
            data_old = res['data'].concat();
            orig_md5 = MD5_hexhash(utf16to8(gb.data.join("\n").replace(/\n+$/,'')+"\n"));
            search();
        },
        error: function(){
        }
    });
}

function calcdoi(){
    var q = document.getElementById("query");
    var pbs = new POBoxSearch(assocwiki_pobox_dict);
    var re = null;
    if(q && q.value != '') re = pbs.regexp(q.value,false);
    
    var maxind = maxindent();
    for(var i=0;i<gb.data.length;i++){
        if(re ? re.exec(gb.data[i]) : true){
            doi[i] = maxind - indent(i);
        }
        else {
            doi[i] = 0 - indent(i) - 1;
        }
    }
}

function search(event)
{
    var kc;
    if(event) kc = event.which;
    if(event == null || kc != KC.down && kc != KC.up && kc != KC.left && kc != KC.right){
        calcdoi();
        zoomlevel = 0;
        display();
    }
    return false;
}

function addimageline(line,indent,id){
    gb.editline = line;
    eline = line;
    deleteblankdata();
    for(var i=gb.data.length-1;i>=gb.editline;i--){
        gb.data[i+1] = gb.data[i];
    }
    var s = '';
    for(var i=0;i<indent;i++) s += ' ';
    s += '[[http://gyazo.com/' + id + '.png]]';
    gb.data[gb.editline] = s;
    search();
}

function addimage(id)
{
    var old = gb.editline;
    if(gb.data[0] == '(empty)'){
        gb.data[0] = '[[http://gyazo.com/' + id + '.png]]';
    }
    else {
        gb.editline = gb.data.length-1;
        addimageline(gb.editline+1,indent(gb.editline),id);
    }
    writegb.data();
    gb.editline = -1;
    display();
    gb.editline = old;
}

// 最新のページに更新
function reload()
{
    version = -1;
    getdata();
    // display(); getdata()で呼ばれるはず
    if(reloadTimeout) clearTimeout(reloadTimeout);
    reloadTimeout = setTimeout(reload,reloadInterval);
}

function sendfiles(files){
    for (_i = 0, _len = files.length; _i < _len; _i++) {
        file = files[_i];
        sendfile(file, function(filename) {
            gb.editline = gb.data.length;
            if(filename.match(/\.(jpg|jpeg|png|gif)$/i)){
                gb.data[gb.editline] = '[[[' + root + "/upload/" + filename + ']]]';
            }
            else {
                gb.data[gb.editline] = '[[' + root + "/upload/" + filename + ' ' + file.name + ']]';
            }
            writedata();
            gb.editline = -1;
            display(true);
        });
    }
}

function sendfile(file, callback){
    var fd;
    fd = new FormData;
    fd.append('uploadfile', file);
    notifyBox.print("uploading..", {progress: true}).show();
    $.ajax({
        url: root + "/__upload",
        type: "POST",
        data: fd,
        processData: false,
        contentType: false,
        dataType: 'text',
        error: function(XMLHttpRequest, textStatus, errorThrown) {
            // 通常はここでtextStatusやerrorThrownの値を見て処理を切り分けるか、
            // 単純に通信に失敗した際の処理を記述します。
            alert('upload fail');
            notifyBox.print("upload fail").show(3000);
            // alert(XMLHttpRequest);
            // alert(textStatus);
            // alert(errorThrown);
            this; // thisは他のコールバック関数同様にAJAX通信時のオプションを示します。
        },
        success: function(data) {
            //return callback.call(this);
            notifyBox.print("upload success!!").show(1000);
            return callback(data);
        }
    });
    return false;
}

// 編集中の行が画面外に移動した時に、ブラウザをスクロールして追随する
function follow_scroll(){
    
    // 編集中かどうかチェック
    if(gb.editline < 0) return;
    if(showold) return;
    
    var currentLinePos = $("input#newtext").offset().top;
    if( !(currentLinePos && currentLinePos > 0) ) return;
    var currentScrollPos = $("body").scrollTop();
    var windowHeight = window.innerHeight;
    
    // 編集中の行が画面内にある場合、スクロールする必要が無い
    if(currentScrollPos < currentLinePos &&
       currentLinePos < currentScrollPos+windowHeight) return;
    
    $("body").stop().animate({'scrollTop': currentLinePos - windowHeight/2}, 200);
};
