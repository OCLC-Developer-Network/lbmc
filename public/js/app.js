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
		n = $("input[name='subject[]']").size() + 1;
		var subject_row = '<div class="row pad_above" id="row-elem-'+n+'">';
		subject_row += '<div class="col-md-10">';
		//subject_row += '<input type="text" name="subject_ind2[]" id="subject_ind2_'+n+'" value=" "/>';
		subject_row += '<input type="text" name="subject[]" class="form-control autosubject"></div>';
		subject_row += '<div class="col-md-2"><button id="addelem-'+n+'" class="add btn btn-sm btn-info" title="Add another topic"><span class="glyphicon glyphicon-plus-sign"></span></button> <button id="elem-'+n+'" class="btn btn-sm btn-warning delete"><span class="glyphicon glyphicon-minus-sign"></span></button></div>';
		subject_row += '</div>';
		$("#subjects").append(subject_row);
		bindAutoComplete("autosubject",n);
		return false;
	});
	$("body").on("click", ".delete", function (e) {
		$("#row-"+this.id).remove();
		return false;
	});
	
	// bind autocomplete ui to input fields with the class autosubject
	bindAutoComplete("autosubject",1);

}); // end of onready function call

// set the FAST auto suggest defaults
var currentSuggestIndexDefault = "suggestall"; 
var subjectProxy = "https://fast.oclc.org/searchfast/fastsuggest?";
var subjectDB =  "autoSubject";

// bind auto complete to input elements
function bindAutoComplete(classname,n) {
	$("." + classname).autocomplete({
		source: autoSubjectExample, 
		minLength: 1,
		select: function(event, ui) {
			//$("#subject_ind2_"+n).val(get653IndicatorTwoFromTag(ui.item.tag));
		},
		create: function() {
			$(this).data("ui-autocomplete")._renderItem = function (ul, item) {
				var retValue = "<span style=\"font-weight: bold;\">" +item.auth+"</span>";
				if(item.type=="alt")
					retValue = item.label + "<span style=\"font-style: italic;\"> USE </span>" + retValue;
				return $( "<li></li>" ).data( "ui-autocomplete-item", item ).append( "<a>" + retValue + "</a>" ).appendTo( ul );
			};
		}
	});
}

// the core autoSubject function for calling FAST
function autoSubject(request, response, responseStyle) {

	// get and clean the request term
	var requestterm = request.term;
	requestterm = requestterm.replace(/\-/g, "");
	requestterm = requestterm.replace(/ /g, "%20");

	// set the index and the properties to return from FAST for each match
	var suggestIndex = currentSuggestIndex;
	var suggestReturn = suggestIndex + "%2Cidroot%2Cauth%2Ctag%2Ctype%2Craw%2Cbreaker%2Cindicator";

	// create the FAST API query and URI
	var query = "&query=" + requestterm + "&queryIndex=" + suggestIndex + "&queryReturn=" + suggestReturn;
	query += "&suggest=" + subjectDB;
	var url = subjectProxy + query;

	// call FAST with Ajax and JSON-P
	$.ajax({
		type: "GET",
		url: url,
		dataType: "jsonp",
		jsonp: 'json.wrf',
		success: function (data) {
			var mr = [];
			var result = data.response.docs;
			for (var i = 0, len = result.length; i < len; i++) {
				var term = result[i][suggestIndex];
				var useValue = "";
				if(responseStyle == undefined )
					useValue = result[i]["auth"];
				else 
					useValue = responseStyle(result[i]); 
				mr.push({
					label: term,                       //heading matched on 
					value: useValue,                   //this gets inserted to the search box when an autocomplete is selected,
					idroot: result[i]["idroot"],       //the fst number
					auth: result[i]["auth"],           //authorized form of the heading, viewable -- format
					tag: result[i]["tag"],             //heading tag, 1xx
					type: result[i]["type"],           //auth= term is authorized form, alt= term is alternate (see also) form
					raw: result[i]["raw"],             //authorized form of the heading, $a-z subdivision form
					breaker: result[i]["breaker"],     //authorized form of the heading, marcbreaker coding for diacritics
					indicator: result[i]["indicator"]  //heading first indicator 
				});
			}
			response(mr);
		}
	});
} // end autoSubject

// called by autosuggest, based on the tag returned convert to appropriate MARC 653 indicator 2 value
function get653IndicatorTwoFromTag(tag) {
	switch(tag) {
		case 100:
			// Personal name
			return "1";
			break;
		case 110:
			// Corporate name
			return "2";
			break;
		case 111:
			// Meeting name
			return "3";
			break;
		case 130:
			// Uniform Title
			return "";
			break;
		case 148:
			// Period
			return "4";
			break;
		case 150:
			// Topical term
			return "0";
			break;
		case 151:
			// Geographic
			return "5";
			break;
		case 155:
			// Form / Genre
			return "6";
			break;
		default:
			return "";
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