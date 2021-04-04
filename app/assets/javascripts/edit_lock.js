(function ($) {
  'use strict';

  $.fn.editLock = function(id, user_id, path, moderated) {
    var $html = this;
    var $message = $html.find('.edit-lock-message');
    var $override = $html.find('#edit-lock-override');
    var $cancel = $html.find('#edit-lock-cancel');

    var ID = id;
    var USER_ID = user_id;
    var PATH = path;
    var INTERVAL = 10000;
    var LOCK_URL = PATH + '/' + ID + '/lock.json';
    var MODERATED = moderated;

    var EditLock = {
      processStatus: function(data) {
        if (data.locked) {
          if (data.locked_by.id == USER_ID) {
            $html.hide();
          } else {
            $message.text('This petition is currently being edited by ' + data.locked_by.name);
            $html.show();
          }
        } else {
          EditLock.obtainLock();
        }
      },

      checkStatus: function() {
        $.getJSON(LOCK_URL, EditLock.processStatus);
      },

      obtainLock: function() {
        $.ajax({
          url: LOCK_URL,
          method: 'POST',
          success: EditLock.processStatus
        });
      },

      releaseLock: function() {
        var params = new URLSearchParams();

        params.append('_method', 'DELETE');
        params.append($.rails.csrfParam(), $.rails.csrfToken());

        navigator.sendBeacon(LOCK_URL, params);
      },

      overrideClicked: function(e) {
        $.ajax({
          url: LOCK_URL,
          method: 'PATCH',
          success: EditLock.processStatus
        });
      },

      cancelClicked: function(e) {
        if (MODERATED) {
          window.location = PATH + '/' + ID;
        } else {
          window.history.back();
        }
      }
    };

    $override.on('click', EditLock.overrideClicked);
    $cancel.on('click', EditLock.cancelClicked);
    $(window).on('beforeunload', EditLock.releaseLock);

    EditLock.checkStatus();

    var timer = window.setInterval(EditLock.checkStatus, INTERVAL);
  }
})(jQuery);
