// Easter egg ;)

$("header .proposition .graphic-portcullis-white").click(function(){
  var $thing = $(this);
  var count = ($thing.data("click_count") || 0) + 1;
  $thing.data("click_count", count);
  if ( count == 7 )
    $("header .strapline").html("Down with that sort of thing!");
  else if ( count > 7 ) {
    $("header .strapline").append( "!" );
  }
  return false;
});
