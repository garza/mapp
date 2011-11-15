// When map page opens get location and display map

var config = config ? config : {},
map = null;


/*
navigator.geolocation.getCurrentPosition(function(){
	console.log(this);
})
*/
function getGeoLocation() {
	$.get("/system/geolocation",function(data){
		data = data.split(";");
		$("#map-show-header").attr("data-latitude", data[1]);
		$("#map-show-header").attr("data-longitude", data[2]);
		$("#map-show-header").attr("data-location", data[0]);
		updatePosition();
		setTimeout("getGeoLocation()",30000);
	});
}

/* Update our current position on the map */
function updatePosition() {
	var lat = parseFloat($("#map-show-header").attr("data-latitude")),
		lng = parseFloat($("#map-show-header").attr("data-longitude"));
	//console.log("lat:" + lat + "lng:" + lng);
	if (!isNaN(lat) && !isNaN(lng)) {
		if (config.myPos && config.myMarker && map) {
			//our map objects exists no need to recreate
			config.myPos = new google.maps.LatLng(lat, lng);
			config.myMarker.setPosition(config.myPos);
		} else {
			//our map objects don't exists, create them from scratch and place on map
			config.myPos = new google.maps.LatLng(lat, lng);
			config.geo = true;
			var image = new google.maps.MarkerImage('/app/Map/images/rowdy_marker.png',
				// This marker is 40 pixels wide by 32 pixels tall.
				new google.maps.Size(40, 32),
				// The origin for this image is 0,0.
				new google.maps.Point(0,0),
				// The anchor for this image is the base of the shield at 32,12.
				new google.maps.Point(12,32));
			var shape = {
				coord: [0,0,   0,21,   31,21,   31,0,   0,0],
				type: 'poly'
			};
			config.myMarker = new google.maps.Marker({
				position: config.myPos,
				map: map,
				icon: image,
				animation: google.maps.Animation.DROP,
				shape: shape,
				title: 'Your Location'
			});
		}
	}
}

/* load our map center co-ordinates for each major map */
function loadCampuses() {
}

function loadSelectedMap(jqObject) {
	var campusName = null,
		button = jqObject,
		page = jqObject;
	if ( jqObject.attr('data-role') === "page") {
		//we were given a page, not a button
		button = page.find('a.[data-role="radio-button"].ui-btn-active');
	} else {
		//we were given a button, set the page correctly
		page = $.mobile.activePage;
	}
	
	config.currentCampus = button.attr('data-map');
	config.defaultSrcId = button.attr('data-srcid');
	console.log("attempting pan to:");
	console.dir(config);
	map.panTo(config[config.currentCampus]); 
	//updateFTLayer();
	map.setZoom(17);
}

function loadMap(page) {
	config.map = new google.maps.Map(document.getElementById("map-div"), config.mapOpts);
	//updateFTLayer();
	//DEBUG COMMENT OUT NEXT LINE
	getGeoLocation();
	page.data('map', config.map);
}

function updateFTLayer() {
	var defaultSrcId = config.defaultSrcId,
		currentCampus = config.currentCampus;
	if (!currentCampus) {
		currentCampus = "Main";
	}
	if (!defaultSrcId) {
		defaultSrcId = 2052993;
	}
	console.log("updateFTLayer with campus: " + currentCampus + " src id: " + defaultSrcId);
	if (!config.FTLayer) {
		//we need to create our layer!
		config.FTLayer = new google.maps.FusionTablesLayer({
			styles: [{
				markerOptions: {
					iconName: "buildings"
				}
			}],
			query: {
				select: "location, building, abbrv",
				from: defaultSrcId,
				where: 'campus = \'' + currentCampus + '\''
			}
		});
		//config.FTLayer.setQuery("select Abbrv, Building from 2052993");
	} else {
		//we just need to update our layer options
		config.FTLayer.setOptions({
			query: {
				select: "location, building, abbrv",
				from: defaultSrcId,
				where: 'campus = \'' + currentCampus + '\''
			}
		});
	}
	config.FTLayer.setMap(config.map);
    google.maps.event.addListener(config.FTLayer, 'click', displayMarkerBox);
}


function initializeMap() {
	config.Main = new google.maps.LatLng(29.583310,-98.619285);
	config.Downtown = new google.maps.LatLng(29.423880,-98.503339);
	config.ITC = new google.maps.LatLng(29.416701,-98.482186);
	config.mapOpts = {
			zoom: 17,
			center: config.Main,
			mapTypeControl: true,
			mapTypeControlOptions: {
				style: google.maps.MapTypeControlStyle.DROPDOWN_MENU
			},
			zoomControl: true,
			zoomControlOptions: {
				style: google.maps.ZoomControlStyle.SMALL
			},
			mapTypeId: google.maps.MapTypeId.ROADMAP
	};
	console.dir(document.getElementById("map-div"));
	map = new google.maps.Map($("#map-div")[0], config.mapOpts);
	//document.getElementById("map-div"), config.mapOpts);
}

function setContentHeight() {
    // adjust content height to be page height - minus footer and header
    var page = $("#map-show-page"), 
		header = page.find('[data-role="header"]'),
		content = page.find('[data-role="content"]'),
		mapDiv = page.find('[data-role="content"] #map-div'),
		footer = page.find('[data-role="footer"]'),
		newHeight = page.outerHeight() - header.outerHeight() - footer.outerHeight();
    content.css('height', newHeight);
}

function displayMarkerBox(mouseEvent) {
	console.dir(mouseEvent);
	var content = '<div id="content"><b>' + mouseEvent.row['building'].value + ' ('+ mouseEvent.row['abbrv'].value +')</b></div>';
	mouseEvent.infoWindowHtml = content;
}


//event handler for navigation button clicks
$('a.[data-role="radio-button"]').live('click', function() {
	loadSelectedMap($(this));
    return true
});


$('#map-show-page').live("pagecreate", function() {
	console.log("pagecreate");
});

$('#map-show-page').live('pageshow',function(){
	console.log("pageshow");
	initializeMap();
	google.maps.event.trigger(map, 'resize');
	map.setOptions(config.mapOpts); 
});

/*
$('#map-show-page').live("pageshow", function() {
	console.log("Set Content Height");
	setContentHeight();
	console.log("Init Map");
	initializeMap();
});

$('#map-show-page').live("pageshow", function() {    
	//google.maps.event.trigger(config.map, 'resize');
	//config.map.setOptions(config.mapOpts);
	//loadCampuses();
	//loadMap(page);
	//loadSelectedMap(page);
});
*/

//disable clicking on terms
//$('#map-show-page #map-div a').live("click", function(event) {
    /* kludge to fix linking to terms of service and map link */
    //event.preventDefault()
    //return false    
//});

