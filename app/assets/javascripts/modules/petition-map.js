(function () {
  var PetitionMap = this.PetitionMap;
  var data = PetitionMap.data;
  var petition = data.petition;
  var constituencies = data.constituencies.features;
  var regions = data.regions.features;
  var countries = data.countries.features;
  var maxConstituencyCount = 0;
  var maxConstituencyPopulation = 0;
  var maxRegionCount = 0;
  var maxRegionPopulation = 0;
  var maxCountryCount = 0;
  var maxCountryPopulation = 0;

  mapOptions = {
    attributionControl: false,
    zoomControl: false,
    zoom: 5,
    minZoom: 5,
    maxZoom: 7
  }

  var map = PetitionMap.map = L.map('map', mapOptions);

  var initializeConstituencies = function (features) {
    features.forEach(function (feature) {
      var properties = feature.properties;

      properties.count = petition.signatures_by_constituency[properties.id];
      properties.totalCount = petition.signature_count;
      properties.percentageOfCount = properties.count / properties.totalCount;
      properties.percentageOfPopulation = properties.count / properties.population;
      properties.partyColour = properties.member.colour;

      maxConstituencyCount = Math.max(maxConstituencyCount, properties.percentageOfCount);
      maxConstituencyPopulation = Math.max(maxConstituencyPopulation, properties.percentageOfPopulation);
    });
  }

  var initializeRegions = function (features) {
    features.forEach(function (feature) {
      var properties = feature.properties;
      var pattern = new L.Pattern({
        patternUnits: 'userSpaceOnUse',
        patternContentUnits: null,
        x: 0, y: 0, width: 32, height: 32, angle: 135
      });

      properties.count = petition.signatures_by_region[properties.id];
      properties.totalCount = petition.signature_count;
      properties.percentageOfCount = properties.count / properties.totalCount;
      properties.percentageOfPopulation = properties.count / properties.population;

      maxRegionCount = Math.max(maxRegionCount, properties.percentageOfCount);
      maxRegionPopulation = Math.max(maxRegionPopulation, properties.percentageOfPopulation);

      properties.members.forEach(function (member, index) {
        var shape = new L.PatternPath({
          d: 'M 0 ' + (index * 8 + 4) + ' L 32 ' + (index * 8 + 4) + ' Z',
          stroke: true, color: member.colour, weight: 8
        });

        pattern.addShape(shape);
      });

      pattern.addTo(map);
      properties.partyPattern = pattern;
    });
  }

  var initializeCountries = function (features) {
    features.forEach(function (feature) {
      var properties = feature.properties;

      properties.count = petition.signatures_by_country[properties.id];
      properties.totalCount = petition.signature_count;
      properties.percentageOfCount = properties.count / properties.totalCount;
      properties.percentageOfPopulation = properties.count / properties.population;

      maxCountryCount = Math.max(maxCountryCount, properties.percentageOfCount);
      maxCountryPopulation = Math.max(maxCountryPopulation, properties.percentageOfPopulation);
    });
  }

  initializeConstituencies(constituencies);
  initializeRegions(regions);
  initializeCountries(countries);

  var maxPercentageCount = Math.max(maxConstituencyCount, maxRegionCount);
  var maxPercentagePopulation = Math.max(maxConstituencyPopulation, maxRegionPopulation);

  var colourScale = 0.5;
  var constituencyCountColourScale = (1 / maxConstituencyCount) * colourScale;
  var constituencyPopulationColourScale = (1 / maxConstituencyPopulation) * colourScale;
  var regionCountColourScale = (1 / maxRegionCount) * colourScale;
  var regionPopulationColourScale = (1 / maxRegionPopulation) * colourScale;
  var countryCountColourScale = (1 / maxCountryCount) * colourScale;
  var countryPopulationColourScale = (1 / maxCountryPopulation) * colourScale;

  var setCenterAndMaxBounds = function (layer) {
    var bounds = layer.getBounds();
    var center = bounds.getCenter();
    var maxBounds = [
      [center.lat - 2.5, center.lng - 3],
      [center.lat + 2.5, center.lng + 3]
    ];

    map.panTo(center);
    map.setMaxBounds(maxBounds);
  }

  var currentFeature = null;

  var featureStyle = function (feature) {
    var properties = feature.properties;

    return {
      fillColor: '#C9187E',
      fillOpacity: properties.percentageOfPopulation * constituencyPopulationColourScale,
      fillPattern: null,
      color: '#747474',
      opacity: 1.0,
      weight: 1
    }
  }

  var resetFeature = function (target) {
    target.setStyle(featureStyle(target.feature));
  }

  var highlightFeature = function (e) {
    var properties = this.feature.properties;

    if (properties.partyColour) {
      this.setStyle({
        color: '#3C3C3B',
        fillColor: properties.partyColour,
        fillOpacity: 1.0,
        weight: 2
      });
    } else if (properties.partyPattern) {
      this.setStyle({
        color: '#3C3C3B',
        fillColor: null,
        fillPattern: properties.partyPattern,
        fillOpacity: 1.0,
        weight: 2
      });
    } else {
      this.setStyle({
        color: '#3C3C3B',
        fillColor: '#C9187E',
        fillPattern: null,
        fillOpacity: properties.percentageOfPopulation * countryPopulationColourScale,
        weight: 2
      });
    }

    this.bringToFront();
  }

  var resetHighlight = function (e) {
    if (e.target != currentFeature) {
      resetFeature(e.target);
    }
  }

  var selectFeature = function (e) {
    if (currentFeature && currentFeature != e.target) {
      resetFeature(currentFeature);
    }

    currentFeature = e.target;
  }

  var currentTooltip = null;

  var tooltipOptions = {
    direction: 'top',
    sticky: true
  }

  var onEachFeature = function (feature, layer) {
    layer.on({
      mouseover: highlightFeature,
      mouseout: resetHighlight,
      click: selectFeature
    })

    layer.bindTooltip(feature.properties.name, tooltipOptions)
  }

  layerOptions = {
    style: featureStyle,
    onEachFeature: onEachFeature,
    bubblingMouseEvents: false
  }

  var currentLayer = null;
  var constituenciesLayer = L.geoJson(data.constituencies, layerOptions);
  var regionsLayer = L.geoJson(data.regions, layerOptions);
  var countriesLayer = L.geoJson(data.countries, layerOptions);

  currentLayer = constituenciesLayer;

  setCenterAndMaxBounds(currentLayer);

  map.addLayer(currentLayer);

  var petitionInfo = L.petitionInfoControl(data.petition);
  map.addControl(petitionInfo);

  map.on('move', function(e) {
    currentLayer.eachLayer(function(layer) {
      if (layer.isTooltipOpen()) {
        currentTooltip = layer.getTooltip();
        layer.closeTooltip();
      }
    })
  });

  map.on('moveend', function(e) {
    if (currentTooltip) {
      map.openTooltip(currentTooltip);
      currentTooltip = null;
    }
  });

  map.on('click', function(e) {
    if (currentFeature) {
      resetFeature(currentFeature)
      currentFeature = null;
    }
  });
}).call(this);
