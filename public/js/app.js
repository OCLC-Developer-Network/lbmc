$( document ).ready(function() {
  align_marc_views();
  set_home_button();
});

$( window ).resize(function() {
  align_marc_views();
});

function align_marc_views() {
  // align the heights of the marc view and xml divs
  if ($('#marc-view').length && $('#marc-xml').length) {
    $('#marc-xml').height($('#marc-view').height());
    $('#marc-xml').width($('#marc-view').width());
  }
} // end align_marc_views

function set_home_button() {
	// change the home button style if on the home pagevar pathname = window.location.pathname;
	if (window.location.pathname == "/") {
		if ($("#home").length) {
				$("#home").removeClass( "btn-primary" ).addClass("btn-default");
		}
	}
} // end set_home_button