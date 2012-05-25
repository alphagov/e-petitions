require('/javascripts/vendor/jquery.js');
require('/javascripts/edit_response_controller.js');

describe('validation methods', function() {
  template('base.html');
  var controller;
  var form;

  beforeEach(function() {
    cachedDom = $('#test');
    dom = cachedDom.clone();
    cachedDom.replaceWith(dom);
  });

  afterEach(function() {
   dom.replaceWith(cachedDom);
  });

  beforeEach(function() {
    form = $("<form id='edit' action='#'><input type='checkbox' id='email'/></form>");
    $('#test').append(form);
    controller = new EditResponseController({
      form: 'form#edit',
      confirm_if_checked:'input#email',
      message: "are you sure?"
    });
    spyOn(controller, "confirm_box").andReturn(true);
  });

  // For some reason the following tests crash envjs so can't be added to the build. They work well within the browser though. Uncomment to change the controller under test.

  //it('allows submit to pass without incident if the checkbox is not checked', function() {
    //form.submit();
    //expect(controller.confirm_box).not.toHaveBeenCalled();
  //});

  //it('calls confirm if the checkbox is checked', function() {
    //form.find("input").attr('checked', 'checked');
    //form.submit();
    //expect(controller.confirm_box).toHaveBeenCalled();
  //});
});
