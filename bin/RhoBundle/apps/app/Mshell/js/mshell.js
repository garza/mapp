$('#mshell-index-page').live('pagecreate pageshow', function(event) {
    var ignoreNextIndexPageShow = false
    
    if ( event.type === "pageshow" && ignoreNextIndexPageShow ) {
        ignoreNextIndexPageShow = false
    } else {
        if ( event.type === "pagecreate" ) {
            ignoreNextIndexPageShow = true
        }
        $.mobile.changePage( "/app/Mshell/show", { transition: 'fade', reloadPage: true } )
    }
})

$('#list-mshell-show-page,#icon-mshell-show-page').live('pagecreate', function() {
    
    var ignoreNextDiclick = false
    $(this).find('a.footerLogIn').parents('div:first').bind( 'click', function(event) {
        if ( ignoreNextDiclick ) {
            ignoreNextDiclick = false
        }
        else {
            ignoreNextDiclick = true
            $(this).find('a.footerLogIn').click()
        }
    })
})

$('#list-mshell-show-page,#icon-mshell-show-page').live('pageshow', function() {
    // seems to be an issue with it not being at the top with fixed headers
    // always scroll to top for now
    $(window).scrollTop(0)
})

/* Login */
$('#mshell-login-page').live('pagecreate', function() {
    $(this).find('#login-login-failed').hide()
    $(this).find('#login-password').val('')
    $('#list-login-form').submit( function(event) {
        // kill keyboard
        if( window.document.activeElement ){
            $( window.document.activeElement || "" ).add( "input:focus, textarea:focus, select:focus" ).blur();
        }

        // Show the loading message
        $.mobile.pageLoading();

        //loginUrl = $(this).attr('ajax-action')
        var loginUrl = $('#login-url').val()
        var launchMappId = $('#launch-mapp-id').val()
        mappJqmEnabled = $('#mapp-jqm-enabled').val()
        $.getJSON( loginUrl, $(this).serialize(),
                   function(json) {
            $.mobile.pageLoading(true)

            if (json.result === "success") {
                // hide the error message
                $('#login-login-failed').fadeOut()
                
                if ( json.authorized == undefined || json.authorized ) {
                    // Launch the mapp
                    var destination = $('#login-success-url').val()
                    if ( !destination || destination == "" ) {
                        history.back()
                    } else {
                        if ( launchMappId != "" && mappJqmEnabled != "true" ) {
                            window.open( destination , "_self", '', false )
                        } else {
                            $.mobile.changePage( destination, { transition: 'pop', reverse: true, reloadPage: true } )                    
                        }
                    }
                } else {
                    // Not Authorized to view mapp
                    var destination = $('#login-not-authorized-url').val()
                    if ( destination ) {
                        $.mobile.changePage( destination, { role: "dialog", transition: 'pop', reloadPage: true } )                        
                    } else {
                        alert( "login-not-authorized-url is not defined - please report")
                    }
                }
                
            } else {
                // show the error message
                $('#login-login-failed').fadeIn()
            }
        })

        // always stop the submit - login result will determine if the login page is dismissed
        event.preventDefault()    
        return false;
    })
})

$('#mshell-login-page').live('pagebeforeshow', function(event, ui) {
    
    // Fix data-url
    //$(this).attr('data-url', '/app/Mshell/show_login')
    
    $(this).find('#login-login-failed').hide()
    $(this).find('#login-password').val('')
    
    // save off the previous page
    $.mobile.activePage.data('previousPage', ui.prevPage)
})

$('#list-mshell-show-page #mode,#icon-mshell-show-page #mode').live('click', function() {
    var url = "/app/Mshell/set_mode?mode=" + $(this).attr("data-mode")
    $.mobile.pageLoading()
    $.getJSON( url, function(json) {
        $.mobile.pageLoading(true)
        window.location = "/app/Mshell"
    })
})