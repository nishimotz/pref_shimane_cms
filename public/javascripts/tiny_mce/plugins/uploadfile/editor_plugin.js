tinyMCE.importPluginLanguagePack('uploadfile', 'ja');

var TinyMCE_UploadfilePlugin = {
	getControlHTML : function(cn) {
		switch (cn) {
			case "uploadfile":
				return tinyMCE.getButtonHTML(cn, 'lang_uploadfile_desc', '{$pluginurl}/images/uploadfile.gif', 'mceUploadfile', true);
		}

		return "";
	},

	execCommand : function(editor_id, element, command, user_interface, value) {
		switch (command) {
			// Remember to have the "mce" prefix for commands so they don't intersect with built in ones in the browser.
			case "mceUploadfile":
				// Show UI/Popup
				if (user_interface) {
					// Open a popup window and send in some custom data in a window argument
					var uploadfile = new Array();

					uploadfile['file'] = window.document.forms.EditPage.uploadfile_js_url.value;
					uploadfile['width'] = 800;
					uploadfile['height'] = 600;

					tinyMCE.openWindow(uploadfile, {editor_id : editor_id, scrollbars : "yes", resizable : "yes"});

					// Let TinyMCE know that something was modified
					tinyMCE.triggerNodeChange(false);
				} else {
					// Do a command this gets called from the uploadfile popup
					alert("execCommand: mceUploadfile gets called from popup.");
				}

				return true;
		}

		// Pass to next handler in chain
		return false;
	}
};

tinyMCE.addPlugin("uploadfile", TinyMCE_UploadfilePlugin);
