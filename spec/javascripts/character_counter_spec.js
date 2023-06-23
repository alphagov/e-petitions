describe('Character counter', function() {
  var $ = window.jQuery,
      $textbox,
      $counter;

  beforeEach(function () {
    $textbox = $('<textarea data-max-length="50" id="fixture"></textarea>');
    $counter = $('<p class="character-count">50 characters max</p>');
    $(document.body).append($textbox);
    $(document.body).append($counter);
  });

  afterEach(function () {
    $textbox.remove();
    $counter.remove();
  });

  describe("When called", function () {
    it("Puts the max characters into the character counter", function () {
      GOVUK.PETS.characterCounter();
      expect($counter.text()).toEqual("50");
    });

    it("Adds an id to the character counter based on the textbox id", function () {
      GOVUK.PETS.characterCounter();
      expect($counter.attr('id')).toEqual('char-count-' + $textbox.attr('id'));
    });

    it("Adds an aria-controls attribute to the textbox linking it to the character counter", function () {
      GOVUK.PETS.characterCounter();
      expect($textbox.attr('aria-controls')).toEqual($counter.attr('id'));
    });

    it("Sets the count to what's in the data-max-length attribute on the textbox", function () {
      $textbox.attr('data-max-length', '40');
      GOVUK.PETS.characterCounter();
      expect($counter.text()).toEqual('40');
    });

    it("Gives the correct character count for a textbox that has content when the page loads", function () {
      $textbox.val('Words entered');
      GOVUK.PETS.characterCounter();
      expect($counter.text()).toEqual('37');
    });
  });

  describe("When content is added to the textbox", function () {
    it("Has the correct character count if some characters are entered by keyup event", function () {
      GOVUK.PETS.characterCounter();
      $textbox.val('Word entered');
      $textbox.trigger('keyup');
      expect($counter.text()).toEqual('38');
    });

    it("Has the correct character count if some words are entered by paste event", function () {
      GOVUK.PETS.characterCounter();
      $textbox.val('Words entered');
      $textbox.trigger('paste');
      expect($counter.text()).toEqual('37');
    });

    it("Has the correct character count if some words are entered by change event", function () {
      GOVUK.PETS.characterCounter();
      $textbox.val('Words entered');
      $textbox.trigger('change');
      expect($counter.text()).toEqual('37');
    });

    it("Has the correct character count if a single character is entered", function () {
      GOVUK.PETS.characterCounter();
      $textbox.val('w');
      $textbox.trigger('keyup');
      expect($counter.text()).toEqual('49');
    });

    it("Has the correct character count if 50 characters are entered", function () {
      GOVUK.PETS.characterCounter();
      $textbox.val("Vestibulum vel eleifend nunc. Aliquam fermentum nu");
      $textbox.trigger('keyup');
      expect($counter.text()).toEqual('0');
    });

    it("Has the correct character count if 51 characters are entered", function () {
      GOVUK.PETS.characterCounter();
      $textbox.val("Vestibulum vel eleifend nunc. Aliquam fermentum num");
      $textbox.trigger('keyup');
      expect($counter.text()).toEqual('-1');
    });

    it("Has the correct character count if 52 characters are entered", function () {
      GOVUK.PETS.characterCounter();
      $textbox.val("Vestibulum vel eleifend nunc. Aliquam fermentum numb");
      $textbox.trigger('keyup');
      expect($counter.text()).toEqual('-2');
    });
  });
});
