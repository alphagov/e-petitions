L.Control.FeatureInfo = L.Control.extend({
  options: {
    position: 'bottomleft'
  },

  initialize: function(petition, options) {
    L.Util.setOptions(this, options);
    this._petition = petition;
    this._ui = petition.ui.feature_info;
  },

  onAdd: function(map) {
    var container = this._createContainer();
    this._wrapper = this._createWrapper(container);

    this._hideControl();

    L.DomEvent.disableClickPropagation(container);

    return container;
  },

  _createContainer: function() {
    return L.DomUtil.create('section', 'map-control');
  },

  _createWrapper: function(container) {
    return L.DomUtil.create('div', 'map-control-wrapper feature-info', container);
  },

  _hideControl: function() {
    this._wrapper.style.display = 'none';
  },

  _showControl: function() {
    this._wrapper.style.display = 'block';
  },

  _translateSignatures: function(count) {
    switch (count) {
      case 0:
        return this._ui.signatures.zero;
      case 1:
        return this._ui.signatures.one;
      case 2:
        return this._ui.signatures.two;
      default:
        return this._ui.signatures.other;
    }
  },

  _addSignatureCount: function(feature, paragraph) {
    var properties = feature.properties;
    var wrapper = L.DomUtil.create('small', '', paragraph);
    var formattedCount = properties.signatures.toLocaleString();
    var signaturesLabel = this._translateSignatures(properties.signatures);

    wrapper.innerHTML = formattedCount + ' ' + signaturesLabel;
  },

  _addPercentageOfConstituents: function(feature, paragraph) {
    var properties = feature.properties;
    var percentage = properties.percentageOfPopulation;
    var wrapper = L.DomUtil.create('small', '', paragraph);
    var formattedPercentage = (percentage * 100).toLocaleString({ minimumFractionDigits: 3 }) + '%';
    var formattedPopulation = properties.population.toLocaleString() + ' ' + this._ui.constituents;

    wrapper.innerHTML = formattedPercentage + ' ' + this._ui.of + ' ' + formattedPopulation;
  },

  _addPercentageOfSignatures: function(feature, paragraph) {
    var properties = feature.properties;
    var percentage = properties.percentageOfSignatures;
    var wrapper = L.DomUtil.create('small', '', paragraph);
    var formattedPercentage = (percentage * 100).toLocaleString({ minimumFractionDigits: 3 }) + '%';
    var signaturesLabel = this._translateSignatures(properties.totalSignatures);
    var formattedSignatures = properties.totalSignatures.toLocaleString() + ' ' + signaturesLabel;

    wrapper.innerHTML = formattedPercentage + ' ' + this._ui.of + ' ' + formattedSignatures;
  },

  setFeatureInfo: function(feature) {
    var properties = feature.properties;
    this._wrapper.innerHTML = '';

    var heading = L.DomUtil.create('h2', '', this._wrapper);
    heading.innerHTML = properties.name;

    if (properties.member) {
      var memberName = L.DomUtil.create('p', '', this._wrapper);
      memberName.innerHTML = properties.member.name;

      var partyName = L.DomUtil.create('small', '', memberName);
      partyName.innerHTML = properties.member.party;
    } else if (properties.members) {
      var wrapper = this._wrapper;

      properties.members.forEach(function (member) {
        var memberName = L.DomUtil.create('p', '', wrapper);
        memberName.innerHTML = member.name;

        var partyName = L.DomUtil.create('small', '', memberName);
        partyName.innerHTML = member.party;
      });
    }

    var statsParagraph = L.DomUtil.create('p', '', this._wrapper);
    this._addSignatureCount(feature, statsParagraph);

    if (PetitionMap.getCurrentCount() == 'constituents') {
      this._addPercentageOfConstituents(feature, statsParagraph);
    } else {
      this._addPercentageOfSignatures(feature, statsParagraph);
    }

    this._showControl();
  },

  resetFeatureInfo: function() {
    this._hideControl();
    this._wrapper.innerHTML = '';
  }
});

L.featureInfoControl = function(petition, options) {
  return new L.Control.FeatureInfo(petition, options);
};
