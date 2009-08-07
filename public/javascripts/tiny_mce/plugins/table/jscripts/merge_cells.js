function init() {
	tinyMCEPopup.resizeToInnerSize();

	var formObj = document.forms[0];

	formObj.numcols.value = tinyMCE.getWindowArg('numcols', 1);
	formObj.numrows.value = tinyMCE.getWindowArg('numrows', 1);
}

function mergeCells() {
	var args = new Array();
	var formObj = document.forms[0];

	args["numcols"] = formObj.numcols.value;
	args["numrows"] = formObj.numrows.value;

	if (parseInt(args["numcols"]) > 0 && parseInt(args["numrows"]) > 0) {
		tinyMCEPopup.execCommand("mceTableMergeCells", false, args);
		tinyMCEPopup.close();
	} else {
		alert("1以上の数を指定してください");
	}
}
