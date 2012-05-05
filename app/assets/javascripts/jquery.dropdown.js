//Source: http://davidwalsh.name/twitter-dropdown-jquery
$(document).ready(function() {
	/* for keeping track of what's "open" */
	var activeClass = 'dropdown-active', showingDropdown, showingMenu, showingParent;
	/* hides the current menu */
	var hideMenu = function() {
		if(showingDropdown) {
			showingDropdown.removeClass(activeClass);
			showingMenu.hide();
		}
	};
	
	/* recurse through dropdown menus */
	$('.dropdown').each(function() {
		/* track elements: menu, parent */
		var dropdown = $(this);
		var menu = dropdown.next('div.dropdown-menu'), parent = dropdown.parent();
		/* function that shows THIS menu */
		var showMenu = function() {
			hideMenu();
			showingDropdown = dropdown.addClass('dropdown-active');
			showingMenu = menu.show();
			showingParent = parent;
		};
		/* function to show menu when clicked */
		dropdown.bind('click',function(e) {
			if(e) e.stopPropagation();
			if(e) e.preventDefault();
			showMenu();
		});
		/* function to show menu when someone tabs to the box */
		dropdown.bind('focus',function() {
			showMenu();
		});
		
		/* For each menu item */
		menu.find('a').each(function() {
		  /* Function to hide menu once menu item clicked */
		  $(this).bind('click', function(e) {
		    hideMenu();
		  });
		});
		
	});
	
	/* hide when clicked outside */
	$(document.body).bind('click',function(e) {
		if(showingParent) {
			var parentElement = showingParent[0];
			if(!$.contains(parentElement,e.target) || !parentElement == e.target) {
				hideMenu();
			}
		}
	});
});

