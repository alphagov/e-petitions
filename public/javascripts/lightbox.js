var lightbox = new function Lightbox() {
  var overlay;
  var lightbox;
  var lightbox_content;
  
  function init() {
    var lightbox_links = $('.lightbox_link');
    if (lightbox_links.length == 0) return;
    
    overlay = $('<div class="overlay"></div>');
    overlay.hide();
    $(document.body).append(overlay);
    
    lightbox = $('<div class="lightbox">\
      <div class="content"></div>\
      <a class="close_btn link_button cancel_action">Close</a>\
      <p class="close_message">or press \'escape\' to close</p>\
      <a class="close_btn window_close_btn"></a>\
    </div>');
    lightbox.hide();
    $(document.body).append(lightbox);
    
    lightbox_content = $('.content', lightbox);
    
    $('.close_btn', lightbox).click(close);
    overlay.click(close);
    
    for (var i=0; i<lightbox_links.length; i++) {
      
      var link_content = $($(lightbox_links[i]).attr('href')).remove();

      lightbox_links[i].lightbox_content = link_content;
      $(lightbox_links[i]).click(click_link);
    }
    
    $(document).keyup(function(event) {
      if (event.keyCode == 27) {
        close();
      }
    });
  }
  this.init = init;
  
  function click_link(event) {
    open(this.lightbox_content);
  }
  
  function open(content) {
    lightbox_content.html(content);
    reposition_lightbox();
    overlay.fadeTo(300, 0.65);
    lightbox.fadeIn(300);
  }
  
  function close() {
    overlay.fadeOut(300);
    lightbox.fadeOut(300);
  }
  
  function reposition_lightbox() {
    var win = $(window);
    
    var window_height = win.height();
    var lightbox_height = lightbox.outerHeight();
    
    if (lightbox_height > window_height || ($.browser.msie && $.browser.version.substr(0,1)<7)) {
      lightbox.css({
        position: 'absolute',
        top: win.scrollTop() + 20 + 'px',
        marginTop: '0px'
      });
    }
    else {
      lightbox.css({
        position: 'fixed',
        top: '50%',
        marginTop: 0-lightbox.outerHeight()/2 + 'px'
      });
    }
  }  
};

$().ready(lightbox.init);
