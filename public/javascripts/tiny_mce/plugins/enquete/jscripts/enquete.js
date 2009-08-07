function change(part) {
        var enquete = part.options[part.selectedIndex].value;
	document.getElementById("mail_display").style.display = "none";
	document.getElementById("mail_display2").style.display = "none";
	document.getElementById("mail_display3").style.display = "none";
	document.getElementById("hissu_display1").style.display = "";
	document.getElementById("hissu_display2").style.display = "";
        if (enquete == "radio" || enquete == "check") {
                document.getElementById("select").style.display = "block";
        } else {
                document.getElementById("select").style.display = "none";
        }
	if (enquete == "subscribe_mail" || enquete == "unsubscribe_mail" ) {
	    document.getElementById("mail_display").style.display = "";
	    document.getElementById("mail_display2").style.display = "";
	    document.getElementById("mail_display3").style.display = "";
	    document.getElementById("hissu_display1").style.display = "none";
	    document.getElementById("hissu_display2").style.display = "none";
	}
}

function init() {
        tinyMCEPopup.resizeToInnerSize();
}

function insertEnquete() {
        var formObj = document.forms[0];
        var enquete = formObj.enquete.value;
        var name = formObj.name.value;
        var candidates = formObj.candidates.value;
        var error = '';
        if (!enquete) {
                error = 'フォームの種類を選択してください';
        } else if (!name) {
                error = '項目名を入力してください';
        } else {
                if (enquete == "radio" || enquete == "check") {
                        if (formObj.other.checked) {
                                enquete += "_other";
                        }
                        candidates = candidates.replace(/['\t ]*/g, '').replace(/\n+/g, '\n').replace(/^\n/, '').replace(/\n$/, '');
                        if (!candidates) {
                                error = '選択肢を一つ以上入力してください';
                                formObj.candidates.value = '';
                        }
                        var ary = candidates.split("\n");
                        args = ", '" + ary.join("', '") + "'";
                } else {
                        args = '';
                }

                if (enquete == "subscribe_mail") {
                        args += "-request@mm.pref.shimane.jp:subscribe";
                } else if (enquete == "unsubscribe_mail") {
                        args += "-request@mm.pref.shimane.jp:unsubscribe";
                }

                if (tinyMCE.isMSIE) {
                        if (enquete == "subscribe_mail" || enquete == "unsubscribe_mail") {
                                var enquete_format = "&lt;%= plugin('form_" + enquete + "', '" + name + args + "') %&gt;";
                        } else {
                                var enquete_format = "&lt;%= plugin('form_" + enquete + "', '" + name + "'" + args + ") %&gt;";
                        }
                } else {
                        if (enquete == "subscribe_mail" || enquete == "unsubscribe_mail") {
                                var enquete_format = "<%= plugin('form_" + enquete + "', '" + name + args + "') %>";
                        } else {
                                var enquete_format = "<%= plugin('form_" + enquete + "', '" + name + "'" + args + ") %>";
                        }
                }

        }
        if (error) {
                alert(error);
        } else {
                tinyMCEPopup.execCommand("mceInsertContent", true, enquete_format);
                tinyMCEPopup.close();
        }
}
