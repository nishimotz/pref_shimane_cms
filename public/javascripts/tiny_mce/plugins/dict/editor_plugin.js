tinyMCE.importPluginLanguagePack('dict', 'ja');

var TinyMCE_DictPlugin = {
	getControlHTML : function(cn) {
		switch (cn) {
			case "dict":
				return tinyMCE.getButtonHTML(cn, 'lang_dict_desc', '{$pluginurl}/images/dict.gif', 'mceDict', true);
		}

		return "";
	},

	execCommand : function(editor_id, element, command, user_interface, value) {
		switch (command) {
			// Remember to have the "mce" prefix for commands so they don't intersect with built in ones in the browser.
			case "mceDict":
				// Show UI/Popup
				if (user_interface) {
					// Open a popup window and send in some custom data in a window argument
					var dict = new Array();

					dict['file'] = '/_admin/word/';
					dict['width'] = 800;
					dict['height'] = 600;

					tinyMCE.openWindow(dict, {editor_id : editor_id, scrollbars : "yes", resizable : "yes"});

					// Let TinyMCE know that something was modified
					tinyMCE.triggerNodeChange(false);
				} else {
					// Do a command this gets called from the dict popup
					alert("execCommand: mceDict gets called from popup.");
				}

				return true;
		}

		// Pass to next handler in chain
		return false;
	}
};

tinyMCE.addPlugin("dict", TinyMCE_DictPlugin);
