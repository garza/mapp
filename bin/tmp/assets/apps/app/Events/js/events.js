$('#events-search-form').live('submit', function() {    
        events_search()        
    return false
})

function events_search() {
    // kill keyboard
    if( window.document.activeElement ){
    	$( window.document.activeElement || "" ).add( "input:focus, textarea:focus, select:focus" ).blur();
    }
	var selectedCategories = $("#categories").val() || [];			
    var selectedCalendars = $("#calendars").val() || [];	
    var startDate = $("#startDate").val();
    var endDate = $("#endDate").val();
    var keywords = $("#keywords").val();	
    $.mobile.changePage("/app/Events/search_for_events?categories="+selectedCategories.join(",")+"&keywords="+keywords+"&calendars="+selectedCalendars.join(",")+"&startDate="+startDate+"&endDate="+endDate);
}

$('#events-show-search-page').live('pageshow', function() {
    $(this).find('#startDate').val("")
    $(this).find('#endDate').val("")
})

$("#search-events").live('click', function() {		
		events_search()
})
