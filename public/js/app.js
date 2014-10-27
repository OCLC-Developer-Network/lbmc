$( document ).ready(function() {

	// set home button on or off
	set_home_button();

	// browser detection and alerts
	var isChrome = /Chrome/.test(navigator.userAgent) && /Google Inc/.test(navigator.vendor);
	var isSafari = /Safari/.test(navigator.userAgent) && /Apple Computer/.test(navigator.vendor);
	if (isChrome || isSafari) {
		$('#webkit_message').addClass("alert alert-warning");
		$('#webkit_message').html("<span class='glyphicon glyphicon-info-sign'></span> Record editing isn't working yet with the Chrome or Safari web browsers.  The LBMC team is working on a solution to that problem.  Until then, please use Firefox or Internet Explorer.  We apologize for your inconvenience.");
	}

	// adding and deleting topic rows
	$("body").on("click", ".add", function (e) {
		n = $("input[name='subject[]'").size() + 1;
		$("#subjects").append('<div class="row pad_above" id="row-elem-'+n+'"><div class="col-md-10"><input type="text" name="subject[]" class="form-control autosubject"></div><div class="col-md-2"><button id="addelem-'+n+'" class="add btn btn-sm btn-info" title="Add another topic"><span class="glyphicon glyphicon-plus-sign"></span></button> <button id="elem-'+n+'" class="btn btn-sm btn-warning delete"><span class="glyphicon glyphicon-minus-sign"></span></button></div></div>');
		bindAutoComplete("autosubject");
		return false;
	});
	$("body").on("click", ".delete", function (e) {
		$("#row-"+this.id).remove();
		return false;
	});
	
	// bind autocomplete ui to input fields with the class autosubject
	bindAutoComplete("autosubject");

}); // end of onready function call

// set the auto suggest index default
var currentSuggestIndexDefault = "suggestall";  //initial default value

function bindAutoComplete(classname) {
	$("." + classname).autocomplete({
		source: autoSubjectExample, 
		minLength: 1,
		//select: function(event, ui) {
			//$('#exampleXtra').html("FAST ID <b>" + ui.item.idroot + "</b> Facet <b>"+ getTypeFromTag(ui.item.tag)+ "</b>");
		//},
		create: function() {
			$(this).data("ui-autocomplete")._renderItem = function (ul, item) {
				var retValue = "<span style=\"font-weight: bold;\">" +item.auth+"</span>";
				if(item.type=="alt")
					retValue = item.label + "<span style=\"font-style: italic;\"> USE </span>" + retValue;
				return $( "<li></li>" ).data( "ui-autocomplete--item", item ).append( "<a>" + retValue + "</a>" ).appendTo( ul );
			};
		}
	});
}

// called by autosuggest
function getTypeFromTag(tag) {
	switch(tag) {
		case 100:
			return "Personal Name";
			break;
		case 110:
			return "Corporate Name";
			break;
		case 111:
			return "Event";
			break;
		case 130:
			return "Uniform Title";
			break;
		case 148:
			return "Period";
			break;
		case 150:
			return "Topic";
			break;
		case 151:
			return "Geographic";
			break;
		case 155:
			return "Form/Genre";
			break;
		default:
			return "unknown";
	}
} // end getTypeFromTag

// called as the source for the autocomplete
function autoSubjectExample(request, response) {
	currentSuggestIndex = currentSuggestIndexDefault;
	autoSubject(request, response, exampleStyle);
}

// Replace the common subfield break of -- with , 
function exampleStyle(res) {
	//return res["auth"].replace("--",", "); 	
	return res["auth"];
}

function set_home_button() {
	// change the home button style if on the home pagevar pathname = window.location.pathname;
	if (window.location.pathname == "/") {
		if ($("#home").length) {
				$("#home").removeClass( "btn-primary" ).addClass("btn-default");
		}
	}
} // end set_home_button