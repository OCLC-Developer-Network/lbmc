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

	// adding and deleting rows
	$("body").on("click", ".add-author", function (e) {
		n = $("input[name='author[]']").size();
		var row = '<div class="pad_below" id="row_author_'+n+'">';
		row += '<div class="row">';
		row += '<div class="col-md-10">';
		row += '<input type="text" name="author[]" class="form-control"></div>';
		row += '<div class="col-md-2"><button id="add_author_'+n+'" class="add-author btn btn-sm btn-info"><span class="glyphicon glyphicon-plus-sign"></span></button> <button id="author_'+n+'" class="btn btn-sm btn-warning delete"><span class="glyphicon glyphicon-minus-sign"></span></button></div>';
		row += '</div>';
		row += '<div class="row" id="author_type_'+n+'">';
		row += '<div class="col-md-12">';
		row += '<label class="radio-inline">';
		row += '<input type="radio" name="author_field_'+n+'" id="author_is_person_'+n+'" value="100" checked/>';
		row += ' The author is a person';
		row += '</label>';
		row += '<label class="radio-inline">';
		row += '<input type="radio" name="author_field_'+n+'" id="author_is_organization_'+n+'" value="110" />';
		row += ' The author is an organization';
		row += '</label>';
		row += '</div>';
		row += '</div>';
		$("#authors").append(row);
		return false;
	});
	$("body").on("click", ".add-subject", function (e) {
		n = $("input[name='subject[]']").size();
		var row = '<div class="row pad_below" id="row_subject_'+n+'">';
		row += '<div class="col-md-10">';
		row += '<input type="text" name="subject[]" id="subject_entry_'+n+'" class="form-control autosubject"  value="">';
		row += '<input type="hidden" name="subject_raw[]" id="subject_entry_'+n+'_raw" value=""/>';
		row += '<input type="hidden" name="subject_type[]" id="subject_entry_'+n+'_type" value="653"/>';
		row += '<input type="hidden" name="subject_id[]" id="subject_entry_'+n+'_id" value="none"/>';
		row += '<input type="hidden" name="subject_indicator[]" id="subject_entry_'+n+'_indicator" value=" "/>';
		row += '</div>';
		row += '<div class="col-md-2"><button id="add_subject_'+n+'" class="add-subject btn btn-sm btn-info"><span class="glyphicon glyphicon-plus-sign"></span></button> <button id="subject_'+n+'" class="btn btn-sm btn-warning delete"><span class="glyphicon glyphicon-minus-sign"></span></button></div>';
		row += '</div>';
		$("#subjects").append(row);
		bindAutoComplete("autosubject",n);
		return false;
	});
	$("body").on("click", ".add-isbn", function (e) {
		n = $("input[name='isbn[]']").size();
		var row = '<div class="row pad_below" id="row_isbn_'+n+'">';
		row += '<div class="col-md-8">';
		row += '<input type="text" name="isbn[]" class="form-control"></div>';
		row += '<div class="col-md-4"><button id="add_isbn_'+n+'" class="add-isbn btn btn-sm btn-info"><span class="glyphicon glyphicon-plus-sign"></span></button> <button id="isbn_'+n+'" class="btn btn-sm btn-warning delete"><span class="glyphicon glyphicon-minus-sign"></span></button></div>';
		row += '</div>';
		$("#isbns").append(row);
		return false;
	});
	$("body").on("click", ".delete", function (e) {
		$("#row_"+this.id).remove();
		return false;
	});
	
	// bind autocomplete ui to input fields with the class autosubject
	bindAutoComplete("autosubject",1);
	
	// reset subject type and id if user enters data by hand
	$( ".autosubject" ).keypress(function() {
		//console.log($(this));
		$("#"+$(this)[0].id+"_type").val('653');
		$("#"+$(this)[0].id+"_id").val('none');
	});
	
	// reset pd1 hidden value based on visible publication date and currently selected calendar type, when publication date changes
	$("#publication_date").each(function() {
		var elem = $(this);
		// Save current value of element
		elem.data('oldVal', elem.val());
		// Look for changes in the value
		elem.bind("propertychange change click keyup input paste", function(event){
			// If value has changed...
			if (elem.data('oldVal') != elem.val()) {
				// Updated stored value
				elem.data('oldVal', elem.val());
				var pd = $("#publication_date").val();
				console.log(pd);
				if (pd.length > 0) {
					if (pd.indexOf(" ") != -1) {
						pd = pd.substring(0,pd.indexOf(" "));
					}
					computePd1(pd);
				}
			}
		});
	});

}); // end of onready function call

// set the FAST auto suggest defaults
var currentSuggestIndexDefault = "suggestall"; 
var subjectProxy = "https://fast.oclc.org/searchfast/fastsuggest?";
var subjectDB =  "autoSubject";

// bind auto complete to an input element
function bindAutoComplete(classname,n) {
	$("." + classname).autocomplete({
		source: autoSubjectExample, 
		minLength: 1,
		select: function(event, ui) {
			var tag = ui.item.tag + "";
			tag = tag.substring(1);
			tag = "6"+tag;
			console.log(ui.item);
			var raw = ui.item.value
			if (ui.item.raw.length > 0) {
				raw = ui.item.raw
			}
			$("#"+$(this)[0].id).val(ui.item.value);
			$("#"+$(this)[0].id+"_raw").val('$a'+raw);
			$("#"+$(this)[0].id+"_type").val(tag);
			$("#"+$(this)[0].id+"_id").val("(OCoLC)"+ui.item.idroot);
			$("#"+$(this)[0].id+"_indicator").val(ui.item.indicator);
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

// Switch the language of the user interface
function switchLanguage(l) {
	var wurl = window.location.href;
	if (wurl.indexOf("?") == -1) {
		wurl += "?locale="+l;
	} else {
		if (wurl.indexOf("locale=") == -1) {
			wurl += "&locale="+l;
		} else {
			var wurlArray = wurl.split("locale=");
			wurl = wurlArray[0] + "locale=" + l;
			if (wurlArray[1].indexOf("&") != -1) {
				wurl += wurlArray[1].substring(wurlArray[1].indexOf("&"));
			} 
		}
	}
	window.location.href = wurl;
} // end switchLanguage

// Set the 260 $c and 008 dates based on type of date
function setPublicationDate() {
	$("#gregorian_date").html("");
	var selectedValue = $('#calendar_select').val();
	var selectedText = $('#calendar_select>option:selected').text();
	var pd = $("#publication_date").val();
	if (pd.length > 0) {
		if (pd.indexOf(" ") != -1) {
			pd = pd.substring(0,pd.indexOf(" "));
		}
		computePd1(pd);
		if (selectedValue.indexOf("gregorian") == -1) {
			pd += " "+selectedText;
		}
		$("#publication_date").val(pd);
	}
} // end setPublicationDate

// compute the pd1 value based on the publication date string and calendar type
function computePd1(pd) {
	var selectedValue = $('#calendar_select').val();
	var selectedText = $('#calendar_select>option:selected').text();
	if (selectedValue.indexOf("gregorian") == -1) {
		var j;
		var date;
		if (selectedValue.indexOf("hebrew") != -1) {
			j = hebrew_to_jd((new Number(pd)),1,1);
		} else if (selectedValue.indexOf("islamic") != -1) {
			j = islamic_to_jd((new Number(pd)),1,1);
		} else if (selectedValue.indexOf("persian") != -1) {
			j = persian_to_jd((new Number(pd)),1,1);
		}
		date = jd_to_gregorian(j);
		$("#gregorian_date").html("Gregorian year ~= "+date[0]);
		$("#pd1").val(String(date[0]).substring(0,4));
	} else {
		if (!isNaN(parseFloat(pd.substring(0,4)))) {
			$("#pd1").val(parseFloat(pd.substring(0,4)));
		} else {
			$("#pd1").val('   ');
		}
	}
} // end computePd1