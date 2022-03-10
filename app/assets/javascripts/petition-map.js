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
                        '#CC2685']

const setupMap = () =>  {
  let map = L.map('map', {
    zoom: 2,
    zoomControl: true,
    attributionControl: false,
    trackResize: true,
    minZoom: 6,
    maxZoom: 9,
    zoomAnimation: false
  })
  map.setView([52.4, -3.53976], 8);

  return map;
}

const fetchPetitionData = () => {
  L.PetitionMap.data = JSON.parse(document.getElementById('data').textContent);
}

const getColor = (feature) => {
  let signaturePercentage = signaturePercentageByConstituency(feature.id);

  return signaturePercentage > 30 ? L.PetitionMap.colors[7] :
    signaturePercentage > 20  ? L.PetitionMap.colors[6] :
    signaturePercentage > 5   ? L.PetitionMap.colors[5] :
    signaturePercentage > 4   ? L.PetitionMap.colors[4] :
    signaturePercentage > 3   ? L.PetitionMap.colors[3] :
    signaturePercentage > 2   ? L.PetitionMap.colors[2] :
    signaturePercentage > 1   ? L.PetitionMap.colors[1] :
                                L.PetitionMap.colors[0];
}

const signaturePercentageByConstituency = (code) => {
  let signatures = L.PetitionMap.data['data']['attributes']['signatures_by_constituency'] || [];
  let total_signatures = L.PetitionMap.data['data']['attributes']['signature_count'] || 0;

  let signatures_for_constituency = signatures.filter(function(e){return e.id == code});
  let percentage = signatures_for_constituency.length > 0 ?
                    signatures_for_constituency[0].signature_count*100 / total_signatures :
                    1;

  return percentage;
}

const fetchConstituencyData = async () => {
  let data = await getGeoData('../../welsh-constituencies.topojson');

  return data;
}

const getGeoData = async (url) => {
  let response = await fetch(url);
  let data = await response.json();

  return data;
}

const addLayerToMap = (map) => {
  return topoJson(null, {
    style: style,
    minZoom: 0,
    maxZoom: 0
  }).addTo(map);
}

const topoJson = (data, options) => {
  return new L.TopoJSON(data, options);
}

const style = (feature) => {
  return {
    color: "#999",
    opacity: 1,
    weight: 1,
    fillColor: getColor(feature),
    fillOpacity: 0.6
  };
}

const setup = async () => {
  let map = setupMap();
  fetchPetitionData();

  let constituenciesData = await fetchConstituencyData();
  let constituencyLayer = await addLayerToMap(map);

  constituencyLayer.addData(constituenciesData);
  L.control.layers({"constituencies": constituencyLayer}).addTo(map);
}

setup();
