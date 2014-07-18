//
// jQueryを利用して書き直したもの (2011/6/11)
// 

// 
//  以下の編集はSinatraでセットされる
//  var name =  '増井研';
//  var title = 'MIRAIPEDIA';
//  var root =  'http://masui.sfc.keio.ac.jp/Gyazz';
//  var do_auth = true;

var version = -1;

var editline = -1;
var eline = -1;

var data = [];
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
        if(editline >= 0){
            addblankline(editline+1,indent(editline));
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

function hex2(v){
    v = Math.floor(v);
    if(v >= 256) v = 255;
    return ("0" + v.toString(16)).slice(-2);
}

function bgcol(t){
    var i, r, g, b;
    // データの古さに応じて行の色を変える
    var table = [
        [0,                                  256,256,256],
        [10,                                 240,240,240],
        [10*10,                              220,220,220],
        [10*10*10,                           200,200,200],
        [10*10*10*10,                        180,180,180],
        [10*10*10*10*10,                     160,160,160],
        [10*10*10*10*10*10,                  140,140,140],
        [10*10*10*10*10*10*10,               120,120,120],
        [10*10*10*10*10*10*10*10,            100,100,100],
        [10*10*10*10*10*10*10*10*10,          80, 80, 80],
        [10*10*10*10*10*10*10*10*10*10,       60, 60, 60],
        [10*10*10*10*10*10*10*10*10*10*10,    40, 40, 40]
    ];
    for(i=0;i<table.length-1;i++){
        var t1 = table[i][0];
        var t2 = table[i+1][0];
        if(t >= t1 && t <= t2){
            r = ((t - t1) * table[i+1][1] + (t2 - t) * table[i][1]) / (t2 - t1);
            r = Math.floor(r);
            if(r >= 256) r = 255;
            g = ((t - t1) * table[i+1][2] + (t2 - t) * table[i][2]) / (t2 - t1);
            g = Math.floor(g);
            if(g >= 256) g = 255;
            b = ((t - t1) * table[i+1][3] + (t2 - t) * table[i][3]) / (t2 - t1);
            b = Math.floor(b);
            if(b >= 256) b = 255;
            return "#" + hex2(r) + hex2(g) + hex2(b);
        }
    }
}

function addblankline(line,indent){
    var i;
    editline = line;
    eline = line;
    deleteblankdata();
    for(i=data.length-1;i>=editline;i--){
        data[i+1] = data[i];
    }
    var s = '';
    for(i=0;i<indent;i++) s += ' ';
    data[editline] = s;
    search();
}

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
    editline = eline;
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
        editline = eline;
        calcdoi();
        display(true);
    }
    else {
        if(editTimeout) clearTimeout(editTimeout);
        editTimeout = setTimeout(longmousedown,300);
    }
    return true;
});

function indent(line){ // 先頭の空白文字の数
    if(typeof data[line] !== "string") return 0;
    return data[line].match(/^( *)/)[1].length;
}

function movelines(line){ // 移動すべき行数
    var i;
    var ind = indent(line);
    for(i=line+1;i<data.length && indent(i) > ind;i++);
    return i-line;
}

function destline_up(){
    var ind;
    // インデントが自分と同じか自分より深い行を捜す。
    // ひとつもなければ -1 を返す。
    var ind_editline = indent(editline);
    var foundline = -1;
    for(var i=editline-1;i>=0;i--){
        ind = indent(i);
        if(ind > ind_editline){
            foundline = i;
        }
        if(ind == ind_editline) return i;
        if(ind < ind_editline) return foundline;
    }
    return foundline;
}

function destline_down(){
    var ind;
    // インデントが自分と同じ行を捜す。
    // ひとつもなければ -1 を返す。
    var ind_editline = indent(editline);
    for(var i=editline+1;i<data.length;i++){
        ind = indent(i);
        if(ind == ind_editline) return i;
        if(ind < ind_editline) return -1;
    }
    return -1;
}

$(document).keyup(function(event){
    var input = $("input#newtext");
    data[editline] = input.val();
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

    if(ck && kc == 0x53 && editline >= 0){
        transpose();
    }
    else if(kc == KC.enter){
        $('#query').val('');
        writedata();
    }
    else if(kc == KC.down && sk){ // Shift+↓ = 下にブロック移動
        if(editline >= 0 && editline < data.length-1){
            m = movelines(editline);
            dst = destline_down();
            if(dst >= 0){
                m2 = movelines(dst);
                for(i=0;i<m;i++)  tmp[i] = data[editline+i];
                for(i=0;i<m2;i++) data[editline+i] = data[dst+i];
                for(i=0;i<m;i++)  data[editline+m2+i] = tmp[i];
                editline = editline + m2;
                deleteblankdata();
                writedata();
            }
        }
    }
    else if(kc == KC.k && ck){ // Ctrl+K カーソルより右側を削除する
        var input_tag = $("input#newtext");
        if(input_tag.val().match(/^\s*$/) && editline < data.length-1){ // 行が完全に削除された時
            data[editline] = ""; // 現在の行を削除
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
    else if(kc == KC.down && ck && editline >= 0 && editline < data.length-1){ // Ctrl+↓ = 下の行と入れ替え
        current_line_data = data[editline];
        data[editline] = data[editline+1];
        data[editline+1] = current_line_data;
        setTimeout(function(){
            editline += 1;
            deleteblankdata();
            writedata();
        }, 1);
    }
    else if((kc == KC.down && !sk) || (kc == KC.n && !sk && ck)){ // ↓ = カーソル移動
        if(editline >= 0 && editline < data.length-1){
            for(i=editline+1;i<data.length;i++){
                if(doi[i] >= -zoomlevel){
                    editline = i;
                    deleteblankdata();
                    writedata();
                    break;
                }
            }
        }
    }
    else if(kc == KC.up && sk){ // 上にブロック移動
        if(editline > 0){
            m = movelines(editline);
            dst = destline_up();
            if(dst >= 0){
                m2 = editline-dst;
                for(i=0;i<m2;i++) tmp[i] = data[dst+i];
                for(i=0;i<m;i++)  data[dst+i] = data[editline+i];
                for(i=0;i<m2;i++) data[dst+m+i] = tmp[i];
                editline = dst;
                deleteblankdata();
                writedata();
            }
        }
    }
    else if(kc == KC.up && ck && editline > 0){ // Ctrl+↑= 上の行と入れ替え
        current_line_data = data[editline];
        data[editline] = data[editline-1];
        data[editline-1] = current_line_data;
        setTimeout(function(){
            editline -= 1;
            deleteblankdata();
            writedata();
        }, 1);
    }
    else if((kc == KC.up && !sk) || (kc == KC.p && !sk && ck)){ // 上にカーソル移動
        if(editline > 0){
            for(i=editline-1;i>=0;i--){
                if(doi[i] >= -zoomlevel){
                    editline = i;
                    deleteblankdata();
                    writedata();
                    break;
                }
            }
        }
    }
    if(kc == KC.tab && !sk || kc == KC.right && sk){ // indent
        if(editline >= 0 && editline < data.length){
            data[editline] = ' ' + data[editline];
            writedata();
        }
    }
    if(kc == KC.tab && sk || kc == KC.left && sk){ // undent
        if(editline >= 0 && editline < data.length){
            var s = data[editline];
            if(s.substring(0,1) == ' '){
                data[editline] = s.substring(1,s.length);
            }
            writedata();
        }
    }
    if(kc == KC.left && !sk && !ck && editline < 0){ // zoom out
        if(-zoomlevel < maxindent()){
            zoomlevel -= 1;
            display();
        }
    }
    if(kc == KC.right && !sk && !ck && editline < 0){ // zoom in
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
    else if(kc >= 0x30 && kc <= 0x7e && editline < 0 && !cd && !ck){
        $('#querydiv').css('visibility','visible').css('display','block');
        $('#query').focus();
    }
    
    if(not_saved) $("input#newtext").css('background-color','#f0f0d0');
});

function deleteblankdata(){ // 空白行を削除
    for(i=0;i<data.length;i++){
        if(typeof data[i] === "string" && data[i].match(/^ *$/)){
            data.splice(i,1);
        }
    }
    calcdoi();
}

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
            authbuf.push(data[n]);
            tell_auth();
        }
        if(event.shiftKey){
            addblankline(n,indent(n));  // 上に行を追加
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
                data = res['data'];
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
    if(editline == -1){
        deleteblankdata();
        input.css('display','none');
    }
    
    var contline = -1;
    if(data.length == 0){
        data = ["(empty)"];
        doi[0] = maxindent();
    }
    for(i=0;i<data.length;i++){
        var x;
        var ind;
        ind = indent(i);
        xmargin = ind * 30;
        
        var t = $("#list"+i);
        var p = $("#listbg"+i);
        if(doi[i] >= -zoomlevel){
            if(i == editline){ // 編集行
                t.css('display','inline').css('visibility','hidden');
                p.css('display','block').css('visibility','hidden');
                input.css('position','absolute');
                input.css('visibility','visible');
                input.css('left',xmargin+25);
                input.css('top',p.position().top);
                input.blur();
                input.val(data[i]); // Firefoxの場合日本語入力中にこれが効かないことがあるような... blurしておけば大丈夫ぽい
                input.focus();
                input.mousedown(linefunc(i));
                setTimeout(function(){ $("input#newtext").focus(); }, 100); // 何故か少し待ってからfocus()を呼ばないとフォーカスされない...
            }
            else {
                var lastchar = '';
                if(i > 0 && typeof data[i-1] === "string") lastchar = data[i-1][data[i-1].length-1];
                if(editline == -1 && lastchar == '\\'){ // 継続行
                    if(contline < 0) contline = i-1;
                    s = '';
                    for(var j=contline;j<=i;j++){
                        s += data[j].replace(/\\$/,'__newline__');
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
                    if(typeof data[i] === "string" &&
                       ( m = data[i].match(/\[\[(https:\/\/gist\.github\.com.*\?.*)\]\]/i) )){ // gistエンベッド
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
                        t.css('display','inline').css('visibility','visible').css('line-height','').html(tag(data[i],i));
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
    
    for(i=data.length;i<1000;i++){
        $('#list'+i).css('display','none');
        $('#listbg'+i).css('display','none');
    }
    
    input.css('display',(editline == -1 ? 'none' : 'block'));
    
    for(i=0;i<data.length;i++){
        posy[i] = $('#list'+i).position().top;
        //posy[i] = $("#e" + i + "_0").offset().top;
    }
    aligncolumns();
    
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

    var datastr = data.join("\n").replace(/\n+$/,'')+"\n";
    if(!force && (JSON.stringify(data) == JSON.stringify(data_old))){
        search();
        return;
    }
    data_old = data.concat();

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
            data = res['data'].concat();
            data_old = res['data'].concat();
            orig_md5 = MD5_hexhash(utf16to8(data.join("\n").replace(/\n+$/,'')+"\n"));
            search();
        },
        error: function(){
        }
    });
}

function maxindent(){
    var maxind = 0;
    for(var i=0;i<data.length;i++){
        var ind = indent(i);
        if(ind > maxind) maxind = ind;
    }
    return maxind;
}

function calcdoi(){
    var q = document.getElementById("query");
    var pbs = new POBoxSearch(assocwiki_pobox_dict);
    var re = null;
    if(q && q.value != '') re = pbs.regexp(q.value,false);
    
    var maxind = maxindent();
    for(var i=0;i<data.length;i++){
        if(re ? re.exec(data[i]) : true){
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
    editline = line;
    eline = line;
    deleteblankdata();
    for(var i=data.length-1;i>=editline;i--){
        data[i+1] = data[i];
    }
    var s = '';
    for(var i=0;i<indent;i++) s += ' ';
    s += '[[http://gyazo.com/' + id + '.png]]';
    data[editline] = s;
    search();
}

function addimage(id)
{
    var old = editline;
    if(data[0] == '(empty)'){
        data[0] = '[[http://gyazo.com/' + id + '.png]]';
    }
    else {
        editline = data.length-1;
        addimageline(editline+1,indent(editline),id);
    }
    writedata();
    editline = -1;
    display();
    editline = old;
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
            editline = data.length;
            if(filename.match(/\.(jpg|jpeg|png|gif)$/i)){
                data[editline] = '[[[' + root + "/upload/" + filename + ']]]';
            }
            else {
                data[editline] = '[[' + root + "/upload/" + filename + ' ' + file.name + ']]';
            }
            writedata();
            editline = -1;
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
    if(editline < 0) return;
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

// 右下の通知Box
$(function(){
    window.notifyBox = new (function(target){
	
	var img = $("<img>").attr("src", "/progress.png").hide();
	var textBox = $("<span>").css({margin: "5px"});
	
	var box = $("<div>").addClass("notifyBox").css({
	    position: "fixed",
	    right: "10px",
	    bottom: "10px",
	    "background-color": "#EEE"
	}).append(textBox).append(img);
	
	$("html").append(box);
	
	var self = this;
	
	this.print = function(str, opts){
	    if(!opts) opts = {};
	    textBox.text(str);
	    if(opts.progress) img.show();
	    else img.hide();
	    return self;
	};
	
	this.show = function(timeout){
	    box.show();
	    if(typeof timeout === 'number' && timeout > 0){
		setTimeout(function(){
		    box.fadeOut(800);
		}, timeout);
	    }
	    return self;
	};
	
	this.hide = function(){
	    box.hide();
	    return self;
	};
	
    })();
});
