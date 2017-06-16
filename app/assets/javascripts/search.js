$(document).ready(function() {
  var checked_value = $('input[type=radio][name=search_type]:checked');
  var search_type_radios = $('input[type=radio][name=search_type]');
  var tag_filters_pane = $('details.tag-filters');

  if (checked_value.val() == "petition") {
    tag_filters_pane.show();
  }
  else {
    tag_filters_pane.hide();
  };

  search_type_radios.change(function() {
    if ($(this).val() == "petition") {
      $('details.tag-filters').show();
    }
    else {
     $('details.tag-filters').hide();
    }
  });
});
