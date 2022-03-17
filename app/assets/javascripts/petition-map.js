L.TopoJSON = L.GeoJSON.extend({
  addData: function (data) {
    var geojson, key;
    if (data.type === "Topology") {
      for (key in data.objects) {
        if (data.objects.hasOwnProperty(key)) {
          geojson = topojson.feature(data, data.objects[key]);
          L.GeoJSON.prototype.addData.call(this, geojson);
        }
      }
      return this;
    }
    L.GeoJSON.prototype.addData.call(this, data);
    return this;
  }
});

L.PetitionMap = {};
L.PetitionMap.data = [];
L.PetitionMap.colors = ['#FBEEF5',
                        '#F1C2DD',
                        '#EFB9D8',
                        '#E799C6',
                        '#E07BB5',
                        '#D856A0',
                        '#D85AA2',
                        '#CB1F81',
                        '#fC2685']
L.PetitionMap.formattedData = {}

const setupMap = (layers) =>  {
  let map = L.map('map', {
    zoom: 2,
    attributionControl: false,
    minZoom: 6,
    maxZoom: 9,
    zoomAnimation: false,
    layers: layers
  })
  map.setView([52.4, -3.53976], 8);

  return map;
}

const fetchPetitionData = () => {
  L.PetitionMap.data = JSON.parse(document.getElementById('data').textContent);
}

const getColor = (feature) => {
  let element = L.PetitionMap.formattedData.data.find(element => element['id'] == feature.properties.id);
  let divisor = element ?
              (element['type'] == 'constituency' ? 100/L.PetitionMap.formattedData.maxConstituencyPercentage :
               element['type'] == 'region' ? 100/L.PetitionMap.formattedData.maxRegionalPercentage : 1) : 1

  const percentage = element ? element['percentage'] : 0

  return percentage > 0.5*divisor ? L.PetitionMap.colors[7] :
    percentage > 0.4*divisor ? L.PetitionMap.colors[6] :
    percentage > 0.3*divisor ? L.PetitionMap.colors[5] :
    percentage > 0.2*divisor ? L.PetitionMap.colors[4] :
    percentage > 0.1*divisor ? L.PetitionMap.colors[3] :
    percentage > 0.05*divisor ? L.PetitionMap.colors[2] :
    percentage > 0.01*divisor ? L.PetitionMap.colors[1] :
                                L.PetitionMap.colors[0];
}

const calculateConstituencyData = () => {
  let signatures = L.PetitionMap.data['data']['attributes']['signatures_by_constituency'] || [];

  constituencySignatureData  = signatures.map(signaturesForConstituency => (
    signaturesForConstituency['percentage'] = signaturesForConstituency.signature_count*100/L.PetitionMap.totalSignatures,
    signaturesForConstituency['type'] = 'constituency',
    signaturesForConstituency)
  );
  return constituencySignatureData;
}

const calculateRegionalData = () => {
  let signatures = L.PetitionMap.data['data']['attributes']['signatures_by_region'] || [];

  regionSignatureData = signatures.map(signaturesForRegion => (
    signaturesForRegion['percentage'] = signaturesForRegion.signature_count*100/L.PetitionMap.totalSignatures,
    signaturesForRegion['type'] = 'region',
    signaturesForRegion)
  );
  return regionSignatureData;
}

const maxPercentage = (data) => {
  let pos = data.length > 0 ? Object.keys(data).reduce((a, b) => data[a].percentage > data[b].percentage ? a : b) : null;
  return pos ? data[pos].percentage : 0;
}


const signaturePercentageByRegion = (code) => {
  let signatures = L.PetitionMap.data['data']['attributes']['signatures_by_region'] || [];
  let total_signatures = L.PetitionMap.data['data']['attributes']['signature_count'] || 0;

  let signatures_for_region = signatures.filter(function(e){return e.id == code});
  let percentage = signatures_for_region.length > 0 ?
                    signatures_for_region[0].signature_count*100 / total_signatures :
                    null;

  return percentage;
}

const fetchConstituencyData = async () => {
  let data = await getGeoData('../../welsh-constituencies.geojson');

  return data;
}

const fetchRegionalData = async () => {
  let data = await getGeoData('../../welsh-regions.geojson');

  return data;
}

const getGeoData = async (url) => {
  let response = await fetch(url);
  let data = await response.json();

  return data;
}

const createLayer = () => {
  return topoJson(null, {
    style: style,
    onEachFeature: onEachFeature,
    minZoom: 0,
    maxZoom: 0
  })
}

const topoJson = (data, options) => {
  return new L.TopoJSON(data, options);
}

const style = (feature) => {
  return {
    color: "#999",
    weight: 1,
    fillColor: getColor(feature),
    fillOpacity: 1
  };
}

const onEachFeature = (feature, layer) => {
  layer.on({
    mouseover: highlightFeature
  });
}

const highlightFeature = (e) => {
  var layer = e.target;
  let feature = layer.feature;

  const selectedFeature = L.PetitionMap.formattedData.data.find(element => element['id'] == feature.id);

  if (!L.Browser.ie && !L.Browser.opera && !L.Browser.edge) {
    layer.bringToFront();
  }
}

const resetContainerFocus = (map) => {
  map.getContainer().focus = () => {}
}

const setup = async () => {
  fetchPetitionData();

  L.PetitionMap.totalSignatures = L.PetitionMap.data['data']['attributes']['signature_count'];

  let constituenciesData = await fetchConstituencyData();
  let formattedConstituencyData = calculateConstituencyData();
  let maxConstituencyPercentage = maxPercentage(formattedConstituencyData);

  let regionalData = await fetchRegionalData();
  let formattedRegionalData = calculateRegionalData();
  let maxRegionalPercentage = maxPercentage(formattedRegionalData);

  L.PetitionMap.formattedData = {
    data: [...formattedConstituencyData, ...formattedRegionalData],
    maxConstituencyPercentage: maxConstituencyPercentage,
    maxRegionalPercentage: maxRegionalPercentage
  };

  let constituencyLayer = await createLayer();
  constituencyLayer.addData(constituenciesData);

  let regionLayer = await createLayer();
  regionLayer.addData(regionalData);

  let layerControl = L.control.layers(
    {"constituencies": constituencyLayer, 'regions': regionLayer},
    {},
    { collapsed: false }
  )

  let map = setupMap([constituencyLayer]);
  map.addControl(layerControl);

  resetContainerFocus(map); //resolves issue of map jumping when zooming in/out

}

setup();
