EditResponseController = function EditResponseController(options) {
  var self = this;
  $(options.form).submit(function() {
    if ($(options.confirm_if_checked).attr('checked') == 'checked') {
      return self.confirm_box(options.message);
    }
  });

  this.confirm_box = function(message) {
    return window.confirm(message);
  };
};
