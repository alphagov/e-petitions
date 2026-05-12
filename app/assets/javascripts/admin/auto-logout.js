export default function ($) {
  'use strict';

  $.fn.autoLogout = function() {
    var $html = this;
    var $continue = $html.find('#logout-warning-continue');
    var $logout = $html.find('#logout-warning-logout');
    var INTERVAL = 10000;
    var WARNING_TIME = 120;

    var AutoLogout = {
      continueClicked: function(e) {
        $.getJSON('/admin/continue.json', AutoLogout.processContinue);
      },

      logoutClicked: function(e) {
        window.location = '/admin/logout';
      },

      processContinue: function(data) {
        $html.hide();
      },

      processStatus: function(data) {
        if (data.time_remaining == 0) {
          window.location = '/admin/logout';
        } else if (data.time_remaining <= WARNING_TIME) {
          $html.show();
        } else {
          $html.hide();
        }
      },

      checkStatus: function() {
        $.getJSON('/admin/status.json', AutoLogout.processStatus);
      }
    };

    $continue.on('click', AutoLogout.continueClicked);
    $logout.on('click', AutoLogout.logoutClicked);

    window.setInterval(AutoLogout.checkStatus, INTERVAL);
  }
};
