$(document).ready(function() {
	// Turn all multiple select tags into asmSelect tags
	$("select[multiple]").asmSelect({
	    animate: true
	});

	// Hide loading graphic on load
	$('#loading_graphic').hide();
	$('.loading').hide();
	
	// Hide raw text area if raw_mode_id is 0 container
	// if($('#package_raw_mode_id').val() == 0) {
	// 	$('#package_raw_tags').hide();
	// }
	// // Flip visibility of raw tag text area
	// $("#package_raw_mode_id").change(function() {
	// 	if(this.value == 0) {
	// 		$('#package_raw_tags').slideUp();
	// 	} else {
	// 		$('#package_raw_tags').slideDown();
	// 	}
	// });	
	
	// For USER views, enable/disable change password
	if($('#change_password_checkbox').attr('checked') == false) {
		$('#user_password').attr("disabled",true);
		$('#user_password_confirmation').attr("disabled",true);
	}
	$('#change_password_checkbox').change(function() {
		if(this.checked) {
			$('#user_password').attr("disabled",false);
			$('#user_password_confirmation').attr("disabled",false);
		} else {
			$('#user_password').attr("disabled",true);
			$('#user_password_confirmation').attr("disabled",true);
		}
	});
	
	// Helps provide an easy way to show confirm windows
	// on any link easily using the attribute data-confirm-message
	$('a').click(function() {
		// When the data-confirm-message attribute exists, pop up a confirm window
		var message = $(this).attr('data-confirm-message');
		if( message !== undefined) {
			return confirm(message);
		}
	});

	// Field lock control method
	$(".field-lock-control").click(function() {
		$el = $("#" + $(this).attr("data-target-id"));
		if($el.is(":disabled")) {
			$el.attr("disabled",false).css("color","#000").focus();
			$("#" + $el.attr('id') + "_control").html("lock");
		} else {
			$el.attr("disabled",true).css("color","#666");
			$("#" + $el.attr('id') + "_control").html("unlock");
		}
		return false;
	});
	
	// Load managed install report on change to drop down
	$("select#managed_install_reports").change(function() {
		$(".loading").show();
		$.ajax({
		  url: "/managed_install_reports/" +$(this).val()+ ".js",
		  complete: function(){
		    $(".loading").hide();
		  }
		});
	});
	$("select#managed_install_reports").change();
	
	
	// add Codemirror with jQuery animation to highlight XML/plist/bash syntax in package list
	$("textarea[data-format]").each(function () {
		
		var format = $(this).attr("data-format");
		var toRefresh = function(){
			editor.refresh();
		}
	
		var editor = CodeMirror.fromTextArea(this, {
					onFocus: function() {
					    //jQuery animation goes here				
					    $(editor.getWrapperElement()).animate({
					        height: "300px"
					    },
					    400, "swing", toRefresh);
	
	
					},
					onBlur: function() {
					    $(editor.getWrapperElement()).animate({
					        height: "78px"
					    },
					    400, "swing", toRefresh);
	
					},
					lineNumbers: true,
					matchBrackets: true,
					mode: format,
					onCursorActivity: function() {
					    editor.setLineClass(hlLine, null);
					    hlLine = editor.setLineClass(editor.getCursor().line, "activeline");
					}
		      });
		var hlLine = editor.setLineClass(0, "activeline");	
	});
	
	function hideAllUninstallField(){
		$("input#package_uninstaller_item_location").parent().parent().hide();
		$("input#package_uninstall_script").parent().parent().hide();
		$("#postinstall_script_container").parent().parent().hide();
	}
	hideAllUninstallField();
	
	
	// show Uninstall script/item location when corresponding value is selected in the dropdown list	
	function hideUninstallField(val, vid){
		$("#package_uninstall_method").change(function (){
			
			if (this.value === val){
				$(vid).parent().parent().show();								
			}
			else{
				$(vid).parent().parent().hide();
				$(vid).val('');	
			}
		});
	}
	
	hideUninstallField("uninstaller_item_location", "input#package_uninstaller_item_location");
	hideUninstallField("","input#package_uninstall_script");
	hideUninstallField("uninstall_script","#postinstall_script_container");
	$("#package_uninstall_method").change();
		
	// jQuery for tabs in package edit
	$("#tabs").tabs();
	
	// client side validation jQuery animation
	clientSideValidations.callbacks.element.fail = function(element, message, callback) {
	  callback();
	  if (element.data('valid') !== false) {
		e = element.parent().find('.message');
		// e.css({"display":"block"});
		e.hide().show('slide', {direction: "left", easing: "easeOutBounce"}, 500);
	  }
	}
	
	initializeBulkEdit();
}); // end document ready function

// disable input and select field onload, click to enable the field
function selectToEdit(){
	$(".accept").parents("tr").find("input, select").not($(".accept:checkbox")).attr("disabled", true);
	
	$(".accept").change(function(){
		$(this).parents("tr").find("input, select").not(this).attr("disabled", !$(this).attr("checked"));
	})
}

// trigger lightbox popup
function initalizeLightBoxMe(){
	$('#lightbox_target').lightbox_me({
	        centered: true, 
			closeSelector: ".cancel",
			destroyOnClose: true,
			onLoad: selectToEdit() });	
}
// uncheck all the checkbox and hide the submit button
function initializeBulkEdit() {
	
	$("#bulk_edit").css({"visibility":"hidden"});
	
	$(".select_all").change(function() {
		$(this).parents("table").find(":checkbox").attr("checked",$(this).attr("checked"));
	});
	
	var totalCheckboxes = $(".bulk_edit_checkbox").length;
	// uncheck the .select_all checkbox when one or more checkbox is not selected
	$(".bulk_edit_checkbox").change(function(){
		var n = $(".bulk_edit_checkbox:checked").length;
		if (n != totalCheckboxes) {
			$(".select_all").attr("checked", false);
		}
	});
	
	// show bulk edit button when 2 or more checkbox is selected
	$(":checkbox").change(function(){
		var n = $(".bulk_edit_checkbox:checked").length;
		if (n > 1) {
			$("#bulk_edit").css({"visibility":"visible"});
		} else{
			$("#bulk_edit").css({"visibility":"hidden"});
		}
	});
	$(":checkbox").change();
}

// AJAX hostname search/filter
// $("#filter_form").submit(function() {
// 	// Show the loading graphic while request is made
// 	$("#loading_graphic").show();
// 	// Grab the script and execute it
// 	$.getScript(this.action + "?hostname=" + $("[name=hostname]").val());
// 	// Return false so the form isn't submitted
// 	return false;
// });

// Text field default message
$.fn.extend({
	subtle_value: function(original_value) {
		var $text_field = $(this);
		var this_id = $text_field.attr("id");
		if($text_field.val() == '') {
			$text_field.val(original_value);
			$text_field.css("color","#666");			
		}

		$text_field.focus(function(){
			if($("#" + this_id).val() == original_value) {
				$text_field.val("");
				$("#" + this_id).css("color","#000");
			}
		});	
		$text_field.blur(function(){
			if($("#" + this_id).val() == '') {
				$("#" + this_id).val(original_value);
				$("#" + this_id).css("color","#666");
			}
		});
	},
	// Push text field value to sibling asmSelect
	push_value_to_asmselect: function() {
		var $text_field = $(this);
		var asmSelect_id = $text_field.siblings(".asmContainer").children(".asmSelect").attr("id");
		var option_tags = $("#" + asmSelect_id + " option");
		var option_values = [];
		var value_matches_option = false;
		var text_field_value = '';
		$.each(option_tags, function() {
			option_values.push($text_field.text());
		});
		$text_field.keypress(function (e) {
			if(e.which == 13) {
				text_field_value = $text_field.val();
				// If the text input matches an item in our list, select it
				// Find a match
				$("#" + asmSelect_id).children('option').each(function(){
					var $option_tag = $(this);
					if($option_tag.text() == text_field_value) {	
						var $matching_option_tag = $option_tag;
						$("#" + asmSelect_id).val($matching_option_tag.val());
						$("#" + asmSelect_id).change();
					}
				});
				// Clear auto complete text field
				$text_field.val("");
				return false;
			}
		});
	}
});

// Site search bar
$(function() {
	$("#search_field").subtle_value("doesn't work yet...");
});

// Package variation name text field
$(function() {
	$("#create_package_variation_name").subtle_value("Display name");
});

// Package picker autocompletion
// This is poorly written and liable to break.  Fix it soon.
$(function() {
	$(".quickly_complete_field").keypress(function (e) { 
		if(e.which == 13) {
			// Grab asmSelect box and change it's value
			//this.siblings(".asmContainer").children(".asmSelect")).val(this.value)
			// this.find("asmContainer > asmSelect").val(this.value)
			$("#asmSelect1").val(this.value);
			$("#asmSelect1").change();
			this.clear();
			return false;
		}
	});
	$(".quickly_complete_field").val("type package name...");
	$(".quickly_complete_field").css("color","#666");
	$(".quickly_complete_field").focus(function() {
		if( this.value == "type package name..." ) {
			this.clear();
			$(".quickly_complete_field").css("color","#000");
		}
	});
	$(".quickly_complete_field").blur(function() {
		if( this.value == '' ) {
			$(".quickly_complete_field").val("type package name...");
			$(".quickly_complete_field").css("color","#666");
		}
	});
});

// Misc.
function toggleDisabledTextField($el) {
	if($el.attr("disabled") == true) {
		$el.attr("disabled",false).css("color","#000").focus();
		$("#" + id + "_control").html("lock");
	} else {
		$el.attr("disabled",true).css("color","#666");
		$("#" + id + "_control").html("unlock");
	}
}

function SetAllCheckBoxes(FormName, FieldName, CheckValue)
{
	if(!document.forms[FormName]) {
		return;	
	}
	var objCheckBoxes = document.forms[FormName].elements[FieldName];
	if(!objCheckBoxes) {
		return;
	}
	var countCheckBoxes = objCheckBoxes.length;
	if(!countCheckBoxes) {
		objCheckBoxes.checked = CheckValue;
	} else {
		// set the check value for all check boxes
		for(var i = 0; i < countCheckBoxes; i++) {
			objCheckBoxes[i].checked = CheckValue;	
		}
	}
}

// Submits the form for auto packaging, while creating a nice alert and "take over screen"
function submit_auto_package(jq_id) {
	if(confirm("Are you sure you want to auto package? This may take some time.")) {
		$(jq_id).submit();
	}
	return false;
}

