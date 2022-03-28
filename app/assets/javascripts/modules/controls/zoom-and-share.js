L.Control.ZoomAndShare = L.Control.extend({
  options: {
    position: 'bottomright'
  },

  initialize: function(petition, options) {
    L.Util.setOptions(this, options);
    this._petition = petition;
    this._ui = petition.ui.zoom_and_share;
  },

  onAdd: function(map) {
    var container = this._createContainer();
    var wrapper = this._createWrapper(container);

    this._createZoomButtons(wrapper);
    this._createLinks(wrapper);

    L.DomEvent.disableClickPropagation(container);

    return container;
  },

  _createContainer: function() {
    return L.DomUtil.create('section', 'map-control');
  },

  _createWrapper: function(container) {
    return L.DomUtil.create('div', 'map-control-wrapper zoom-and-share', container);
  },

  _createZoomButtons: function(wrapper) {
    var buttonsDiv = L.DomUtil.create('div', 'zoom-buttons', wrapper);

    var zoomOutBtn = L.DomUtil.create('button', 'button button--zoom-out', buttonsDiv);
    var zoomOutText = L.DomUtil.create('span', 'visuallyhidden', zoomOutBtn);
    zoomOutText.innerHTML = this._ui.zoom_out;

    var zoomInBtn = L.DomUtil.create('button', 'button button--zoom-in', buttonsDiv);
    var zoomInText = L.DomUtil.create('span', 'visuallyhidden', zoomInBtn);
    zoomInText.innerHTML = this._ui.zoom_in;

    zoomOutBtn.addEventListener('click', function (e){
      PetitionMap.map.zoomOut();
    });

    zoomInBtn.addEventListener('click', function (e){
      PetitionMap.map.zoomIn();
    });
  },

  _createLinks: function(wrapper) {
    var linksList = L.DomUtil.create('ul', '', wrapper);

    var shareListItem = L.DomUtil.create('li', '', linksList);
    var shareLink = L.DomUtil.create('a', '', shareListItem);
    shareLink.innerHTML = this._ui.share;
    shareLink.href = this._petition.share_map_url;

    var aboutListItem = L.DomUtil.create('li', '', linksList);
    var aboutLink = L.DomUtil.create('a', '', aboutListItem);
    aboutLink.innerHTML = this._ui.about;
    aboutLink.href = this._petition.about_map_url;
  }
});

L.zoomAndShareControl = function(petition, options) {
  return new L.Control.ZoomAndShare(petition, options);
};
