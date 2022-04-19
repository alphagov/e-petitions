(function () {
  var PetitionMap = this.PetitionMap;
  var data = PetitionMap.data;
  var layers = PetitionMap.layers = {};
  var controls = PetitionMap.controls = {};
  var currentView = null;
  var currentCount = null;
  var currentLayer = null;
  var currentFeature = null;
  var moving = false;
  var zooming = false;

  var map = PetitionMap.map = L.map('map', {
    attributionControl: false,
    doubleClickZoom: false,
    zoomControl: false,
    zoomSnap: 0.1,
    zoomDelta: 0.5,
    zoom: 5
  });

  var defaultMapView = function() {
    params = new URLSearchParams(window.location.search);
    viewParam = params.get('view');

    switch (viewParam) {
      case 'countries':
      case 'regions':
      case 'constituencies':
        return viewParam;
      default:
        return 'constituencies';
    }
  }

  var defaultMapCount = function() {
    params = new URLSearchParams(window.location.search);
    countParam = params.get('count');

    switch (countParam) {
      case 'signatures':
      case 'constituents':
        return countParam;
      default:
        return 'signatures';
    }
  }

  var updateWindowHref = function() {
    var path = window.location.pathname;
    var params = new URLSearchParams();

    params.set('view', currentView);
    params.set('count', currentCount);

    window.history.replaceState(null, '', path + '?' + params.toString());
  }

  var ensureMapIsVisible = function (layer) {
    var padding = 72;
    var size = map.getSize();
    var topRight = map.containerPointToLatLng([size.x - padding, padding]);
    var bottomLeft = map.containerPointToLatLng([padding, size.y - padding]);
    var bounds = layer.getBounds();
    var deltaX = 0, deltaY = 0;

    if (topRight.lng < bounds.getWest()) {
      var point = map.latLngToContainerPoint(bounds.getSouthWest());
      deltaX = point.x - size.x + padding;
    } else if (bottomLeft.lng > bounds.getEast()) {
      var point = map.latLngToContainerPoint(bounds.getNorthEast());
      deltaX = -(padding - point.x);
    }

    if (topRight.lat < bounds.getSouth()) {
      var point = map.latLngToContainerPoint(bounds.getSouthWest());
      deltaY = -(padding - point.y);
    } else if (bottomLeft.lat > bounds.getNorth()) {
      var point = map.latLngToContainerPoint(bounds.getNorthEast());
      deltaY = padding - (size.y - point.y)
    }

    map.panBy([deltaX, deltaY], { noMoveStart: true, animate: false });
  }

  PetitionMap.resetView = function () {
    map.fitBounds(currentLayer.getBounds(), { padding: [25, 25], animate: false });
  }

  PetitionMap.setCurrentView = function (newView) {
    if (currentLayer) {
      currentLayer.removeFrom(map);
    }

    var newData = data[newView];
    var newLayer = layers[newView];
    var bounds = newLayer.getBounds();

    map.setMaxBounds([[90, 180], [-90, -180]]);
    map.setMinZoom(0);
    map.setMaxZoom(20);
    map.setZoom(20);
    map.panTo([0, 0]);

    currentView = newView;
    currentLayer = newLayer;
    currentLayer.eachLayer(resetFeature);
    map.addLayer(currentLayer);

    map.setMinZoom(newData.minZoom);
    map.setMaxZoom(newData.maxZoom);
    map.fitBounds(bounds, { padding: [25, 25], animate: false });
    map.panTo(newData.mapCenter, { noMoveStart: true, animate: false });

    updateWindowHref();

    if (controls.featureInfo) {
      controls.featureInfo.resetFeatureInfo();
    }
  }

  PetitionMap.getCurrentView = function () {
    return currentView;
  }

  PetitionMap.setCurrentCount = function (newCount) {
    currentCount = newCount;

    if (currentLayer) {
      currentLayer.eachLayer(resetFeature);
      updateWindowHref();
    }

    if (controls.featureInfo) {
      controls.featureInfo.resetFeatureInfo();
    }
  }

  PetitionMap.getCurrentCount = function () {
    return currentCount;
  }

  PetitionMap.hideControls = function () {
    controls.petitionInfo.hide();
    controls.mapSwitcher.hide();

    if (currentFeature) {
      resetFeature(currentFeature)
      controls.featureInfo.resetFeatureInfo();
      currentFeature = null;
    }
  }

  data.constituencies.initialize(data.petition);
  data.regions.initialize(data.petition);
  data.countries.initialize(data.petition);

  var tooltipOptions = {
    direction: 'top',
    sticky: true,
    interactive: true
  }

  var calculateFillOpactity = function (scale, percentage) {
    if (percentage < 0.00000001) {
      return 0;
    } else {
      return (1 / scale) * percentage * 0.8 + 0.05;
    }
  }

  var fillOpacity = function (properties) {
    if (currentCount == 'constituents') {
      return calculateFillOpactity(
        properties.populationColourScale,
        properties.percentageOfPopulation
      );
    } else {
      return calculateFillOpactity(
        properties.signatureColourScale,
        properties.percentageOfSignatures
      );
    }
  }

  var featureStyle = function (feature) {
    return {
      fillColor: '#C9187E',
      fillOpacity: fillOpacity(feature.properties),
      fillPattern: null,
      color: '#747474',
      opacity: 1.0,
      weight: 1
    }
  }

  var resetFeature = function (layer) {
    layer.setStyle(featureStyle(layer.feature));
  }

  var highlightFeature = function (layer) {
    var properties = layer.feature.properties;

    var style = {
      color: '#3C3C3B',
      fillColor: null,
      fillPattern: null,
      fillOpacity: 1.0,
      weight: 2
    };

    if (properties.partyColour) {
      style.fillColor = properties.partyColour;
    } else if (properties.partyPattern) {
      style.fillPattern = properties.partyPattern;
    } else {
      style.fillOpacity = fillOpacity(properties);
      style.fillColor = '#C9187E';
    }

    layer.setStyle(style);
    layer.bringToFront();
  }

  var onMouseMoveFeature = function (e) {
    if (!moving && !zooming && !e.target.isTooltipOpen()) {
      e.target.openTooltip();
    }
  }

  var onMouseOverFeature = function (e) {
    if (!zooming) {
      highlightFeature(e.target);
    }
  }

  var onMouseOutFeature = function (e) {
    if (e.target != currentFeature) {
      resetFeature(e.target);
    }
  }

  var onClickFeature = function (e) {
    controls.petitionInfo.hide();
    controls.mapSwitcher.hide();

    if (currentFeature && currentFeature != e.target) {
      resetFeature(currentFeature);
      controls.featureInfo.resetFeatureInfo();
    }

    currentFeature = e.target;
    highlightFeature(currentFeature);
    controls.featureInfo.setFeatureInfo(currentFeature.feature);
  }

  var onEachFeature = function (feature, layer) {
    layer.on({
      mousemove: onMouseMoveFeature,
      mouseover: onMouseOverFeature,
      mouseout: onMouseOutFeature,
      click: onClickFeature
    });

    layer.bindTooltip(feature.properties.name, tooltipOptions)
  }

  layerOptions = {
    style: featureStyle,
    onEachFeature: onEachFeature,
    bubblingMouseEvents: false
  }

  layers.constituencies = L.geoJson(data.constituencies, layerOptions);
  layers.regions = L.geoJson(data.regions, layerOptions);
  layers.countries = L.geoJson(data.countries, layerOptions);

  PetitionMap.setCurrentCount(defaultMapCount());
  PetitionMap.setCurrentView(defaultMapView());

  controls.petitionInfo = L.petitionInfoControl(data.petition);
  controls.mapSwitcher = L.mapSwitcherControl(data.petition);
  controls.zoomAndShare = L.zoomAndShareControl(data.petition);
  controls.featureInfo = L.featureInfoControl(data.petition);

  map.addControl(controls.petitionInfo);
  map.addControl(controls.mapSwitcher);
  map.addControl(controls.zoomAndShare);
  map.addControl(controls.featureInfo);

  var onZoomStart = function(e) {
    zooming = true;
  }

  var onZoomEnd = function(e) {
    zooming = false;
  }

  var onMoveStart = function(e) {
    moving = true;

    if (currentLayer) {
      currentLayer.eachLayer(function(layer) {
        if (layer.isTooltipOpen()) {
          layer.closeTooltip();
        }
      });
    }
  }

  var onMoveEnd = function(e) {
    if (moving && currentLayer) {
      moving = false;
      ensureMapIsVisible(currentLayer);
    }
  }

  var onClick = function(e) {
    controls.mapSwitcher.hide();
    controls.petitionInfo.hide();

    if (currentFeature) {
      resetFeature(currentFeature)
      controls.featureInfo.resetFeatureInfo();
      currentFeature = null;
    }
  }

  var onDoubleClick = function(e) {
    if (currentLayer) {
      map.fitBounds(currentLayer.getBounds(), { padding: [25, 25], animate: false });
    }
  }

  map.on('zoomstart', onZoomStart);
  map.on('zoomend', onZoomEnd);
  map.on('movestart', onMoveStart);
  map.on('moveend', onMoveEnd);
  map.on('click', onClick);
  map.on('dblclick', onDoubleClick);
}).call(this);
