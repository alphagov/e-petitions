// From govuk_elements/public/javascripts/vendor/details.polyfill.js
// <details> polyfill
// http://caniuse.com/#feat=details

// FF Support for HTML5's <details> and <summary>
// https://bugzilla.mozilla.org/show_bug.cgi?id=591737

// http://www.sitepoint.com/fixing-the-details-element/

(function () {

  // We'll need the getBoundingClientRect function for the
  // hash scripting, so if it's not supported just return,
  // then the elements will remain in their default open state
  if (typeof(document.createElement('span').getBoundingClientRect) == 'undefined') { return; }


  // Add event construct for modern browsers or IE
  // which fires the callback with a pre-converted target reference
  function addEvent(node, type, callback) {
    if (node.addEventListener) {
      node.addEventListener(type, function (e) {
        callback(e, e.target);

      }, false);
    } else if (node.attachEvent) {
      node.attachEvent('on' + type, function (e) {
        callback(e, e.srcElement);
      });
    }
  }

  // Handle cross-modal click events
  function addClickEvent(node, callback) {
    // Prevent space(32) from scrolling the page
    addEvent(node, 'keypress', function (e, target) {
      if (target.nodeName === "SUMMARY") {
        if (e.keyCode === 32) {
          if (e.preventDefault) {
            e.preventDefault();
          } else {
            e.returnValue = false;
          }
        }
      }
    });
    // When the key comes up - check if it is enter(13) or space(32)
    addEvent(node, 'keyup', function (e, target) {
      if (e.keyCode === 13 || e.keyCode === 32) { callback(e, target); }
    });
    addEvent(node, 'mouseup', function (e, target) {
      callback(e, target);
    });
  }

  // Get the nearest ancestor element of a node that matches a given tag name
  function getAncestor(node, match) {
    do {
      if (!node || node.nodeName.toLowerCase() === match) {
        break;
      }
    } while (node = node.parentNode);

    return node;
  }

  // Create a started flag so we can prevent the initialisation
  // function firing from both DOMContentLoaded and window.onload
  var started = false;

  // Initialisation function
  function addDetailsPolyfill(list) {

    // If this has already happened, just return
    // else set the flag so it doesn't happen again
    if (started) {
      return;
    }
    started = true;

    // Get the collection of details elements, but if that's empty
    // then we don't need to bother with the rest of the scripting
    if ((list = document.getElementsByTagName('details')).length === 0) {
      return;
    }

    // else iterate through them to apply their initial state
    var n = list.length, i = 0;
    for (n; i < n; i++) {
      var details = list[i];

      // Detect native implementations
      details.__native = typeof(details.open) == 'boolean';

      // Save shortcuts to the inner summary and content elements
      details.__summary = details.getElementsByTagName('summary').item(0);
      details.__content = details.getElementsByTagName('div').item(0);

      // If the content doesn't have an ID, assign it one now
      // which we'll need for the summary's aria-controls assignment
      if (!details.__content.id) {
        details.__content.id = 'details-content-' + i;
      }

      // Add ARIA role="group" to details
      details.setAttribute('role', 'group');

      // Add role=button to summary
      details.__summary.setAttribute('role', 'button');

      // Add aria-controls
      details.__summary.setAttribute('aria-controls', details.__content.id);

      // Set tabindex so the summary is keyboard accessible
      // details.__summary.setAttribute('tabindex', 0);
      // http://www.saliences.com/browserBugs/tabIndex.html
      details.__summary.tabIndex = 0;

      // Detect initial open/closed state

      // Native support - has 'open' attribute
      if (details.open === true) {
        details.__summary.setAttribute('aria-expanded', 'true');
        details.__content.setAttribute('aria-hidden', 'false');
        details.__content.style.display = 'block';
      }

      // Native support - doesn't have 'open' attribute
      if (details.open === false) {
        details.__summary.setAttribute('aria-expanded', 'false');
        details.__content.setAttribute('aria-hidden', 'true');
        details.__content.style.display = 'none';
      }

      // If this is not a native implementation
      if (!details.__native) {

        // Add an arrow
        var twisty = document.createElement('i');

        // Check for the 'open' attribute
        // If open exists, but isn't supported it won't have a value
        if (details.getAttribute('open') === "") {
          details.__summary.setAttribute('aria-expanded', 'true');
          details.__content.setAttribute('aria-hidden', 'false');
        }

        // If open doesn't exist - it will be null or undefined
        if (details.getAttribute('open') == null || details.getAttribute('open') == "undefined" ) {
          details.__summary.setAttribute('aria-expanded', 'false');
          details.__content.setAttribute('aria-hidden', 'true');
          details.__content.style.display = 'none';
        }

      }

      // Create a circular reference from the summary back to its
      // parent details element, for convenience in the click handler
      details.__summary.__details = details;

      // If this is not a native implementation, create an arrow
      // inside the summary
      if (!details.__native) {

        var twisty = document.createElement('i');

        if (details.getAttribute('open') === "") {
          twisty.className = 'arrow arrow-open';
          twisty.appendChild(document.createTextNode('\u25bc'));
        } else {
          twisty.className = 'arrow arrow-closed';
          twisty.appendChild(document.createTextNode('\u25ba'));
        }

        details.__summary.__twisty = details.__summary.insertBefore(twisty, details.__summary.firstChild);
        details.__summary.__twisty.setAttribute('aria-hidden', 'true');

      }
    }

    // Define a statechange function that updates aria-expanded and style.display
    // to either expand or collapse the region (ie. invert the current state)
    // or to set a specific state if the expanded flag is strictly true or false
    // then update the twisty if we have one with a correpsonding glyph
    function statechange(summary, expanded) {
      var hidden = summary.__details.__content.getAttribute('aria-hidden') == 'true';

      if (typeof(expanded) == 'undefined') {
        expanded = summary.__details.__content.getAttribute('aria-expanded') == 'true';
      } else if (expanded === false) {
        summary.__details.setAttribute('open', 'open');
      } else if (expanded === true) {
        summary.__details.removeAttribute('open');
      }

      summary.__details.__content.setAttribute('aria-expanded', (expanded ? 'false' : 'true'));
      summary.__details.__content.setAttribute('aria-hidden', (hidden ? 'false' : 'true'));
      summary.__details.__content.style.display = (expanded ? 'none' : 'block');

      if (summary.__twisty) {
        summary.__twisty.firstChild.nodeValue = (expanded ? '\u25ba' : '\u25bc');
        summary.__twisty.setAttribute('class', (expanded ? 'arrow arrow-closed' : 'arrow arrow-open'));
      }

      return true;
    }

    // Bind a click event to handle summary elements
    // if the target is not inside a summary element, just return true
    // to pass-through the event, else call and return the statechange function
    // which also returns true to pass-through the remaining event
    addClickEvent(document, function (e, summary) {
      if (!(summary = getAncestor(summary, 'summary'))) {
        return true;
      }
      return statechange(summary);
    });

    // Define an autostate function that identifies whether a target
    // is or is inside a details region, and if so expand that region
    // then iterate up the DOM expanding any ancestors, then finally
    // return the original target if applicable, or null if not
    function autostate(target, expanded, ancestor) {
      if (typeof(ancestor) == 'undefined') {
        if (!(target = getAncestor(target, 'details'))) {
          return null;
        }
        ancestor = target;
      } else {
        if (!(ancestor = getAncestor(ancestor, 'details'))) {
          return target;
        }
      }

      statechange(ancestor.__summary, expanded);

      return autostate(target, expanded, ancestor.parentNode);
    }

    // Then if we have a location hash, call the autostate
    // function now with the target element it refers to
    if (location.hash) {
      autostate(document.getElementById(location.hash.substr(1)), false);
    }

    // Bind a click event to handle internal page links
    // ignoring links to other pages, else passing the target it
    // refers to to the autostate function, and if that returns a target
    // auto-scroll the page so that the browser jumps to that target
    // then return true anyway so that the address-bar hash updates
    addEvent(document, 'click', function (e, target) {
      if (!target.href) {
        return true;
      }
      if ((target = target.href.split('#')).length == 1) {
        return true;
      }
      if (document.location.href.split('#')[0] != target[0]) {
        return true;
      }
      if (target = autostate(document.getElementById(target[1]), false)) {
        window.scrollBy(0, target.getBoundingClientRect().top);
      }
      return true;
    });
  }

  // Bind two load events for modern and older browsers
  // If the first one fires it will set a flag to block the second one
  // but if it's not supported then the second one will fire
  addEvent(document, 'DOMContentLoaded', addDetailsPolyfill);
  addEvent(window, 'load', addDetailsPolyfill);

})();
