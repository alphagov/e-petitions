window.E_PETS = {
  init: function() {
    E_PETS.Accessibility.init();
    E_PETS.UI.init();
  },
  
  UTILS: {
    group_collection_by: function(collection, attribute_name) {
      var groups = {};
      for (var i=0; i<collection.length; i++) {
        groups[collection[i][attribute_name]] = groups[collection[i][attribute_name]] || [];
        groups[collection[i][attribute_name]].push(collection[i]);
      }
      return groups;
    },
    simple_format: function(text) {
      var simpleFormatRE1 = /\r\n?/g;
      var simpleFormatRE2 = /\n\n+/g;
      var simpleFormatRE3 = /([^\n]\n)(?=[^\n])/g;
      var fstr = text;
      fstr = fstr.replace(simpleFormatRE1, "\n") // \r\n and \r -> \n
      fstr = fstr.replace(simpleFormatRE2, "</p>\n\n<p>") // 2+ newline  -> paragraph
      fstr = fstr.replace(simpleFormatRE3, "$1<br/>") // 1 newline   -> br
      fstr = "<p>" + fstr + "</p>";
      return fstr;
    }
  },

  UI: {
    init: function init() {
      var _ExpandableBlock = E_PETS.UI.ExpandableBlock;
      _ExpandableBlock.instances = [];
      var expandable_links = $('.expandable_link');
      for (var i=0; i<expandable_links.length; i++) {
        _ExpandableBlock.instances.push(new _ExpandableBlock(expandable_links[i]));
      }
    },
    
    ExpandableBlock: function ExpandableBlock(link) {
      link = $(link);
      var content_block = $(link.attr('href'));
      content_block.hide();
      var is_open = false;
      
      link.click(toggle);
      
      function open() {
        content_block.slideDown(300);
        is_open = true;
      }
      this.open = open;
      
      function close() {
        content_block.slideUp(300);        
        is_open = false;
      }
      this.close = close;
      
      function toggle() {
        if(is_open) close();
        else open();
        return false;
      }
      this.toggle = toggle;
    }
  }
};

$().ready(E_PETS.init);
