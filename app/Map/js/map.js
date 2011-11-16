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

function changeCampus(campusStr) {
	var campusPos = config[""+campusStr];
	map.panTo(campusPos);
	map.setZoom(15);
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
	//console.log("attempting pan to: " + config.currentCampus);
	changeCampus(config.currentCampus);
	updateFTLayer();
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
	//console.log("updateFTLayer with campus: " + currentCampus + " src id: " + defaultSrcId);
	if (!config.FTLayer) {
		//we need to create our layer!
		config.FTLayer = new google.maps.FusionTablesLayer({
			styles: [{
				where: "icon = 'building'",
				markerOptions: {
					iconName: "buildings"
				}
			},
			{
				where: "icon = 'parking_lot'",
				markerOptions: {
					iconName: "parking_lot"
				}
			}],
			query: {
				select: "location, building, abbrv",
				from: defaultSrcId,
				where: 'campus = \'' + currentCampus + '\''
			}
		});
		config.FTLayer.setMap(map);
	    google.maps.event.addListener(config.FTLayer, 'click', displayMarkerBox);
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
}

function reduceLayer(newCampus, abbrvStr) {
	var defaultSrcId = config.defaultSrcId;
	changeCampus(newCampus);
	//console.log("updateFTLayer with campus: " + newCampus + " abbrv: " + abbrvStr);
	if(config.FTLayer) {
		config.FTLayer.setOptions({
			query: {
				select: "location, building, abbrv",
				from: defaultSrcId,
				where: 'campus = \'' + newCampus + '\' AND abbrv = \'' + abbrvStr + '\''
			}
		});
	}
}

function initializeMap() {
	var button = $("#map-show-page").find('a.[data-role="radio-button"].ui-btn-active');
	config.currentCampus = button.attr('data-map');
	config.defaultSrcId = button.attr('data-srcid');
	config.Main = new google.maps.LatLng(29.5828745,-98.6187745);
	config.Downtown = new google.maps.LatLng(29.423880,-98.503339);
	config.ITC = new google.maps.LatLng(29.416701,-98.482186);
	config.mapOpts = {
			zoom: 15,
			center: config.Main,
			mapTypeControl: true,
			mapTypeControlOptions: {
				style: google.maps.MapTypeControlStyle.DROPDOWN_MENU
			},
			zoomControl: true,
			zoomControlOptions: {
				style: google.maps.ZoomControlStyle.SMALL
			},
		    mapTypeId: google.maps.MapTypeId.SATELLITE
			//mapTypeId: google.maps.MapTypeId.ROADMAP
	};
	//console.dir(document.getElementById("map-div"));
	map = new google.maps.Map($("#map-div")[0], config.mapOpts);
	updateFTLayer();
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
	var content = '<div id="info-content"><b>' + mouseEvent.row['building'].value + ' ('+ mouseEvent.row['abbrv'].value +')</b></div>';
	mouseEvent.infoWindowHtml = content;
}

//event handler for navigation button clicks
$('a.[data-role="radio-button"]').live('click', function() {
	loadSelectedMap($(this));
    return true
});

//event handler for navigation button clicks
$('a.place').live('click', function(evt) {
	var passed = $(evt.target).data(),
		campus = passed.campus,
		abbrv = passed.abbrv;
	config.reduce = { "campus": campus, "abbrv": abbrv};
	google.maps.event.trigger(map, 'resize');
	reduceLayer(campus, abbrv);
	evt.preventDefault();
	evt.stopPropagation();
	config.event = evt;
	$(".ui-dialog").dialog('close');
	//$('.ui-dialog').dialog('close');
	//$("#search-show-page").
	return true
});

$('#map-show-page').live("pagecreate", function() {
	initializeMap();
});

$('#map-show-page').live('pageshow',function(){
	setContentHeight();
	google.maps.event.trigger(map, 'resize');
	getGeoLocation();
});

//disable clicking on terms
$('#map-show-page #map-div a').live("click", function(event) {
    /* kludge to fix linking to terms of service and map link */
    event.preventDefault()
    return false    
});