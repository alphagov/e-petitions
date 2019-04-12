$().ready(function() {
  $('select[data-autosubmit]')
    .change(function() {
      $(this).closest('form').submit();
    })

  $('input[data-autosubmit]')
    .change(function() {
      $(this).closest('form').submit();
    })
});
