require('/javascripts/vendor/jquery.js');
require('/javascripts/application.js');
require('/javascripts/accessibility.js');
require('/javascripts/form_controller.js');

describe('validation methods', function() {
  beforeEach(function() {
    this.addMatchers({
      toBeValidPostcode: function() {
        return E_PETS.FormController.validation_formats.postcode.exec(this.actual) != null;
      },
      toBeValidEmailAddress: function() {
        return E_PETS.FormController.validation_formats.email.exec(this.actual) != null;
      }
    });
  });

  describe('postcode validation', function() {
    it ('matches valid postcodes', function() {
      expect('NW1 8SU').toBeValidPostcode();
    });
    it ('matches valid lowercase postcodes', function() {
      expect('nw1 8su').toBeValidPostcode();
    });
    it('matches valid British Forces Post Office postcodes', function(){
      expect('BFPO 1').toBeValidPostcode();
      expect('BFPO 1234').toBeValidPostcode();
      expect('BFPO c/o 1').toBeValidPostcode();
      expect('BFPO c/o 1234').toBeValidPostcode();
    });

    it ('rejects postcodes with extra characters', function() {
      expect('NW1 8SU0').not.toBeValidPostcode();
    });
    it ('rejects postcodes with invalid trailing characters', function() {
      expect('NW1 8SC').not.toBeValidPostcode();
    });
    it ('accepts postcodes without a space', function() {
      expect('NW18SU').toBeValidPostcode();
    });
  });

  describe('email validation', function() {
    it ('matches a regular email address', function() {
      expect('foo@bar.com').toBeValidEmailAddress();
    });
    it ('rejects two @s', function() {
      expect('foo@bar@baz.com').not.toBeValidEmailAddress();
    });
    it ('allows apostrophe', function() {
      expect("o'nell@bar.com").toBeValidEmailAddress();
    });
    it ('allows plus', function() {
      expect("o+nell@bar.com").toBeValidEmailAddress();
    });
  });
});

describe("conditional validation", function() {
  template('base.html');

  beforeEach(function() {
    cachedDom = $('#test');
    dom = cachedDom.clone();
    cachedDom.replaceWith(dom);
  });

  afterEach(function() {
   dom.replaceWith(cachedDom);
  });

  var controller;
  beforeEach(function() {
    form = $("<form action='#'><fieldset><div class='row'><input name='title'/><input name='other'/><input id ='submit' type='submit'></div></fieldset></form>");
    $('#test').append(form);

    new E_PETS.Accessibility.init();
    spyOn(window, "push_feedback");

    controller = new E_PETS.FormController($('#test form'), 0);
  });

  describe('the presence of a field', function() {
    beforeEach(function() {
      controller.validates('title', {
        method: E_PETS.FormController.validation_methods.validate_presence,
        message: 'title problem'
      });
    });

    it ('does not return an error if it is valid', function() {
      $("form input[name=title]").val('foo');
      expect(controller.validate_all()).toBeTruthy();
    });

    it ('prints an error if the field is not valid', function() {
      $("#submit").click();
      expect($(".row .errors").text()).toEqual("title problem");
    });
  });

  describe('conditional presence of a field', function() {
    beforeEach(function() {
      controller.validates('title', {
        method: E_PETS.FormController.validation_methods.validate_presence,
        message: 'title problem',
        when: function() {
          return $(this).siblings('input[name=other]').val() != 'foo';
        }
      });
    });

    it ('runs the validation if the condition is true', function() {
      $("#submit").click();
      expect($(".row .errors").text()).toEqual("title problem");
    });

    it ('does not run the validation if the condition is not true', function() {
      $("form input[name=other]").val('foo');
      expect(controller.validate_all()).toBeTruthy();
    });
  });

  describe('confirmation of a field', function() {
    beforeEach(function() {
      controller.validates('title', {
        method : [E_PETS.FormController.validation_methods.validate_confirmation, 'other'],
        message: "title doesn't match other"
      });
      $("form input[name=other]").val('foo');
    });      
      
    it('returns validation error', function() {
      $("form input[name=title]").val('bar');
      $("#submit").click();
      expect($(".row .errors").text()).toEqual("title doesn't match other");
    });
    
    it('returns no validation error', function() {
      $("form input[name=title]").val('foo');
      $("#submit").click();
      expect(controller.validate_all()).toBeTruthy();
    });
    
    it('returns no validation error when delta is only white space', function() {
      $("form input[name=title]").val('  foo  ');
      $("#submit").click();
      expect(controller.validate_all()).toBeTruthy();
    });
  });
});
