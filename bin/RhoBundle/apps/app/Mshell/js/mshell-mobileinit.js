// Fix issue with dialog adding ui-body-a regardless of the data-theme

// JQuery Mobile 1.0 doesn't set data-theme for dialogs
$(document).bind("mobileinit", function() {
    // Configure JQuery Mobile
    
    $.mobile.minScrollBack = "50"
    
    // fetch language specific loading and error loading messages
    $.getJSON( "/app/Mshell/get_jquery_mobile_locale_strings", function(json) {
        $.mobile.loadingMessage = json.loadingMessage
        $.mobile.pageLoadErrorMessage = json.errorLoadingMessage
    })
    
    // live bind to dialogs with a data-theme
    $('div[data-role="dialog"]*[data-theme]').live("pagecreate", function() {
        theme = $(this).attr('data-theme')

        // exchange ui-body-* class to match the theme
        if ( $(this).hasClass('ui-body-a')) {
            $(this).removeClass('ui-body-a').addClass( 'ui-body-' + theme )
        }
    })
})