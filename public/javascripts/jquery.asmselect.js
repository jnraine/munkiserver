/*
 * Alternate Select Multiple (asmSelect) 1.0.4a beta - jQuery Plugin
 * http://www.ryancramer.com/projects/asmselect/
 * 
 * Copyright (c) 2009 by Ryan Cramer - http://www.ryancramer.com
 * 
 * Dual licensed under the MIT (MIT-LICENSE.txt)
 * and GPL (GPL-LICENSE.txt) licenses.
 *
 */

(function(jQuery) {

	jQuery.fn.asmSelect = function(customOptions) {

		var options = {

			listType: 'ol',						// Ordered list 'ol', or unordered list 'ul'
			sortable: false, 					// Should the list be sortable?
			highlight: false,					// Use the highlight feature? 
			animate: false,						// Animate the the adding/removing of items in the list?
			addItemTarget: 'bottom',				// Where to place new selected items in list: top or bottom
			hideWhenAdded: false,					// Hide the option when added to the list? works only in FF
			debugMode: false,					// Debug mode keeps original select visible 

			removeLabel: 'remove',					// Text used in the "remove" link
			highlightAddedLabel: 'Added: ',				// Text that precedes highlight of added item
			highlightRemovedLabel: 'Removed: ',			// Text that precedes highlight of removed item

			containerClass: 'asmContainer',				// Class for container that wraps this widget
			selectClass: 'asmSelect',				// Class for the newly created <select>
			optionDisabledClass: 'asmOptionDisabled',		// Class for items that are already selected / disabled
			listClass: 'asmList',					// Class for the list (jQueryol)
			listSortableClass: 'asmListSortable',			// Another class given to the list when it is sortable
			listItemClass: 'asmListItem',				// Class for the <li> list items
			listItemLabelClass: 'asmListItemLabel',			// Class for the label text that appears in list items
			removeClass: 'asmListItemRemove',			// Class given to the "remove" link
			highlightClass: 'asmHighlight'				// Class given to the highlight <span>

			};

		jQuery.extend(options, customOptions); 

		return this.each(function(index) {

			var jQueryoriginal = jQuery(this); 				// the original select multiple
			var jQuerycontainer; 					// a container that is wrapped around our widget
			var jQueryselect; 						// the new select we have created
			var jQueryol; 						// the list that we are manipulating
			var buildingSelect = false; 				// is the new select being constructed right now?
			var ieClick = false;					// in IE, has a click event occurred? ignore if not
			var ignoreOriginalChangeEvent = false;			// originalChangeEvent bypassed when this is true

			function init() {

				// initialize the alternate select multiple

				// this loop ensures uniqueness, in case of existing asmSelects placed by ajax (1.0.3)
				while(jQuery("#" + options.containerClass + index).size() > 0) index++; 

				jQueryselect = jQuery("<select></select>")
					.addClass(options.selectClass)
					.attr('name', options.selectClass + index)
					.attr('id', options.selectClass + index); 

				jQueryselectRemoved = jQuery("<select></select>"); 

				jQueryol = jQuery("<" + options.listType + "></" + options.listType + ">")
					.addClass(options.listClass)
					.attr('id', options.listClass + index); 

				jQuerycontainer = jQuery("<div></div>")
					.addClass(options.containerClass) 
					.attr('id', options.containerClass + index); 

				buildSelect();

				jQueryselect.change(selectChangeEvent)
					.click(selectClickEvent); 

				jQueryoriginal.change(originalChangeEvent)
					.wrap(jQuerycontainer).before(jQueryselect).before(jQueryol);

				if(options.sortable) makeSortable();

				if(jQuery.browser.msie && jQuery.browser.version < 8) jQueryol.css('display', 'inline-block'); // Thanks Matthew Hutton
			}

			function makeSortable() {

				// make any items in the selected list sortable
				// requires jQuery UI sortables, draggables, droppables

				jQueryol.sortable({
					items: 'li.' + options.listItemClass,
					handle: '.' + options.listItemLabelClass,
					axis: 'y',
					update: function(e, data) {

						var updatedOptionId;

						jQuery(this).children("li").each(function(n) {

							jQueryoption = jQuery('#' + jQuery(this).attr('rel')); 

							if(jQuery(this).is(".ui-sortable-helper")) {
								updatedOptionId = jQueryoption.attr('id'); 
								return;
							}

							jQueryoriginal.append(jQueryoption); 
						}); 

						if(updatedOptionId) triggerOriginalChange(updatedOptionId, 'sort'); 
					}

				}).addClass(options.listSortableClass); 
			}

			function selectChangeEvent(e) {
				
				// an item has been selected on the regular select we created
				// check to make sure it's not an IE screwup, and add it to the list

				if(jQuery.browser.msie && jQuery.browser.version < 7 && !ieClick) return;
				var id = jQuery(this).children("option:selected").slice(0,1).attr('rel'); 
				addListItem(id); 	
				ieClick = false; 
				triggerOriginalChange(id, 'add'); // for use by user-defined callbacks
			}

			function selectClickEvent() {

				// IE6 lets you scroll around in a select without it being pulled down
				// making sure a click preceded the change() event reduces the chance
				// if unintended items being added. there may be a better solution?

				ieClick = true; 
			}

			function originalChangeEvent(e) {

				// select or option change event manually triggered
				// on the original <select multiple>, so rebuild ours

				if(ignoreOriginalChangeEvent) {
					ignoreOriginalChangeEvent = false; 
					return; 
				}

				jQueryselect.empty();
				jQueryol.empty();
				buildSelect();

				// opera has an issue where it needs a force redraw, otherwise
				// the items won't appear until something else forces a redraw
				if(jQuery.browser.opera) jQueryol.hide().fadeIn("fast");
			}

			function buildSelect() {

				// build or rebuild the new select that the user
				// will select items from

				buildingSelect = true; 

				// add a first option to be the home option / default selectLabel
				jQueryselect.prepend("<option>" + jQueryoriginal.attr('title') + "</option>"); 

				jQueryoriginal.children("option").each(function(n) {

					var jQueryt = jQuery(this); 
					var id; 

					if(!jQueryt.attr('id')) jQueryt.attr('id', 'asm' + index + 'option' + n); 
					id = jQueryt.attr('id'); 

					if(jQueryt.is(":selected")) {
						addListItem(id); 
						addSelectOption(id, true); 						
					} else {
						addSelectOption(id); 
					}
				});

				if(!options.debugMode) jQueryoriginal.hide(); // IE6 requires this on every buildSelect()
				selectFirstItem();
				buildingSelect = false; 
			}

			function addSelectOption(optionId, disabled) {

				// add an <option> to the <select>
				// used only by buildSelect()

				if(disabled == undefined) var disabled = false; 

				var jQueryO = jQuery('#' + optionId); 
				var jQueryoption = jQuery("<option>" + jQueryO.text() + "</option>")
					.val(jQueryO.val())
					.attr('rel', optionId);

				if(disabled) disableSelectOption(jQueryoption); 

				jQueryselect.append(jQueryoption); 
			}

			function selectFirstItem() {

				// select the firm item from the regular select that we created

				jQueryselect.children(":eq(0)").attr("selected", true); 
			}

			function disableSelectOption(jQueryoption) {

				// make an option disabled, indicating that it's already been selected
				// because safari is the only browser that makes disabled items look 'disabled'
				// we apply a class that reproduces the disabled look in other browsers

				jQueryoption.addClass(options.optionDisabledClass)
					.attr("selected", false)
					.attr("disabled", true);

				if(options.hideWhenAdded) jQueryoption.hide();
				if(jQuery.browser.msie) jQueryselect.hide().show(); // this forces IE to update display
			}

			function enableSelectOption(jQueryoption) {

				// given an already disabled select option, enable it

				jQueryoption.removeClass(options.optionDisabledClass)
					.attr("disabled", false);

				if(options.hideWhenAdded) jQueryoption.show();
				if(jQuery.browser.msie) jQueryselect.hide().show(); // this forces IE to update display
			}

			function addListItem(optionId) {

				// add a new item to the html list

				var jQueryO = jQuery('#' + optionId); 

				if(!jQueryO) return; // this is the first item, selectLabel

				var jQueryremoveLink = jQuery("<a></a>")
					.attr("href", "#")
					.addClass(options.removeClass)
					.prepend(options.removeLabel)
					.click(function() { 
						dropListItem(jQuery(this).parent('li').attr('rel')); 
						return false; 
					}); 

				var jQueryitemLabel = jQuery("<span></span>")
					.addClass(options.listItemLabelClass)
					.html(jQueryO.html()); 

				var jQueryitem = jQuery("<li></li>")
					.attr('rel', optionId)
					.addClass(options.listItemClass)
					.append(jQueryitemLabel)
					.append(jQueryremoveLink)
					.hide();

				if(!buildingSelect) {
					if(jQueryO.is(":selected")) return; // already have it
					jQueryO.attr('selected', true); 
				}

				if(options.addItemTarget == 'top' && !buildingSelect) {
					jQueryol.prepend(jQueryitem); 
					if(options.sortable) jQueryoriginal.prepend(jQueryO); 
				} else {
					jQueryol.append(jQueryitem); 
					if(options.sortable) jQueryoriginal.append(jQueryO); 
				}

				addListItemShow(jQueryitem); 

				disableSelectOption(jQuery("[rel=" + optionId + "]", jQueryselect));

				if(!buildingSelect) {
					setHighlight(jQueryitem, options.highlightAddedLabel); 
					selectFirstItem();
					if(options.sortable) jQueryol.sortable("refresh"); 	
				}

			}

			function addListItemShow(jQueryitem) {

				// reveal the currently hidden item with optional animation
				// used only by addListItem()

				if(options.animate && !buildingSelect) {
					jQueryitem.animate({
						opacity: "show",
						height: "show"
					}, 100, "swing", function() { 
						jQueryitem.animate({
							height: "+=2px"
						}, 50, "swing", function() {
							jQueryitem.animate({
								height: "-=2px"
							}, 25, "swing"); 
						}); 
					}); 
				} else {
					jQueryitem.show();
				}
			}

			function dropListItem(optionId, highlightItem) {

				// remove an item from the html list

				if(highlightItem == undefined) var highlightItem = true; 
				var jQueryO = jQuery('#' + optionId); 

				jQueryO.attr('selected', false); 
				jQueryitem = jQueryol.children("li[rel=" + optionId + "]");

				dropListItemHide(jQueryitem); 
				enableSelectOption(jQuery("[rel=" + optionId + "]", options.removeWhenAdded ? jQueryselectRemoved : jQueryselect));

				if(highlightItem) setHighlight(jQueryitem, options.highlightRemovedLabel); 

				triggerOriginalChange(optionId, 'drop'); 
				
			}

			function dropListItemHide(jQueryitem) {

				// remove the currently visible item with optional animation
				// used only by dropListItem()

				if(options.animate && !buildingSelect) {

					jQueryprevItem = jQueryitem.prev("li");

					jQueryitem.animate({
						opacity: "hide",
						height: "hide"
					}, 100, "linear", function() {
						jQueryprevItem.animate({
							height: "-=2px"
						}, 50, "swing", function() {
							jQueryprevItem.animate({
								height: "+=2px"
							}, 100, "swing"); 
						}); 
						jQueryitem.remove(); 
					}); 
					
				} else {
					jQueryitem.remove(); 
				}
			}

			function setHighlight(jQueryitem, label) {

				// set the contents of the highlight area that appears
				// directly after the <select> single
				// fade it in quickly, then fade it out

				if(!options.highlight) return; 

				jQueryselect.next("#" + options.highlightClass + index).remove();

				var jQueryhighlight = jQuery("<span></span>")
					.hide()
					.addClass(options.highlightClass)
					.attr('id', options.highlightClass + index)
					.html(label + jQueryitem.children("." + options.listItemLabelClass).slice(0,1).text()); 
					
				jQueryselect.after(jQueryhighlight); 

				jQueryhighlight.fadeIn("fast", function() {
					setTimeout(function() { jQueryhighlight.fadeOut("slow"); }, 50); 
				}); 
			}

			function triggerOriginalChange(optionId, type) {

				// trigger a change event on the original select multiple
				// so that other scripts can pick them up

				ignoreOriginalChangeEvent = true; 
				jQueryoption = jQuery("#" + optionId); 

				jQueryoriginal.trigger('change', [{
					'option': jQueryoption,
					'value': jQueryoption.val(),
					'id': optionId,
					'item': jQueryol.children("[rel=" + optionId + "]"),
					'type': type
				}]); 
			}

			init();
		});
	};

})(jQuery); 
