class PetitionMap {
  constructor () {

    this.extendTopoJson();
    this.setupMap();

    this.fetchPetitionData();

    this.constituency_json = this.addConstituenciesToMap();
    this.constituency_json.addTo(this.map);
    this.addConstituencyData();
  }

  async fetchPetitionData() {
    this.petition_data = JSON.parse(document.getElementById('data').textContent);
  }

  async getGeoData(url) {
    let response = await fetch(url);
    let data = await response.json();
    return data;
  }

  async fetchConstituencyData() {
    let constituency_data = await this.getGeoData('../../welsh-constituencies.topojson');

    return constituency_data;
  }

  async fetchRegionalData() {
    let regional_data = await this.getGeoData('../../welsh-regions.topojson')

    return regional_data;
  }

  addConstituenciesToMap() {
    return this.topoJson(null, {
      style: this.style,
      //onEachFeature: onEachFeature,
      minZoom: 0,
      maxZoom: 0
    })
  }

  async addConstituencyData() {
    let data = await this.fetchConstituencyData();

    await this.constituency_json.addData(data);
  }

  setupMap() {
    this.map = L.map('map', {
      zoom: 2,
      zoomControl: false,
      attributionControl: false,
      trackResize: true,
      minZoom: 6,
      maxZoom: 9,
      zoomAnimation: false
    })

    this.map.setView([52.4, -3.53976], 8);
    return 'no';
  }

  topoJson(data, options) {
    return new L.TopoJSON(data, options);
  };

  extendTopoJson() {
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
  }

  style(feature) {
    return {
      color: "#777",
      fillColor: '#111100',
      opacity: 1,
      weight: 1,
      fillColor: '#999999',
      fillOpacity: 0.6
    };
  }

  getColor(feature) {
    var signaturePercentage = signaturePercentageByConstituency(feature.id);

    var colors = ['#f189c5', '#eb5bae', '#e62e98', '##c9187e', '#9b1361', '#6e0d45', '#400828']
    return colors[0];
  }

  signaturePercentageByConstituency(code) {
    signatures = this.petition_data['signatures_by_constituency'];
    signatures_for_constituency = signatures.filter(function(e){return e.id == code});
    all_signatures = Object.values(signatures).reduce((a, b) => a + b.signature_count);
    console.log(all_signatures);

    return signatures_for_constituency.length > 0 ? signatures_for_constituency[0].signature_count : 0;
  }
}

const petitionMap = new PetitionMap();
