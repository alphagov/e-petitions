$().ready(function() {
  $('select[data-autosubmit]')
    .change(function() {
      $(this).closest('form').submit();
    })
    .closest('form')
      .find('input[type="submit"]')
      .hide();
});
