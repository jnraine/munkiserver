// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

jQuery.noConflict();

jQuery(document).ready(function() {
	// Turn all multiple select tags into asmSelect tags
	jQuery("select[multiple]").asmSelect({
	    animate: true
	});

	// Hide loading graphic on load
	jQuery('#loading_graphic').hide();
	
	// Hide text receipts container
	jQuery('#text_installs_container').hide();
	// Flip visibility of GUI and text receipt views
	jQuery('input[name=installs_mode]').change(function() {
		if(this.value == 'text') {
			jQuery('#gui_installs_container').slideUp();
			jQuery('#text_installs_container').slideDown();	
		} else {
			jQuery('#gui_installs_container').slideDown();
			jQuery('#text_installs_container').slideUp();
		}
	});

	// Hide text receipts container
	jQuery('#text_receipts_container').hide();
	// Flip visibility of GUI and text receipt views
	jQuery('input[name=receipts_mode]').change(function() {
		if(this.value == 'text') {
			jQuery('#gui_receipts_container').slideUp();
			jQuery('#text_receipts_container').slideDown();	
		} else {
			jQuery('#gui_receipts_container').slideDown();
			jQuery('#text_receipts_container').slideUp();
		}
	});

	// Hide installer choices container if unchecked
	if(jQuery('#pkgsinfo_use_installer_choices:checked').val() == null) {
		jQuery("#installer_choices_container").hide();
	}
	// Bind "use installer choices" checkbox to hide show the value
	jQuery('#pkgsinfo_use_installer_choices').change(function() {
		if(this.checked) {
			jQuery("#installer_choices_container").slideDown();	
		} else {
			jQuery("#installer_choices_container").slideUp();
		}
	});
	// Hide text installer choices container
	jQuery('#text_installer_choices_container').hide();
	// Flip visibility of GUI and text installer choice views
	jQuery("input[name='installer_choices_mode']").change(function() {
		if(this.value == 'text') {
			jQuery('#gui_installer_choices_container').slideUp();
			jQuery('#text_installer_choices_container').slideDown();	
		} else {
			jQuery('#gui_installer_choices_container').slideDown();
			jQuery('#text_installer_choices_container').slideUp();
		}
	});
	
	// Hide raw text area if raw_mode_id is 0 container
	if(jQuery('#package_raw_mode_id').val() == 0)
		jQuery('#package_raw_tags').hide();
	// Flip visibility of raw tag text area
	jQuery("#package_raw_mode_id").change(function() {
		if(this.value == 0) {
			jQuery('#package_raw_tags').slideUp();
		} else {
			jQuery('#package_raw_tags').slideDown();
		}
	});	
	
	// For USER views, enable/disable change password
	if(jQuery('#change_password_checkbox').attr('checked') == false) {
		jQuery('#user_password').attr("disabled",true);
		jQuery('#user_password_confirmation').attr("disabled",true);
	}
	jQuery('#change_password_checkbox').change(function() {
		if(this.checked) {
			jQuery('#user_password').attr("disabled",false);
			jQuery('#user_password_confirmation').attr("disabled",false);
		} else {
			jQuery('#user_password').attr("disabled",true);
			jQuery('#user_password_confirmation').attr("disabled",true);
		}
	})
	
	// Helps provide an easy way to show confirm windows
	// on any link easily using the attribute data-confirm-message
	jQuery('a').click(function() {
		// When the data-confirm-message attribute exists, pop up a confirm window
		var message = jQuery(this).attr('data-confirm-message');
		if( message !== undefined) {
			return confirm(message);
		}
	});
});

// AJAX hostname search/filter
jQuery("#filter_form").submit(function() {
	// Show the loading graphic while request is made
	jQuery("#loading_graphic").show();
	// Grab the script and execute it
	jQuery.getScript(this.action + "?hostname=" + jQuery("[name=hostname]").val());
	// Return false so the form isn't submitted
	return false
});

// Text field default message
jQuery.fn.extend({
	subtle_value: function(original_value) {
		var this_id = this.attr("id");
		if(this.val() == '') {
			this.val(original_value);
			this.css("color","#666");			
		}

		this.focus(function(){
			if(jQuery("#" + this_id).val() == original_value) {
				this.clear();
				jQuery("#" + this_id).css("color","#000");
			}
		});	
		this.blur(function(){
			if(jQuery("#" + this_id).val() == '') {
				jQuery("#" + this_id).val(original_value);
				jQuery("#" + this_id).css("color","#666");
			}
		});
	},
	// Push text field value to sibling asmSelect
	push_value_to_asmselect: function() {
		var asmSelect_id = this.siblings(".asmContainer").children(".asmSelect").attr("id");
		var option_tags = jQuery("#" + asmSelect_id + " option");
		var option_values = new Array;
		var value_matches_option = false;
		var text_field_value = '';
		jQuery.each(option_tags, function() {
			option_values.push(this.text);
		});
		this.keypress(function (e) { 
			if(e.which == 13) {
				text_field_value = this.value;
				value_matches_option = option_values.some(
					function (element) {
						return (element == text_field_value); 
					}
				);
				if(value_matches_option) {
					jQuery("#" + asmSelect_id).val(this.value);
					jQuery("#" + asmSelect_id).change();
				}
				this.clear();
				return false;
			}
		});
	}
});

// Site search bar
jQuery(function() {
	jQuery("#search_field").subtle_value("doesn't work yet...");
});

// Package variation name text field
jQuery(function() {
	jQuery("#create_package_variation_name").subtle_value("Display name");
});

// Package picker autocompletion
// This is poorly written and liable to break.  Fix it soon.
jQuery(function() {
	jQuery(".quickly_complete_field").keypress(function (e) { 
		if(e.which == 13) {
			// Grab asmSelect box and change it's value
			//this.siblings(".asmContainer").children(".asmSelect")).val(this.value)
			// this.find("asmContainer > asmSelect").val(this.value)
			jQuery("#asmSelect1").val(this.value);
			jQuery("#asmSelect1").change();
			this.clear();
			return false;
		}
	});
	jQuery(".quickly_complete_field").val("type package name...");
	jQuery(".quickly_complete_field").css("color","#666");
	jQuery(".quickly_complete_field").focus(function() {
		if( this.value == "type package name..." ) {
			this.clear();
			jQuery(".quickly_complete_field").css("color","#000");
		}
	});
	jQuery(".quickly_complete_field").blur(function() {
		if( this.value == '' ) {
			jQuery(".quickly_complete_field").val("type package name...");
			jQuery(".quickly_complete_field").css("color","#666");
		}
	});
});

// Misc.
function toggleDisabledTextField(id) {
	var el = document.getElementById(id);
	if(el.disabled == true) {
		el.disabled = false;
		el.style.color = '#000';
		el.focus();
		document.getElementById(id + '_control').innerHTML = 'lock';
	}
	else {
		el.disabled = true;
		el.style.color = '#666';
		document.getElementById(id + '_control').innerHTML = 'unlock';
	}
	return false;
}

function SetAllCheckBoxes(FormName, FieldName, CheckValue)
{
	if(!document.forms[FormName])
		return;
	var objCheckBoxes = document.forms[FormName].elements[FieldName];
	if(!objCheckBoxes)
		return;
	var countCheckBoxes = objCheckBoxes.length;
	if(!countCheckBoxes)
		objCheckBoxes.checked = CheckValue;
	else
		// set the check value for all check boxes
		for(var i = 0; i < countCheckBoxes; i++)
			objCheckBoxes[i].checked = CheckValue;
}

// Submits the form for auto packaging, while creating a nice alert and "take over screen"
function submit_auto_package(jq_id) {
	if(confirm("Are you sure you want to auto package? This may take some time.")) {
		jQuery(jq_id).submit();
	}
	return false;
}

// $('dropdown_link').onmouseover = function() {
// 	this.show();
// }
// 
// $('dropdown_link').onmouseout = function() {
// 	this.hide();
// }
