function dir_open(id){
  document.getElementById(id + '-closed').style.display = 'none';
  document.getElementById(id + '-open').style.display = 'block';
}

function dir_close(id){
  document.getElementById(id + '-closed').style.display = 'block';
  document.getElementById(id + '-open').style.display = 'none';
}

function ime_disabled(txobj){
	txobj.style.imeMode="disabled";
}

function openWindow(url) {
	var select_value = encodeURIComponent(window.document.forms.TemplateForm.template.options[window.document.forms.TemplateForm.template.selectedIndex].value);
	var name = encodeURIComponent($("page_name").value);
	var title = encodeURIComponent($("page_title").value);
	var genre_id = encodeURIComponent($("genre_id").value);
        window.open(url + '/' + select_value + '?name=' + name + ';title=' + title + ';genre_id=' + genre_id, "", "WIDTH=800,HEIGHT=600,toolbar=no,status=no,menubar=no,scrollbars=yes,resizable");
}

function openWindowforNewPage(url) {
	var select_value = encodeURIComponent(window.document.forms.TemplateFormNewPage.template.options[window.document.forms.TemplateFormNewPage.template.selectedIndex].value);
	var name = encodeURIComponent($("page_name").value);
	var title = encodeURIComponent($("page_title").value);
	var genre_id = encodeURIComponent($("genre_id").value);
        window.open(url + '/' + select_value + '?name=' + name + ';title=' + title + ';genre_id=' + genre_id, "", "WIDTH=800,HEIGHT=600,toolbar=no,status=no,menubar=no,scrollbars=yes,resizable");
}

function toggle_sidebar() {
  status = document.getElementById("side").style.display;
  if ( status != "none" ){
    document.getElementById("side").style.display = "none";
    document.getElementById("main").style.margin = "0";
  } else {
    document.getElementById("side").style.display = "block";
    document.getElementById("main").style.margin = "0 0 0 21%";
  }
}

function select_switch_radio(select) {
  var radio;
  if (select == 'on')
  {
    radio = document.getElementById('public_term_switch_on');
  }
  else if (select == 'off')
  {
    radio = document.getElementById('public_term_switch_off');
  }
  radio.checked = 'true';
}

function select_switch_template_radio(select) {
  var radio;
  if (select == 'on')
  {
    radio = document.getElementById('template_page_enable_on');
  }
  else if (select == 'off')
  {
    radio = document.getElementById('template_page_enable_off');
  }
  radio.checked = 'true';
}

function check_public_term_date() {
	var select_value;
        select_value = document.getElementById('public_term_begin_date');
}

function login_submit() {
  window.open("about:blank", "login", "WIDTH=800,HEIGHT=600,toolbar=no,status=no,menubar=no,scrollbars=yes,resizable");
  document.Login.target = "login";
  document.Login.submit();
  close_window();
}

function close_window(){
  document.write("このウィンドウを閉じてください。");
}

function NotSetPublicTerm(color){
  document.getElementById('public_term_select').style.color = color;
  document.getElementById('public_term_begin_date_(1i)').disabled = true;
  document.getElementById('public_term_begin_date_(2i)').disabled = true;
  document.getElementById('public_term_begin_date_(3i)').disabled = true;
  document.getElementById('public_term_begin_date_(4i)').disabled = true;
  document.getElementById('public_term_begin_date_(5i)').disabled = true;
  document.getElementById('public_term_end_date_(1i)').disabled = true;
  document.getElementById('public_term_end_date_(2i)').disabled = true;
  document.getElementById('public_term_end_date_(3i)').disabled = true;
  document.getElementById('public_term_end_date_(4i)').disabled = true;
  document.getElementById('public_term_end_date_(5i)').disabled = true;
  document.getElementById('public_term_end_date_enable').disabled = true;
}

function SetPublicTerm(color){
  document.getElementById('public_term_select').style.color = color;
  document.getElementById('public_term_begin_date_(1i)').disabled = false;
  document.getElementById('public_term_begin_date_(2i)').disabled = false;
  document.getElementById('public_term_begin_date_(3i)').disabled = false;
  document.getElementById('public_term_begin_date_(4i)').disabled = false;
  document.getElementById('public_term_begin_date_(5i)').disabled = false;
  if (!document.getElementById('public_term_end_date_enable').checked) {
    document.getElementById('public_term_end_date_(1i)').disabled = false;
    document.getElementById('public_term_end_date_(2i)').disabled = false;
    document.getElementById('public_term_end_date_(3i)').disabled = false;
    document.getElementById('public_term_end_date_(4i)').disabled = false;
    document.getElementById('public_term_end_date_(5i)').disabled = false;
  }
  document.getElementById('public_term_end_date_enable').disabled = false;
}

function TogglePublicTermEnd(){
  if (document.getElementById('public_term_end_date_enable').checked) {
    document.getElementById('public_term_end_date_(1i)').disabled = true;
    document.getElementById('public_term_end_date_(2i)').disabled = true;
    document.getElementById('public_term_end_date_(3i)').disabled = true;
    document.getElementById('public_term_end_date_(4i)').disabled = true;
    document.getElementById('public_term_end_date_(5i)').disabled = true;
  } else {
    document.getElementById('public_term_end_date_(1i)').disabled = false;
    document.getElementById('public_term_end_date_(2i)').disabled = false;
    document.getElementById('public_term_end_date_(3i)').disabled = false;
    document.getElementById('public_term_end_date_(4i)').disabled = false;
    document.getElementById('public_term_end_date_(5i)').disabled = false;
  }
}
