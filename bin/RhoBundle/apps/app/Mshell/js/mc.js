// Add data-cache="false" support to JQM
$(':jqmData(role="page"):jqmData(cache="false"),:jqmData(role="dialog"):jqmData(cache="false")').live('pagehide', function( event ) {
    $(this).remove()
})

// Swipe right for history back
$(':jqmData(role="page")').live('swiperight', function( event ) {
    // check for the data-swipe="ignore"
    var dataSwipe = $(this).attr('data-swipe')
    var ignore = typeof dataSwipe != "undefined" && dataSwipe.toLowerCase() === "ignore"
    if ( !ignore ) {
        history.back()
    }
})

// Swipe left for history back
$(':jqmData(role="page")').live('swipeleft', function( event ) {
    var dataSwipe = $(this).attr('data-swipe')
    var ignore = typeof dataSwipe != "undefined" && dataSwipe.toLowerCase() === "ignore"
    if ( !ignore ) {
        history.forward()
    }
})

// enable menus
$(':jqmData(role="page")').live('pagecreate', function() {
    
    $.fixedToolbars.setTouchToggleEnabled(false)

    var page = $(this)

    // Menu
    var menuButton = page.find(".menu-link")
    if ( menuButton.length > 0 ) {
        var menu = page.find("div.menu")
        hideMenu(page, menuButton)
        enableMenu( page, menuButton, menu, showMenu, hideMenu)
    }

    // More Menu
    var moreMenuButton = page.find("#more-link")
    if ( moreMenuButton.length > 0 ) {
        var moreMenu = page.find("#more-menu")
        hideMoreMenu(page, moreMenu)
        enableMenu( page, moreMenuButton, moreMenu, showMoreMenu, hideMoreMenu)
    }
})

$(':jqmData(role="page")').live('pagebeforeshow', function() {
    $.fixedToolbars.show(true)
})

function showMenu(page, menu) {
    var numberOfOptions = menu.find('ul li').length
    var liWidth = numberOfOptions <= 3 ? (Math.round( 100 / numberOfOptions ) - 1) + '%' : "33%"
    menu.css('top', $(window).scrollTop() + 43 + 'px')
    page.find('div.menu-tab').css('top', $(window).scrollTop() + 2 + 'px')
    menu.find('ul li').css('width', liWidth)
    menu.fadeIn()
	page.find("div.menu-tab").fadeIn()
}

function hideMenu(page, menu) {
	menu.fadeOut()
	page.find("div.menu-tab").fadeOut()
}

function showMoreMenu(page, menu) {
    var bottomScroll = page.outerHeight() - window.innerHeight - $(window).scrollTop()
    menu.css('bottom', bottomScroll + 50)
    page.find('#more-link').addClass("selected")
    menu.fadeIn()
}

function hideMoreMenu(page, menu) {
    page.find('#more-link').removeClass("selected")
    menu.fadeOut()
}

function enableMenu(page, button, menu, showMenu, hideMenu) {
    // ensure hidden to start with
    hideMenu(page, menu)
    
    // bind for the click on the menu button
    button.bind('click', function(event) {
        // unbind so we don't get extra clicks
        button.unbind(event)
        
        // show the menu
        showMenu(page, menu)
        
        // dimiss on a click to anywhere on the page, but disable all link except in the menu
        page.bind('click', function(event) {
	        var followLinkFlag = false
	        var hideMenuFlag = true
	        
	        if ( menu.has(event.target).length > 0 && $(event.target).is('a') ) {
	            // clicked a menu link
	            followLinkFlag = true
	            hideMenuFlag = true
	        } else if ( $(event.target).get(0) === menu.get(0) ||
	                    menu.has(event.target).length > 0 ) {
                        
                // click on a non-link part of menu, just ignore it
	            followLinkFlag = false
                hideMenuFlag = false
	        }
	        
	        if ( hideMenuFlag )
	        {
                // unbind the page click
	            page.unbind(event)
                
	            // hide the menu
	            hideMenu(page, menu)
	            
	            // re-enable menu button click
	            enableMenu(page, button, menu, showMenu, hideMenu)
	        }
	        
	        if ( !followLinkFlag ) event.preventDefault()
            return followLinkFlag
        })
        
        // stop click propigation
        event.preventDefault()
        return false
    })
}

// Ensure current m-Aapp is set - controller is not invoked if the page is cached
$(':jqmData(role="page"):jqmData(url*="launch_mapp")').live('pagebeforeshow', function(event) {
    var url = "/app/Mshell/set_mapp?id=" + $(this).attr("data-url").match(/(\?id=)(.*)/)[2]
    $.getJSON( url, function(json) {
        // success
    })
})

// fire clicks to sign in links so that destintation is correct
$(':jqmData(role="page")').live('pagecreate', function() {
    var page = $(this)

    // Click on Sign In
    $(this).find('a.signIn-link').bind('click', function(event) {
        var success_url = page.attr('data-url'),
            transition = $(this).attr('data-transition'),
            url = $(this).attr('href'),
        data = { success_url: success_url }

        if ( !transition ) transition = "pop"

        $.mobile.changePage( url, {
            transition: transition,
            role: 'dialog',
            changeHash: false,
            data: data,
            reloadPage: true } )
            
        event.preventDefault()
        return false
    })
    
    // click on Sign Out
    $(this).find('a.signOut-link').bind('click', function(event) {
        var success_url = page.attr('data-url'),
            transition = $(this).attr('data-transition'),
            direction =  $(this).attr('data-direction'),
            url = $(this).attr('href')

        if ( !transition ) transition = "pop"
        
        reverse = false
        if ( direction && direction === "reverse" ) reverse = true

        $.getJSON( url, function(json) {
            $.mobile.changePage( success_url, {
                transition: transition,
                reverse: reverse,
                changeHash: false,
                reloadPage: true } )
        })
            
        event.preventDefault()
        return false
    })
})