L.Control.PetitionInfo = L.Control.extend({
  options: {
    position: 'topleft'
  },

  initialize: function(petition, options) {
    L.Util.setOptions(this, options);
    this._petition = petition;
    this._ui = petition.ui.petition_info;
  },

  onAdd: function(map) {
    var container = this._createContainer();
    var wrapper = this._createWrapper(container);

    this._createBackButton(wrapper);
    this._createPetitionAction(wrapper);
    this._createSignatureCount(wrapper);
    this._createSignPetitionButton(wrapper);

    L.DomEvent.disableClickPropagation(container);

    return container;
  },

  _createContainer: function() {
    return L.DomUtil.create('section', 'map-control');
  },

  _createWrapper: function(container) {
    return L.DomUtil.create('div', 'map-control-wrapper petition-info', container);
  },

  _createBackButton: function(wrapper) {
    var link = L.DomUtil.create('a', 'petition-info--back-link', wrapper);
    link.innerHTML = this._ui.back;
    link.href = this._petition.petition_url;

    return link;
  },

  _createPetitionAction: function(wrapper) {
    var secondaryHeading = L.DomUtil.create('span', 'label');
    secondaryHeading.innerHTML = this._ui.petition + ' ';

    var heading = L.DomUtil.create('h1', 'petition-info--action', wrapper);
    heading.appendChild(secondaryHeading);

    var actionText = document.createTextNode(this._petition.action);
    heading.appendChild(actionText);

    return heading;
  },

  _createSignatureCount: function(wrapper) {
    var signatureCount = this._petition.signature_count.toLocaleString();
    var paragraph = L.DomUtil.create('p', 'petition-info--signature-count', wrapper);
    var countSpan = L.DomUtil.create('span', 'count', paragraph);
    var textSpan = L.DomUtil.create('span', 'text', paragraph);

    countSpan.innerHTML = signatureCount;
    textSpan.innerHTML = ' ' + this._ui.signatures;

    return paragraph;
  },

  _createSignPetitionButton: function(wrapper) {
    if (this._petition.sign_petition_url) {
      var link = L.DomUtil.create('a', 'petition-info--sign-button', wrapper);
      link.innerHTML = this._ui.sign_this_petition;
      link.href = this._petition.sign_petition_url;

      return link;
    }
  }
});

L.petitionInfoControl = function(petition, options) {
  return new L.Control.PetitionInfo(petition, options);
};
