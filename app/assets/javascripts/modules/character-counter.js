// Appropriated from
// https://github.com/alphagov/digitalmarketplace-frontend-toolkit/blob/master/toolkit/javascripts/word-counter.js

(function ($) {

  'use strict';

  var characterCounter,
      COUNTER_CLASS = 'character-count';

  if (typeof $ === 'undefined') { return; }

  var attach = function() {
      var $textareas = $('textarea[data-max-length]');

      if (!$textareas.length) { return; }

      $textareas.each(function () {
        var $textarea = $(this),
            ariaId = 'char-count-' + $textarea.attr('id');

        $textarea
          .next('.' + COUNTER_CLASS)
            .text($textarea.data('max-length'))
            .attr({
                'role': 'status',
                'aria-atomic': 'true',
                'id': ariaId
            });

        $textarea
          .attr('aria-controls', ariaId)
          .on('change keyup paste', updateCount);

        updateCount.call(this);

      });

    },
    statusMessage = function($characters) {
      if (Math.abs($characters) == 1) {
        return $characters + ' character remaining';
      } else {
        return $characters + ' characters remaining';
      }
    },
    updateCount = function() {
      var $textarea = $(this),
          contents = $textarea.val(),
          charCount = contents.length,
          maxCharCount = $textarea.data('max-length'),
          charsRemaining = maxCharCount - charCount;

      $textarea
        .next('.' + COUNTER_CLASS)
        .html(statusMessage(charsRemaining))
        .toggleClass('too-many-characters', charsRemaining < 0);
    };

  characterCounter = function () {
    attach();
  };

  this.GOVUK = this.GOVUK || {};
  this.GOVUK.PETS = this.GOVUK.PETS || {};
  GOVUK.PETS.characterCounter = characterCounter;
}).call(this, window.jQuery);
