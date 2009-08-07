var url = tinyMCE.getParam("external_image_list_url");
if (url != null) {
	// Fix relative
	if (url.charAt(0) != '/' && url.indexOf('://') == -1)
		url = tinyMCE.documentBasePath + "/" + url;

	document.write('<sc'+'ript language="javascript" type="text/javascript" src="' + url + '"></sc'+'ript>');
}

function insertImage() {
	var src = document.forms[0].src.value;
	var alt = document.forms[0].alt.value;
	if (!alt) {
		alert(tinyMCE.getLang('lang_insert_image_missing_alt'));
		return;
	}
	var border = document.forms[0].border.value;
	var vspace = document.forms[0].vspace.value;
	var hspace = document.forms[0].hspace.value;
	var width = document.forms[0].width.value;
	var height = document.forms[0].height.value;
	var align = document.forms[0].align.options[document.forms[0].align.selectedIndex].value;

	tinyMCEPopup.restoreSelection();
	tinyMCE.themes['advanced']._insertImage(src, alt, border, hspace, vspace, width, height, align);
	tinyMCEPopup.close();
}

function init() {
	tinyMCEPopup.resizeToInnerSize();

	document.getElementById('srcbrowsercontainer').innerHTML = getBrowserHTML('srcbrowser','src','image','theme_advanced_image');

	var formObj = document.forms[0];

	for (var i=0; i<document.forms[0].align.options.length; i++) {
		if (document.forms[0].align.options[i].value == tinyMCE.getWindowArg('align'))
			document.forms[0].align.options.selectedIndex = i;
	}

	formObj.src.value = tinyMCE.getWindowArg('src');
	formObj.alt.value = tinyMCE.getWindowArg('alt');
	formObj.border.value = tinyMCE.getWindowArg('border');
	formObj.vspace.value = tinyMCE.getWindowArg('vspace');
	formObj.hspace.value = tinyMCE.getWindowArg('hspace');
	formObj.width.value = tinyMCE.getWindowArg('width');
	formObj.height.value = tinyMCE.getWindowArg('height');
	formObj.insert.value = tinyMCE.getLang('lang_' + tinyMCE.getWindowArg('action'), 'Insert', true); 

	// Handle file browser
	if (isVisible('srcbrowser'))
		document.getElementById('src').style.width = '180px';

	// Auto select image in list
	if (typeof(tinyMCEImageList) != "undefined" && tinyMCEImageList.length > 0) {
		for (var i=0; i<formObj.image_list.length; i++) {
			if (formObj.image_list.options[i].value == tinyMCE.getWindowArg('src'))
				formObj.image_list.options[i].selected = true;
		}
	}
	initImageData();
}

var preloadImg = new Image();

function resetImageData() {
	var formObj = document.forms[0];
	formObj.width.value = formObj.height.value = "";	
}

function updateImageData() {
	var formObj = document.forms[0];

	formObj.width.value = preloadImg.width;
	formObj.height.value = preloadImg.height;
	changeImageSize();
}

function initImageData() {
 	preloadImg = new Image();
	tinyMCE.addEvent(preloadImg, "load", getImagePreview);
 	tinyMCE.addEvent(preloadImg, "error", function () {var formObj = document.forms[0];formObj.width.value = formObj.height.value = "";});
 	preloadImg.src = tinyMCE.convertRelativeToAbsoluteURL(tinyMCE.settings['base_href'], document.forms[0].src.value);
 }

function getImageData() {
	initImageData();
	tinyMCE.addEvent(preloadImg, "load", updateImageData);
}

function getImagePreview(){
//add preview -- added by John Butler :: Event Ireland
	preview = new Image();
	preview=document.images[0];
	preview.style.display = 'inline';
	preview_max=100; //you can change this if necessary
	preview.src=preloadImg.src;
	var temp_width=preloadImg.width;
	var temp_height=preloadImg.height;

	//resize images to fit in preview
	//aspect ratio is maintained
	if(temp_width<=preview_max && temp_height<=preview_max){
		;
	} 
	else{
		if(temp_width==temp_height){
			temp_width=preview_max;
			temp_height=preview_max;
		}
		else if(temp_width > temp_height){
			temp_height=(temp_height * preview_max) / temp_width;
			temp_width=preview_max;
		}
		else{
			temp_width=(temp_width * preview_max) / temp_height;
			temp_height=preview_max;
		}

	}
	preview.width=temp_width;
	preview.height=temp_height;
	temp_width=0;
	temp_height=0;
}

function changeImageSize() {
	var scale = parseFloat(document.forms[0].scale.value);
	if (preloadImg.width && preloadImg.height) {
		document.forms[0].width.value = Math.round(preloadImg.width * scale /100);
		document.forms[0].height.value = Math.round(preloadImg.height * scale /100);
	}
}
