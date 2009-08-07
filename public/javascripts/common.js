function isMac() {
        if (navigator.appVersion.indexOf("Macintosh") != -1) {
                return true;
        } else {
                return false;
        }
}

function isMSIE() {
        if (navigator.appVersion.indexOf("MSIE") != -1) {
                return true;
        } else {
                return false;
        }
}

function getElement(id) {
        if(document.getElementById) {
                return document.getElementById(id);
        } else if(document.all){
                return document.all[id];
        }

}
function myEncodeURIComponent(str) {
        try {
                return encodeURIComponent(str);
        } catch(e) {
                return '';
        }
}

var m3uUri = null;
function udMenu(uri) {
	m3uUri = uri + '.m3u';
        document.write('<div class="ud_menu">');
	if (isMSIE() && !isMac() && document.all && getCookie('activex') == "on") { // IE
		document.write('<object id="MediaPlayer" classid="CLSID:22d6f312-b0f6-11d0-94ab-0080c74c7e95" codebase="http://activex.microsoft.com/activex/controls/mplayer/en/nsmp2inf.cab#Version=5,1,52,701" width="0" height="0" type="application/x-oleobject"><param name="FileName" value="' + m3uUri + '" /><param name="ShowControls" value="false" /><param name="AutoStart" value="false" /><param name="Volume" value="0" /></object>');
		document.write('<script type="text/javascript" for="MediaPlayer" event="PlayStateChange(oldState, newState)"> toggleSpeakPlayButton(oldState, newState); </script>');
		document.write('<span onclick="speak();"><img alt="よみあげ" src="/images/univ/speak.gif" /></span>');
		document.write('<div id="speak_nav" onmousedown="startMovingSpeakNav();">');
		document.write('<span class="speak_nav_button" onclick="speakPrev();"><img alt="前へ" src="/images/speak_prev.png" /></span>');
		document.write('<span class="speak_nav_button" onclick="speakPlayOrPause();"><img id="speak_play_or_stop_icon" alt="一時停止" src="/images/speak_pause.png" /></span>');
		document.write('<span class="speak_nav_button" onclick="speakNext();"><img alt="次へ" src="/images/speak_next.png" /></span>');
		document.write('<span class="speak_nav_button" onclick="speakSlow();"><img alt="遅く" src="/images/speak_slow.png" /></span>');
		document.write('<span class="speak_nav_button" onclick="speakFast();"><img alt="速く" src="/images/speak_fast.png" /></span>');
		document.write('<span class="speak_nav_button" onclick="speakClose();"><img alt="閉じる" src="/images/speak_close.png" /></span>');
		document.write('</div>');
		stickSpeakNav();
	}
	else {
		document.write('<a href="' + m3uUri + '"><img alt="よみあげ" src="/images/univ/speak.gif" /></a>');
	}
	document.write('<span id="ruby_off"><a href="javascript:changeRuby();"><img alt="ふりがなをつける" src="/images/univ/ruby_off.gif" /></a></span>',
                       '<span id="ruby_on" class="on"><a href="javascript:changeRuby();"><img alt="ふりがなをけす" src="/images/univ/ruby_on.gif" /></a></span>',
                       '<span id="large_off"><a href="javascript:changeTextSize();"><img alt="おおきく" src="/images/univ/large_off.gif" /></a></span>',
                       '<span id="large_on" class="on"><a href="javascript:changeTextSize();"><img alt="ちいさく" src="/images/univ/large_on.gif" /></a></span>',
                       '<span id="color_off"><a href="javascript:changeColor();"><img alt="いろをかえる" src="/images/univ/color_off.gif" /></a></span>',
                       '<span id="color_on"><a href="javascript:changeColor();"><img alt="いろをかえる" src="/images/univ/color_on.gif" /></a></span>',
                       '<a href="/config.html?url=' + myEncodeURIComponent(location.href) + '"><img alt="せってい" src="/images/univ/config.gif" /></a>',
                       '</div>');
}

var defaultSpeakNavTop = 15;
var speakRate = -1;
var speakNavTop = defaultSpeakNavTop;
var speakNavWidth = 343;
var speakNavOffsetX = 0;
var speakNavOffsetY = 0;
var movingSpeakNav = false;
var mpStopped = 0;
var mpPaused = 1;
var mpPlaying = 2;
var mpWaiting = 3;

function stickSpeakNav() {
	if (!movingSpeakNav) {
		var nav = getElement('speak_nav');
		nav.style.pixelTop = document.documentElement.scrollTop + speakNavTop;
	}
	setTimeout('stickSpeakNav()', 50);
}

function startMovingSpeakNav() {
	movingSpeakNav = true;
	var nav = getElement('speak_nav');
	speakNavOffsetX = nav.style.pixelLeft - event.clientX;
	speakNavOffsetY = nav.style.pixelTop - event.clientY;
	document.onmouseup = endMovingSpeakNav;
	document.onmousemove = moveSpeakNav;
	return false;
}

function endMovingSpeakNav() {
	document.onmouseup = null;
	document.onmousemove = null;
	var nav = getElement('speak_nav');
	speakNavTop = nav.style.pixelTop - document.documentElement.scrollTop;
	movingSpeakNav = false;
	return false;
}

function moveSpeakNav() {
	if (!movingSpeakNav) {
		return false;
	}
	var nav = getElement('speak_nav');
	nav.style.pixelLeft = event.clientX + speakNavOffsetX;
	nav.style.pixelTop = event.clientY + speakNavOffsetY;
	return false;
}

function speak() {
	var nav = getElement('speak_nav');
	var clientWidth = window.innerWidth ||
	                  document.documentElement.clientWidth ||
			  document.body.clientWidth;
	nav.style.pixelTop = speakNavTop = defaultSpeakNavTop;
	nav.style.pixelLeft = clientWidth - speakNavWidth - 10;
	nav.style.visibility = 'visible';
	if (speakRate == -1) {
		speakRate = MediaPlayer.Rate;
	}
	else {
		MediaPlayer.Rate = speakRate;
	}
	MediaPlayer.FileName = m3uUri;
	MediaPlayer.AutoStart = true;
	MediaPlayer.Play();
}

function toggleSpeakPlayButton(oldState, newState) {
	var icon = getElement('speak_play_or_stop_icon');
	switch (newState) {
	case mpStopped:
	case mpPaused:
		icon.alt = "再生";
		icon.src = "/images/speak_play.png";
		break;
	default:
		icon.alt = "一時停止";
		icon.src = "/images/speak_pause.png";
		break;
	}
	if (newState == mpWaiting) {
		MediaPlayer.Rate = speakRate;
	}
}

function speakPlay() {
	MediaPlayer.AutoStart = true;
	MediaPlayer.Play();
}

function speakPlayOrPause() {
	if (MediaPlayer.PlayState == mpPlaying) {
		MediaPlayer.Pause();
	}
	else {
		MediaPlayer.AutoStart = true;
		MediaPlayer.Play();
	}
}

function speakPrev() {
	MediaPlayer.Previous();
}

function speakNext() {
	MediaPlayer.Next();
}

function speakSlow() {
	if (Math.round(speakRate * 10) <= 7) {
		return;
	}
	speakRate -= 0.1;
	MediaPlayer.Rate = speakRate;
}

function speakFast() {
	if (Math.round(speakRate * 10) >= 15) {
		return;
	}
	speakRate += 0.1;
	MediaPlayer.Rate = speakRate;
}

function speakClose() {
	MediaPlayer.Stop();
	MediaPlayer.AutoStart = false;
	var nav = getElement('speak_nav');
	nav.style.visibility = 'hidden';
}

function setCookie(key, value){
	var exp = new Date();
	exp.setTime(exp.getTime() + 31536000000);
	document.cookie = escape(key) + "=" + escape(value) + "; path=/" + "; expires=" + exp.toGMTString();
}

function getCookie(key){
	var cklng = document.cookie.length;
	var ckary = document.cookie.split("; ");
	var value = "";
	var match_key = escape(key) + "=";
	var match_length = match_key.length;
	var i = 0;
	while (ckary[i]){
		if (ckary[i].substr(0,match_length) == match_key){
			value = ckary[i].substr(match_length,ckary[i].length);
			break;
		}
		i++;
	}
	return unescape(value);
}

function changeTextSize(){
        var size;
	var currentSize = document.getElementsByTagName("body")[0].style.fontSize;
	if (currentSize == "200%") {
		size = "300%";
	} else if (currentSize == "300%") {
		size = "100%";
	} else {
		size = "200%";
	}
	setTextSize(size);
	location.reload(); // for IE...
}

function setTextSize(size){
	if ( size == "300%" ){
		getElement("large_off").style.display = 'none';
		getElement("large_on").style.display = 'inline';
	} else {
		getElement("large_off").style.display = 'inline';
		getElement("large_on").style.display = 'none';
	}
	document.getElementsByTagName("body")[0].style.fontSize = size;
	setCookie('size', size);
}

function changeRuby(){
	if (navigator.appCodeName.match(/.*Safari.*/)) {

        } else {
	    var ruby = getCookie('ruby');
	    if (ruby != 'on'){
		setCookie('ruby', 'on');
	    } else {
		setCookie('ruby', 'off');
	    }
	    location.reload(true);
	}
}

function changeColor(){
	var css = getCookie('css');
	if (css == 'hc') {
		setCookie('css', 'lc');
	} else if (css == 'lc') {
		setCookie('css', 'default');
	} else {
		setCookie('css', 'hc');
	}
	location.reload(true);
}

function loadCookie() {
        loadedCookies();
        initBannerAd();
        // do not activate round corner on  Mac IE
        if (!isMac() || !isMSIE()) initRoundCorner();
        try {   // when top page
                initEqualHeightBox();
        } catch(e) {
                ;  // do nothing.
        }
}

function initEqualHeightBox() {
        var equalHeight = new EqualHeightBox(["first", "second", "list"]);
        equalHeight.equalize();
        window.onresize = function() {
                equalHeight.equalize();
        };
}

function initBannerAd() {
        var banner_image = getElement("header_banner_image");
        var link = getElement("header_banner_anchor");
        if(banner_image && link) {
                var bannerCount = Math.floor(Math.random() * BANNERS.length);
                banner_image.setAttribute('src', BANNERS[bannerCount].image);
                banner_image.setAttribute('alt', BANNERS[bannerCount].alt);
                link.setAttribute('href', BANNERS[bannerCount].url);
        }
}

function loadCookiePolice() {
        loadedCookies();
}

function loadedCookies() {
	var path = window.location.href;
	var file = path.substring(path.lastIndexOf('/',path.length)+1,path.length); 
	var ruby = getCookie('ruby');
        if ((file.match(/.*html.r/)) && (!ruby)) {
		if (!navigator.cookieEnabled) {
			return;
		}
		setCookie('ruby', 'off');
//		location.reload(true);
		getElement("ruby_off").style.display = 'inline';
		getElement("ruby_on").style.display = 'none';
	} else {
		ruby = getCookie('ruby');
		if (ruby != 'on'){
			if (document.getElementsByTagName('ruby').length != 0) {
//				location.reload(true);
			}
			getElement("ruby_off").style.display = 'inline';
			getElement("ruby_on").style.display = 'none';
		} else {
		    if (document.getElementsByTagName('ruby').length != 0) {
//			location.reload(true);
		    }
		    getElement("ruby_off").style.display = 'none';
		    getElement("ruby_on").style.display = 'inline';
		}
		var size = getCookie('size');
		if (size != "") {
			setTextSize(size);
		}
		var style = getCookie('css');
                if (style != "" && style != "default") {
			setColorStyle(style);
		}
	}
}

// Color change used to be done by web server, but for the unknown reason
// clients conneted to www1 server don't get color changed, so we compliment
// the server by changing the link to stylesheet according to the color
// value of the cookie.
function setColorStyle(style) {
        // change univ icon.
        getElement("color_on").style.display = 'inline';
        getElement("color_off").style.display = 'none';

        // change stylesheet link's hrefl.
	var link_tags = document.getElementsByTagName("link");
	for (var i = 0; i < link_tags.length; i++) {
		if (isColorCSSLink(link_tags[i])) {
			var css_path = link_tags[i].getAttribute('href');
			var new_css = css_path.substring(0, css_path.lastIndexOf('/')+1) + style + '.css'; 
			link_tags[i].setAttribute('href',new_css);
		}
	}
}

function isColorCSSLink(link_tag) {
	if (link_tag.getAttribute('type') == 'text/css' && link_tag.getAttribute('title') == 'カラー') {
		return true;
	} else {
		return false;
	}
}

function reload() {
	if (getCookie('reload') == 't') {
		setCookie('reload', '');
		location.reload(true);
	}
}

reload();

// vim: set sw=4 ts=4 noexpandtab :
