/* Import plugin specific language pack */
tinyMCE.importPluginLanguagePack('plugin', 'ja');

var TinyMCE_PluginPlugin = {
	getControlHTML : function(cn) {
		switch (cn) {
			case "plugin":
				return tinyMCE.getButtonHTML(cn, 'lang_plugin_desc', '{$pluginurl}/images/plugin.gif', 'mcePlugin', true);
		}

		return "";
	},

	execCommand : function(editor_id, element, command, user_interface, value) {
		switch (command) {
			case "mcePlugin":
				var name = "", swffile = "", swfwidth = "", swfheight = "", action = "insert";
				var template = new Array();
				var inst = tinyMCE.getInstanceById(editor_id);
				var focusElm = inst.getFocusElement();
	
				template['file']   = '../../plugins/plugin/plugin.htm'; // Relative to theme
				template['width']  = 355;
				template['height'] = 205;
	
				template['width'] += tinyMCE.getLang('lang_plugin_delta_width', 0);
				template['height'] += tinyMCE.getLang('lang_plugin_delta_height', 0);
	
				tinyMCE.openWindow(template, {editor_id : editor_id, inline : "yes"});
			return true;
		 }
	
		 // Pass to next handler in chain
		 return false;
	}
};

tinyMCE.addPlugin("plugin", TinyMCE_PluginPlugin);
