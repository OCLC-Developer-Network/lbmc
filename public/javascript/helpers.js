
function get_language() {
	var title_string = $('#title').val()
	var detect_url = "/detect/"+title_string;
	$.getJSON( detect_url, function( data ) {
		var items = [];
		$.each( data, function( key, val ) {
			items.push( val );
		});
		var languages = items.join(", ");
		$("#languages").val(languages);
	});
} // end get_language