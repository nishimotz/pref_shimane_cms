function change(part) {
	var value = part.options[part.selectedIndex].value;
	document.getElementById("plugin_info").innerHTML = info(value);
	if (value == 'counter') {
		document.getElementById("plugin_format").value = "<%= plugin('" + value + "', 0) %>";
	} else {
		document.getElementById("plugin_format").value = "<%= plugin('" + value + "') %>";
	}
}

function info(name) {
	switch(name) {
		case "section_top_list":
			return "分野別情報（所属に割り当てられたジャンルの一覧）を表示します。<br />主に所属のトップページで使用します。";
		case "section_news":
			return "所属の新着情報を表示します。<br />主に所属のトップページで使用します。";
		case "genre_news_list":
			return "現在のジャンル以下にあるページの新着情報を表示します。<br />主にジャンルのindexページで使用します。";
		case "genre_list":
			return "現在のジャンルにある下位ジャンルの一覧を表示します。<br />主にジャンルのindexページで使用します。";
		case "page_list":
			return "現在のジャンルにあるページの一覧を表示します。<br />主にジャンルのindexページで使用します。";
		default:
			return "<br />";
	}
}

function init() {
	tinyMCEPopup.resizeToInnerSize();
}

function insertPlugin() {
	var formObj = document.forms[0];
	if (tinyMCE.isMSIE) {
		var plugin_format = formObj.plugin_format.value.replace(/</, "&lt;").replace(/>/, "&gt;");
	} else {
		var plugin_format = formObj.plugin_format.value;
	}
	tinyMCEPopup.execCommand("mceInsertContent", true, plugin_format);
	tinyMCEPopup.close();
}
