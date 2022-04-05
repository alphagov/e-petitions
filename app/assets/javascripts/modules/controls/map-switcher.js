L.Control.MapSwitcher = L.Control.extend({
  options: {
    position: 'topright'
  },

  initialize: function(petition, options) {
    L.Util.setOptions(this, options);
    this._petition = petition;
    this._ui = petition.ui.map_switcher;
  },

  onAdd: function(map) {
    var container = this._createContainer();
    var wrapper = this._createWrapper(container);

    this._createViewSwitcher(wrapper);
    this._createCountSwitcher(wrapper);

    L.DomEvent.disableClickPropagation(container);

    return container;
  },

  _createContainer: function() {
    return L.DomUtil.create('section', 'map-control');
  },

  _createWrapper: function(container) {
    return L.DomUtil.create('div', 'map-control-wrapper map-switcher', container);
  },

  _createViewSwitcher: function(wrapper) {
    var fieldset = L.DomUtil.create('fieldset', 'form-group view-switcher', wrapper);
    var legend = L.DomUtil.create('legend', '', fieldset);
    legend.innerHTML = this._ui.show_signatures_by.legend;

    var constituenciesDiv = L.DomUtil.create('div', 'multiple-choice', fieldset);
    var constituenciesRadio = L.DomUtil.create('input', '', constituenciesDiv);
    constituenciesRadio.type = 'radio';
    constituenciesRadio.name = 'current_view';
    constituenciesRadio.value = 'constituencies';
    constituenciesRadio.id = 'current_view_constituencies';

    if (PetitionMap.getCurrentView() == 'constituencies') {
      constituenciesRadio.checked = true;
    }

    var constituenciesLabel = L.DomUtil.create('label', '', constituenciesDiv);
    constituenciesLabel.htmlFor = 'current_view_constituencies';
    constituenciesLabel.innerHTML = this._ui.show_signatures_by.constituencies;

    var regionsDiv = L.DomUtil.create('div', 'multiple-choice', fieldset);
    var regionsRadio = L.DomUtil.create('input', '', regionsDiv);
    regionsRadio.type = 'radio';
    regionsRadio.name = 'current_view';
    regionsRadio.value = 'regions';
    regionsRadio.id = 'current_view_regions';

    if (PetitionMap.getCurrentView() == 'regions') {
      regionsRadio.checked = true;
    }

    var regionsLabel = L.DomUtil.create('label', '', regionsDiv);
    regionsLabel.htmlFor = 'current_view_regions';
    regionsLabel.innerHTML = this._ui.show_signatures_by.regions;

    var countriesDiv = L.DomUtil.create('div', 'multiple-choice', fieldset);
    var countriesRadio = L.DomUtil.create('input', '', countriesDiv);
    countriesRadio.type = 'radio';
    countriesRadio.name = 'current_view';
    countriesRadio.value = 'countries';
    countriesRadio.id = 'current_view_countries';

    if (PetitionMap.getCurrentView() == 'countries') {
      countriesRadio.checked = true;
    }

    var countriesLabel = L.DomUtil.create('label', '', countriesDiv);
    countriesLabel.htmlFor = 'current_view_countries';
    countriesLabel.innerHTML = this._ui.show_signatures_by.countries;

    fieldset.addEventListener('change', function (e){
      PetitionMap.setCurrentView(e.target.value);
    });
  },

  _createCountSwitcher: function(wrapper) {
    var fieldset = L.DomUtil.create('fieldset', 'form-group count-switcher', wrapper);
    var legend = L.DomUtil.create('legend', '', fieldset);
    legend.innerHTML = this._ui.count_signatures_by.legend;

    var signaturesDiv = L.DomUtil.create('div', 'multiple-choice', fieldset);
    var signaturesRadio = L.DomUtil.create('input', '', signaturesDiv);
    signaturesRadio.type = 'radio';
    signaturesRadio.name = 'current_count';
    signaturesRadio.value = 'signatures';
    signaturesRadio.id = 'current_count_signatures';

    if (PetitionMap.getCurrentCount() == 'signatures') {
      signaturesRadio.checked = true;
    }

    var signaturesLabel = L.DomUtil.create('label', '', signaturesDiv);
    signaturesLabel.htmlFor = 'current_count_signatures';
    signaturesLabel.innerHTML = this._ui.count_signatures_by.signatures;

    fieldset.addEventListener('change', function (e){
      PetitionMap.setCurrentCount(e.target.value);
    });

    var populationDiv = L.DomUtil.create('div', 'multiple-choice', fieldset);
    var populationRadio = L.DomUtil.create('input', '', populationDiv);
    populationRadio.type = 'radio';
    populationRadio.name = 'current_count';
    populationRadio.value = 'constituents';
    populationRadio.id = 'current_count_constituents';

    if (PetitionMap.getCurrentCount() == 'constituents') {
      populationRadio.checked = true;
    }

    var populationLabel = L.DomUtil.create('label', '', populationDiv);
    populationLabel.htmlFor = 'current_count_constituents';
    populationLabel.innerHTML = this._ui.count_signatures_by.population;
  }
});

L.mapSwitcherControl = function(petition, options) {
  return new L.Control.MapSwitcher(petition, options);
};
