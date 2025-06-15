describe('Character counter', function() {
  var $textbox, $counter;

  function initCounter(value = '', maxLength = '50') {
    $textbox.value = value;
    $textbox.dataset.maxLength = maxLength;

    return new PETS.CharacterCounter($textbox);
  }

  function dispatchEvent(value, event) {
    $textbox.value = value;
    $textbox.dispatchEvent(new Event(event));
  }

  beforeEach(function () {
    $textbox = document.createElement('textarea');
    $textbox.id = 'fixture';
    $textbox.dataset.maxLength = '50';

    $counter = document.createElement('p');
    $counter.classList.add('character-count');
    $counter.textContent = '50 characters max';

    document.body.append($textbox);
    document.body.append($counter);
  });

  afterEach(function () {
    $textbox.remove();
    $counter.remove();
  });

  describe("When called", function () {
    it("Puts the max characters into the character counter", function () {
      initCounter();

      expect($counter.textContent).toEqual('You have 50 characters remaining');
    });

    it("Adds an id to the character counter based on the textbox id", function () {
      initCounter();

      expect($counter.id).toEqual('char-count-' + $textbox.id);
    });

    it("Adds an aria-controls attribute to the textbox linking it to the character counter", function () {
      initCounter();

      expect($textbox.getAttribute('aria-controls')).toEqual($counter.id);
    });

    it("Sets the count to what's in the data-max-length attribute on the textbox", function () {
      initCounter('', '40');

      expect($counter.textContent).toEqual('You have 40 characters remaining');
    });

    it("Gives the correct character count for a textbox that has content when the page loads", function () {
      initCounter('Words entered');

      expect($counter.textContent).toEqual('You have 37 characters remaining');
    });
  });

  describe("When content is added to the textbox", function () {
    beforeEach(function () {
      initCounter();
    });

    it("Has the correct character count if some characters are entered by keyup event", function () {
      dispatchEvent('Word entered', 'keyup');

      expect($counter.textContent).toEqual('You have 38 characters remaining');
    });

    it("Has the correct character count if some words are entered by paste event", function () {
      dispatchEvent('Words entered', 'paste');

      expect($counter.textContent).toEqual('You have 37 characters remaining');
    });

    it("Has the correct character count if some words are entered by change event", function () {
      dispatchEvent('Words entered', 'change');

      expect($counter.textContent).toEqual('You have 37 characters remaining');
    });

    it("Has the correct character count if a single character is entered", function () {
      dispatchEvent('w', 'keyup');

      expect($counter.textContent).toEqual('You have 49 characters remaining');
    });

    it("Has the correct character count if 49 characters are entered", function () {
      dispatchEvent('Vestibulum vel eleifend nunc. Aliquam fermentum n', 'keyup');

      expect($counter.textContent).toEqual('You have 1 character remaining');
    });

    it("Has the correct character count if 50 characters are entered", function () {
      dispatchEvent('Vestibulum vel eleifend nunc. Aliquam fermentum nu', 'keyup');

      expect($counter.textContent).toEqual('You have 0 characters remaining');
    });

    it("Has the correct character count if 51 characters are entered", function () {
      dispatchEvent('Vestibulum vel eleifend nunc. Aliquam fermentum num', 'keyup');

      expect($counter.textContent).toEqual('You have 1 character too many');
    });

    it("Has the correct character count if 52 characters are entered", function () {
      dispatchEvent('Vestibulum vel eleifend nunc. Aliquam fermentum numb', 'keyup');

      expect($counter.textContent).toEqual('You have 2 characters too many');
    });

    it("Has added the error classes if too many characters are entered", function () {
      dispatchEvent('Vestibulum vel eleifend nunc. Aliquam fermentum numb', 'keyup');

      expect($textbox.classList).toContain('form-control--error');
      expect($counter.classList).toContain('too-many-characters');
    });
  });
});
