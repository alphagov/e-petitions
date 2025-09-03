export default function($) {
  if (typeof $ === 'undefined') { return; }

  $(document).on({
    ajaxStart: function() { $('body').addClass('ajax-active'); },
    ajaxStop: function() { $('body').removeClass('ajax-active'); }
  });

  function debounce(f, delay) {
    var debounceTimer = 0;
    return function() {
      var context = this;
      var args = arguments;

      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(function() {
        f.apply(context, args);
      }, delay);
    }
  }

  function setHeaderOrLabelState(headerOrLabel, state) {
    headerOrLabel.removeClass(['saving', 'saved', 'error']);
    if(state) headerOrLabel.addClass(state);

    headerOrLabel.next('.flash-alert').remove();
    if("error" == state) {
      headerOrLabel.after('<p class="flash-alert"></p>').next().text('There was an error saving. Please manually submit the form.')
    }
  }

  var debouncedSubmitForm = debounce(function() {
    var form = $(this).closest('form');
    var headerOrLabel = form.prevAll('h2');
    if(!headerOrLabel.length) {
      headerOrLabel = $("label[for='" + $(this).attr('id') + "']");
    }
    setHeaderOrLabelState(headerOrLabel, 'saving');

    $.ajax({
      type: form.attr('method'),
      url: form.attr('action'),
      headers: { 'Accept': 'application/json' },
      data: form.serialize(),
      success: function(response) {
        if(response && response.updated) {
          setHeaderOrLabelState(headerOrLabel, 'saved');
        } else {
          setHeaderOrLabelState(headerOrLabel, 'error');
        }
      },
      error: function(jqXHR, textStatus, errorThrown) {
        setHeaderOrLabelState(headerOrLabel, 'error');
      }
    });
  }, 500); //500ms delay

  $('input[type=checkbox][data-autosave]').change(function() {
    debouncedSubmitForm.call(this);
  });

  $('textarea[data-autosave]').on('input', function() {
    debouncedSubmitForm.call(this);
  });
};
