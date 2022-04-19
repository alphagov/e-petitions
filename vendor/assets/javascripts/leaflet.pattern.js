/*
 Leaflet.pattern, Provides tools to set the backgrounds of vector shapes in Leaflet to be patterns.
 https://github.com/teastman/Leaflet.pattern
 (c) 2015, Tyler Eastman
*/
(function (window, document, undefined) {/*
 * L.Pattern is the base class for fill patterns for leaflet Paths.
 */

L.Pattern = L.Class.extend({
  includes: [L.Evented],

  options: {
    x: 0,
    y: 0,
    width: 8,
    height: 8,
    patternUnits: 'userSpaceOnUse',
    patternContentUnits: 'userSpaceOnUse'
    // angle: <0 - 360>
    // patternTransform: <transform-list>
  },

  _addShapes: L.Util.falseFn,
  _update: L.Util.falseFn,

  initialize: function (options) {
    this._shapes = {};
    L.setOptions(this, options);
  },

  onAdd: function (map) {
        this._map = map.target ? map.target : map;
        this._map._initDefRoot();

    // Create the DOM Object for the pattern.
    this._initDom();

    // Any shapes that were added before this was added to the map need to have their onAdd called.
    for (var i in this._shapes) {
      this._shapes[i].onAdd(this);
    }

    // Call any children that want to add their own shapes.
    this._addShapes();

    // Add the DOM Object to the DOM Tree
    this._addDom();
    this.redraw();

    if (this.getEvents) {
            this._map.on(this.getEvents(), this);
    }
    this._map.fire('add');
        this._map.fire('patternadd', {pattern: this});
  },

  onRemove: function () {
    this._removeDom();
  },

  redraw: function () {
    if (this._map) {
      this._update();
      for (var i in this._shapes) {
        this._shapes[i].redraw();
      }
    }
    return this;
  },

  setStyle: function (style) {
    L.setOptions(this, style);
    if (this._map) {
      this._updateStyle();
      this.redraw();
    }
    return this;
  },

  addTo: function (map) {
    map.addPattern(this);
    return this;
  },

  remove: function () {
    return this.removeFrom(this._map);
  },

  removeFrom: function (map) {
    if (map) {
      map.removePattern(this);
    }
    return this;
  }
});

L.Map.addInitHook(function () {
  this._patterns = {};
});

L.Map.include({
  addPattern: function (pattern) {
    var id = L.stamp(pattern);
    if (this._patterns[id]) { return pattern; }
    this._patterns[id] = pattern;

    this.whenReady(pattern.onAdd, pattern);
    return this;
  },

  removePattern: function (pattern) {
    var id = L.stamp(pattern);
    if (!this._patterns[id]) { return this; }

    if (this._loaded) {
      pattern.onRemove(this);
    }

    if (pattern.getEvents) {
      this.off(pattern.getEvents(), pattern);
    }

    delete this._patterns[id];

    if (this._loaded) {
      this.fire('patternremove', {pattern: pattern});
      pattern.fire('remove');
    }

    pattern._map = null;
    return this;
  },

  hasPattern: function (pattern) {
    return !!pattern && (L.stamp(pattern) in this._patterns);
  }
});



L.Pattern.SVG_NS = 'http://www.w3.org/2000/svg';

L.Pattern = L.Pattern.extend({
  _createElement: function (name) {
    return document.createElementNS(L.Pattern.SVG_NS, name);
  },

  _initDom: function () {
    this._dom = this._createElement('pattern');
    if (this.options.className) {
      L.DomUtil.addClass(this._dom, this.options.className);
    }
    this._updateStyle();
  },

  _addDom: function () {
    this._map._defRoot.appendChild(this._dom);
  },

  _removeDom: function () {
    L.DomUtil.remove(this._dom);
  },

  _updateStyle: function () {
    var dom = this._dom,
      options = this.options;

    if (!dom) { return; }

    dom.setAttribute('id', L.stamp(this));
    dom.setAttribute('x', options.x);
    dom.setAttribute('y', options.y);
    dom.setAttribute('width', options.width);
    dom.setAttribute('height', options.height);
    dom.setAttribute('patternUnits', options.patternUnits);
//    dom.setAttribute('patternContentUnits', options.patternContentUnits);

    if (options.patternTransform || options.angle) {
      var transform = options.patternTransform ? options.patternTransform + " " : "";
      transform += options.angle ?  "rotate(" + options.angle + ") " : "";
      dom.setAttribute('patternTransform', transform);
    }
    else {
      dom.removeAttribute('patternTransform');
    }

    for (var i in this._shapes) {
      this._shapes[i]._updateStyle();
    }
  }
});

L.Map.include({
  _initDefRoot: function () {
        if (!this._defRoot) {
            if (typeof this.getRenderer === 'function') {
                var renderer = this.getRenderer(this);
                this._defRoot = L.Pattern.prototype._createElement('defs');
                renderer._container.appendChild(this._defRoot);
            } else {
                if (!this._pathRoot) {
                    this._initPathRoot();
                }
                this._defRoot = L.Pattern.prototype._createElement('defs');
                this._pathRoot.appendChild(this._defRoot);
            }
        }
    }
});

if (L.SVG) {
    L.SVG.include({
        _superUpdateStyle: L.SVG.prototype._updateStyle,

        _updateStyle: function (layer) {
            this._superUpdateStyle(layer);

            if (layer.options.fill && layer.options.fillPattern) {
                layer._path.setAttribute('fill', 'url(#' + L.stamp(layer.options.fillPattern) + ")");
            }
        }
    });
}
else {
    L.Path.include({
        _superUpdateStyle: L.Path.prototype._updateStyle,

        _updateStyle: function () {
            this._superUpdateStyle();

            if (this.options.fill && this.options.fillPattern) {
                this._path.setAttribute('fill', 'url(#' + L.stamp(this.options.fillPattern) + ")");
            }
        }
    });
}


/*
 * L.StripePattern is an implementation of Pattern that creates stripes.
 */

L.StripePattern = L.Pattern.extend({

  options: {
    weight: 4,
    spaceWeight: 4,
    color: '#000000',
    spaceColor: '#ffffff',
    opacity: 1.0,
    spaceOpacity: 0.0
  },

  _addShapes: function () {
    this._stripe = new L.PatternPath({
      stroke: true,
      weight: this.options.weight,
      color: this.options.color,
      opacity: this.options.opacity
    });

    this._space = new L.PatternPath({
      stroke: true,
      weight: this.options.spaceWeight,
      color: this.options.spaceColor,
      opacity: this.options.spaceOpacity
    });

    this.addShape(this._stripe);
    this.addShape(this._space);

    this._update();
  },

  _update: function () {
    this._stripe.options.d = 'M0 ' + this._stripe.options.weight / 2 + ' H ' + this.options.width;
    this._space.options.d = 'M0 ' + (this._stripe.options.weight + this._space.options.weight / 2) + ' H ' + this.options.width;
  },

  setStyle: L.Pattern.prototype.setStyle
});

L.stripePattern = function (options) {
  return new L.StripePattern(options);
};

/*
 * L.PatternShape is the base class that is used to define the shapes in Patterns.
 */

L.PatternShape = L.Class.extend({

  options: {
    stroke: true,
    color: '#3388ff',
    weight: 3,
    opacity: 1,
    lineCap: 'round',
    lineJoin: 'round',
    // dashArray: null
    // dashOffset: null

    // fill: false
    // fillColor: same as color by default
    fillOpacity: 0.2,
    fillRule: 'evenodd',
    // fillPattern: L.Pattern
  },

  initialize: function (options) {
    L.setOptions(this, options);
  },

  // Called when the parent Pattern get's added to the map,
  // or when added to a Pattern that is already on the map.
  onAdd: function (pattern) {
    this._pattern = pattern;
    if (this._pattern._dom) {
      this._initDom();  // This function is implemented by it's children.
      this._addDom();
    }
  },

  addTo: function (pattern) {
    pattern.addShape(this);
    return this;
  },

  redraw: function () {
    if (this._pattern) {
      this._updateShape();  // This function is implemented by it's children.
    }
    return this;
  },

  setStyle: function (style) {
    L.setOptions(this, style);
    if (this._pattern) {
      this._updateStyle();
    }
    return this;
  },

  setShape: function (shape) {
        this.options = L.extend({}, this.options, shape);
    this._updateShape();
  },
});

L.Pattern.include({
  addShape: function (shape) {
    var id = L.stamp(shape);
    if (this._shapes[id]) { return shape; }
    this._shapes[id] = shape;
    shape.onAdd(this);
  }
});



L.PatternShape.SVG_NS = 'http://www.w3.org/2000/svg';

L.PatternShape = L.PatternShape.extend({
  _createElement: function (name) {
    return document.createElementNS(L.PatternShape.SVG_NS, name);
  },

  _initDom: L.Util.falseFn,
  _updateShape: L.Util.falseFn,

  _initDomElement: function (type) {
    this._dom = this._createElement(type);
    if (this.options.className) {
      L.DomUtil.addClass(this._dom, this.options.className);
    }
    this._updateStyle();
  },

  _addDom: function () {
    this._pattern._dom.appendChild(this._dom);
  },

  _updateStyle: function () {
    var dom = this._dom,
      options = this.options;

    if (!dom) { return; }

    if (options.stroke) {
      dom.setAttribute('stroke', options.color);
      dom.setAttribute('stroke-opacity', options.opacity);
      dom.setAttribute('stroke-width', options.weight);
      dom.setAttribute('stroke-linecap', options.lineCap);
      dom.setAttribute('stroke-linejoin', options.lineJoin);

      if (options.dashArray) {
        dom.setAttribute('stroke-dasharray', options.dashArray);
      } else {
        dom.removeAttribute('stroke-dasharray');
      }

      if (options.dashOffset) {
        dom.setAttribute('stroke-dashoffset', options.dashOffset);
      } else {
        dom.removeAttribute('stroke-dashoffset');
      }
    } else {
      dom.setAttribute('stroke', 'none');
    }

    if (options.fill) {
      if (options.fillPattern) {
        dom.setAttribute('fill', 'url(#' + L.stamp(options.fillPattern) + ")");
      }
      else {
        dom.setAttribute('fill', options.fillColor || options.color);
      }
      dom.setAttribute('fill-opacity', options.fillOpacity);
      dom.setAttribute('fill-rule', options.fillRule || 'evenodd');
    } else {
      dom.setAttribute('fill', 'none');
    }

    dom.setAttribute('pointer-events', options.pointerEvents || (options.interactive ? 'visiblePainted' : 'none'));
  }
});



/*
 * L.PatternPath is the implementation of PatternShape for adding Paths
 */

L.PatternPath = L.PatternShape.extend({
//  options: {
    // d: <svg path code>
//  },

  _initDom: function () {
    this._initDomElement('path');
  },

  _updateShape: function () {
        if (!this._dom) { return; }
    this._dom.setAttribute('d', this.options.d);
  }
});

/*
 * L.PatternCircle is the implementation of PatternShape for adding Circles
 */

L.PatternCircle = L.PatternShape.extend({
  options: {
        x: 0,
        y: 0,
        radius: 0
  },

  _initDom: function () {
    this._initDomElement('circle');
  },

  _updateShape: function () {
        if (!this._dom) { return; }
    this._dom.setAttribute('cx', this.options.x);
    this._dom.setAttribute('cy', this.options.y);
    this._dom.setAttribute('r', this.options.radius);
  }
});

/*
 * L.PatternRect is the implementation of PatternShape for adding Rectangles
 */

L.PatternRect = L.PatternShape.extend({
  options: {
        x: 0,
        y: 0,
        width: 10,
        height: 10,
        // rx: x radius for rounded corners
        // ry: y radius for rounded corners
  },

  _initDom: function () {
    this._initDomElement('rect');
  },

  _updateShape: function () {
        if (!this._dom) { return; }
    this._dom.setAttribute('x', this.options.x);
    this._dom.setAttribute('y', this.options.y);
    this._dom.setAttribute('width', this.options.width);
    this._dom.setAttribute('height', this.options.height);
        if (this.options.rx) { this._dom.setAttribute('rx', this.options.rx); }
    if (this.options.ry) { this._dom.setAttribute('ry', this.options.ry); }
  }
});

}(window, document));
