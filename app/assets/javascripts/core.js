// Borrowed from govuk_template source/assets/javascripts/core.js
(function() {
  "use strict"

  // fix for printing bug in Windows Safari
  var windowsSafari = (window.navigator.userAgent.match(/(\(Windows[\s\w\.]+\))[\/\(\s\w\.\,\)]+(Version\/[\d\.]+)\s(Safari\/[\d\.]+)/) !== null),
      style;

  if (windowsSafari) {
    // set the New Transport font to Arial for printing
    style = document.createElement('style');
    style.setAttribute('type', 'text/css');
    style.setAttribute('media', 'print');
    style.innerHTML = '@font-face { font-family: nta !important; src: local("Arial") !important; }';
    document.getElementsByTagName('head')[0].appendChild(style);
  }

}).call(this);