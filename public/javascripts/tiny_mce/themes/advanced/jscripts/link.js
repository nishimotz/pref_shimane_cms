var url = tinyMCE.getParam("external_link_list_url");
if (url != null) {
	// Fix relative
	if (url.charAt(0) != '/' && url.indexOf('://') == -1)
		url = tinyMCE.documentBasePath + "/" + url;

	document.write('<sc'+'ript language="javascript" type="text/javascript" src="' + url + '"></sc'+'ript>');
}

var url = tinyMCE.getParam("external_file_list_url");
if (url != null) {
	// Fix relative
	if (url.charAt(0) != '/' && url.indexOf('://') == -1)
		url = tinyMCE.documentBasePath + "/" + url;

	document.write('<sc'+'ript language="javascript" type="text/javascript" src="' + url + '"></sc'+'ript>');
}

var url = tinyMCE.getParam("external_popup");
if (url != null) {
	// Fix relative
	if (url.charAt(0) != '/' && url.indexOf('://') == -1)
		url = tinyMCE.documentBasePath + "/" + url;

	document.write('<sc'+'ript language="javascript" type="text/javascript" src="' + url + '"></sc'+'ript>');
}

function init() {
	tinyMCEPopup.resizeToInnerSize();

	document.getElementById('hrefbrowsercontainer').innerHTML = getBrowserHTML('hrefbrowser','href','file','theme_advanced_link');

	// Handle file browser
	if (isVisible('hrefbrowser'))
		document.getElementById('href').style.width = '180px';

	var formObj = document.forms[0];

	for (var i=0; i<document.forms[0].target.options.length; i++) {
		var option = document.forms[0].target.options[i];

		if (option.value == tinyMCE.getWindowArg('target'))
			option.selected = true;
	}

	document.forms[0].href.value = tinyMCE.getWindowArg('href');
	document.forms[0].linktitle.value = tinyMCE.getWindowArg('title');
	document.forms[0].insert.value = tinyMCE.getLang('lang_' + tinyMCE.getWindowArg('action'), 'Insert', true); 

	addClassesToList('styleSelect', 'theme_advanced_link_styles');
	selectByValue(formObj, 'styleSelect', tinyMCE.getWindowArg('className'), true);

	// Hide css select row if no CSS classes
	if (formObj.styleSelect && formObj.styleSelect.options.length <= 1) {
		var sr = document.getElementById('styleSelectRow');
		sr.style.display = 'none';
		sr.parentNode.removeChild(sr);
	}

	// Auto select link in list
	var href = tinyMCE.getWindowArg('href');
	var dirname = href.replace(/[^\/]*$/, '');
	if (typeof(tinyMCELinkList) != "undefined" && tinyMCELinkList.length > 0) {
		var formObj = document.forms[0];

		for (var i=0; i<formObj.genre_list.length; i++) {
			if (formObj.genre_list.options[i].value == dirname) {
				formObj.genre_list.options[i].selected = true;
				genre_list_change();
				formObj.href.value = href;
				for (var j=0; j<formObj.link_list.length; j++) {
					if (formObj.link_list.options[j].value == href)
						formObj.link_list.options[j].selected = true;
				}
			}
		}
	}

	// Auto select link in file list
	if (typeof(tinyMCEFileList) != "undefined" && tinyMCEFileList.length > 0) {
		var formObj = document.forms[0];

		for (var i=0; i<formObj.file_list.length; i++) {
			if (formObj.file_list.options[i].value == tinyMCE.getWindowArg('href'))
				formObj.file_list.options[i].selected = true;
		}
	}
}

function insertLink() {
	var href = document.forms[0].href.value;
	var target = document.forms[0].target.options[document.forms[0].target.selectedIndex].value;
	var title = document.forms[0].linktitle.value;
	var style_class = document.forms[0].styleSelect ? document.forms[0].styleSelect.value : "";
	var dummy;

	// Make anchors absolute
	if (href.charAt(0) == '#')
		href = tinyMCE.settings['document_base_url'] + href;

	if (target == '_self')
		target = '';

	tinyMCEPopup.restoreSelection();
	tinyMCE.themes['advanced']._insertLink(href, target, title, dummy, style_class);
	tinyMCEPopup.close();
}

function genre_list_change() {
	var selection = document.getElementById('genre_list');
	var target = document.getElementById('link_list_select');
	var genre_index = selection.selectedIndex
	selection.form.href.value=selection.options[genre_index].value;
	selection.form.file_list.options[0].selected = true;

	try {
		var page_list = tinyMCELinkList[genre_index-1][2];
	} catch(e) {
		return;
	}
	var html = "";
	html += '<select id="link_list" name="link_list" style="width: 400px" onchange="link_list_change(this)">';
	html += '<option value="'+tinyMCELinkList[genre_index-1][1]+'">---</option>';
	for (var i=0; i<page_list.length; i++) {
		var page_title = page_list[i][0];
		var page_path = page_list[i][1];
		html += '<option value="' + page_path + '">' + page_title + ' (' + page_path + ')</option>';
	}
	html += '</select>'
	target.innerHTML = html;
}

function link_list_change(selection) {
	selection.form.href.value=selection.options[selection.selectedIndex].value;
	selection.form.file_list.options[0].selected = true;
}

function file_list_change(selection) {
	selection.form.href.value=selection.options[selection.selectedIndex].value;
	selection.form.genre_list.options[0].selected = true;
	var target = document.getElementById('link_list_select');
	var html = "";
	html += '<select id="link_list" name="link_list" style="width: 400px" onchange="link_list_change(this)">';
	html += '<option value="">---</option>';
	html += '</select>'
	target.innerHTML = html;
}
