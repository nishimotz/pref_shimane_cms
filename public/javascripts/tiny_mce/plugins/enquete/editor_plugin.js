/* Import plugin specific language pack */
tinyMCE.importPluginLanguagePack('enquete', 'ja');

var TinyMCE_EnquetePlugin = {
	getControlHTML : function(cn) {
		switch (cn) {
			case "enquete":
				return tinyMCE.getButtonHTML(cn, 'lang_enquete_desc', '{$pluginurl}/images/enquete.gif', 'mceEnquete', true);
		}

		return "";
	},

	execCommand : function(editor_id, element, command, user_interface, value) {
		switch (command) {
			case "mceEnquete":
				var name = "", swffile = "", swfwidth = "", swfheight = "", action = "insert";
				var template = new Array();
				var inst = tinyMCE.getInstanceById(editor_id);
				var focusElm = inst.getFocusElement();

				template['file']   = '../../plugins/enquete/enquete.htm'; // Relative to theme
				template['width']  = 355;
				template['height'] = 305;

				template['width'] += tinyMCE.getLang('lang_plugin_delta_width', 0);
				template['height'] += tinyMCE.getLang('lang_plugin_delta_height', 0);

				tinyMCE.openWindow(template, {editor_id : editor_id, inline : "yes"});
			return true;
		 }

		 // Pass to next handler in chain
		 return false;
	}
};

tinyMCE.addPlugin("enquete", TinyMCE_EnquetePlugin);
