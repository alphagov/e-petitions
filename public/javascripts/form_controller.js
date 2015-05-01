E_PETS.FormController = function FormController(form, start_on_section) {
  form = $(form);
  start_on_section = start_on_section || 0;

  var fields = {};
  init_fields();
  this.fields = fields;

  var pagination_tabs;
  var sections = [];
  var is_wizard_form = form.hasClass('wizard_form');
  var current_section;

  hide_error_summary();
  init_sections();

  form.submit(validate_all);

  //Field Validation
  function init_fields() {
    var inputs = $('input:not([type=hidden]), textarea, select', form);

    //Group inputs by name to ensure related radio buttons are grouped together.
    var input_groups = E_PETS.UTILS.group_collection_by(inputs, 'name');
    for (var field_name in input_groups) {
      fields[field_name] = new Field(input_groups[field_name]);
    }

    // Fix IE6/7 z-index bugs
    var zIndexNumber = 1000;
    if ($.browser.msie) {
      form.find('.row').each(function() {
        $(this).css('z-index', zIndexNumber);
        zIndexNumber -= 10;
      });
    }
  }

  function validates(field_name, validation_opts) {
    var message = validation_opts.message;
    var when = validation_opts.when;
    var func, params;

    if (typeof(validation_opts.method) == 'function') {
      func = validation_opts.method;
      params = [];
    }
    else {
      func = validation_opts.method.shift();
      params = validation_opts.method;
    }

    fields[field_name].add_validation({
      func: func,
      params: params,
      message: message,
      when: when
    });
  }
  this.validates = validates;

  function validate_all() {
    var all_valid = true;
    for (var i in fields) {
      if (!fields[i].validate()) all_valid = false;
    }
    return all_valid;
  }
  this.validate_all = validate_all;

  function observe_field(field_name, func) {
    fields[field_name].observe(func);
  }
  this.observe_field = observe_field;

  function Field(input_group) {
    var wrapper = $(input_group[0]).closest('div.row');
    var validations = [];
    this.validations = validations;

    this.input = input_group[0];

    var error_message = $('.errors', wrapper);
    if (error_message.length == 0 || error_message.hasClass('server_only_validation')) {
      error_message = $('<div class="errors"></div>');
      wrapper.append(error_message);
    }

    var tooltip = $('.tip', wrapper);
    var tooltip_error = $('<p class="error"></p>');
    tooltip.prepend(tooltip_error);
    tooltip.hide();
    tooltip_error.hide();

    bind_events();

    function bind_events() {
      for (var i=0; i<input_group.length; i++) {
        $(input_group[i]).blur(evt_validate);
        if (input_group[i].type == "radio" || input_group[i].type == "checkbox") {
          $(input_group[i]).click(evt_validate);
        }

        $(input_group[i]).focus(show_tooltip);
        $(input_group[i]).blur(hide_tooltip);
      }

      function evt_validate() {
        validate();
      }
    }

    function add_validation(validation) {
      validations.push(validation);
    }
    this.add_validation = add_validation;

    function validate() {
      for (var i in validations) {
        if (validations[i].when == undefined || validations[i].when.apply(input_group[0])) {
          if (!validations[i].func.apply(input_group[0], validations[i].params)) {
            show_invalid_message(validations[i].message);
            push_feedback(validations[i].message);
            return false;
          }
        }
      }
      hide_invalid_message();
      return true;
    }
    this.validate = validate;

    function show_invalid_message(message) {
      error_message.html(message);
      error_message.show();
      tooltip_error.html(message);
      tooltip_error.show();
      wrapper.addClass('invalid_row');
    }
    function hide_invalid_message() {
      error_message.hide();
      tooltip_error.hide();
      wrapper.removeClass('invalid_row');
    }

    function show_tooltip() {
      tooltip.show();
    }
    function hide_tooltip() {
      tooltip.hide();
    }

    function observe(func) {
      for (var i in input_group) {
        $(input_group[i]).change(func);
        $(input_group[i]).blur(func);
        func.apply(input_group[i]);
      }
    }
    this.observe = observe;
  }

  function hide_error_summary() {
    $("#errorExplanation").hide();
  }

  //Sections / wizard behaviour
  function init_sections() {
    var fieldsets = $('fieldset', form);
    for (var i=0; i<fieldsets.length; i++) {
      sections.push(new Section(fieldsets[i], i, fieldsets.length));
    }

    if (is_wizard_form) {
      var pagination = $('.form_pagination', form).show();
      pagination_tabs = $('.pagination_tab', pagination);

      for (var tab=0; tab<pagination_tabs.length; tab++) {
        pagination_tabs[tab].tab_no = tab;
        $(pagination_tabs[tab]).click(function() {
          show_earlier_section(this.tab_no);
          return false;
        });
      }
    }
    show_section(start_on_section);
  }

  function show_section(section_number) {

    if (pagination_tabs) {
      pagination_tabs.removeClass('active');
    }
    for (var i=0; i<sections.length; i++) {
      if (i == section_number) {
        sections[i].show();
        if (pagination_tabs) {
          $(pagination_tabs[i]).addClass('active');
        }
      }
      else {
        sections[i].hide();
      }
    }
    current_section = section_number;
  }
  function show_next_section() {
    if (sections[current_section+1]) show_section(current_section+1);
  }
  function show_prev_section() {
    if (current_section != 0) show_section(current_section-1);
  }
  function show_earlier_section(section_number) {
    if (section_number < current_section) show_section(section_number);
  }

  function Section(fieldset, section_no, no_sections){
    fieldset = $(fieldset);
    var section_fields = get_fields_for_section();

    if (is_wizard_form) add_next_prev_buttons();

    $('input[type=submit]', fieldset).click(function() {
      return is_valid();
    });

    function add_next_prev_buttons() {
      var is_first_section = section_no == 0;
      var is_last_section = section_no == no_sections-1;

      var btn_row = $('.button_row', fieldset);
      if (btn_row.length == 0) {
        btn_row = $('<div class="row button_row"></div>');
        fieldset.append(btn_row);
      }
      var last_tabindex = btn_row.prev().find('*[tabindex]').attr('tabindex');

      if (!is_last_section) {
        var next_btn = $('<button class="forward_action">Next</button>');
        next_btn.attr('tabindex', last_tabindex + 1);
        btn_row.prepend(next_btn);
        next_btn.click(function(e) {
          e.preventDefault();
          next_if_valid();
        });
      }
      if (!is_first_section) {
        var prev_btn = $('<button class="backwards_action">Back</button>');
        prev_btn.attr('tabindex', last_tabindex + 2);
        btn_row.prepend(prev_btn);
        prev_btn.click(function(e) {
          e.preventDefault();
          show_prev_section();
        });
      }
    }

    function get_fields_for_section() {
      var fields_for_section = [];
      var inputs = $('input, textarea, select', fieldset);
      var input_groups = E_PETS.UTILS.group_collection_by(inputs, 'name');
      for (var field_name in input_groups) {
        fields_for_section.push(field_name);
      }
      return fields_for_section;
    }

    function next_if_valid() {
      if (is_valid()) {
        show_next_section();
      }
      else
      {
        show();
      }
    }

    function is_valid() {
      clear_feedback();
      var is_valid = true;
      for (var i in section_fields) {
        if (!fields[section_fields[i]].validate()) is_valid = false;
      }
      if (!is_valid) {
        read_all_feedback(fields[section_fields[0]].input);
        error_row = $('.invalid_row');
        if (error_row) {
          var error_tag = error_row.first().find("input,textarea,select").first();
          error_tag.focus();
          if (!error_tag.size() == 0) {
            $('html,body').animate({ scrollTop: error_row.offset().top}, 0.0);
          }
        }
      }
      return is_valid;
    }

    function show() {
      fieldset.show();
      error_row = fieldset.find('.invalid_row');
      if (error_row) {
        var error_tag = error_row.first().find("input,textarea,select").first();
        error_tag.focus();
        if (!error_tag.size() == 0) {
          $('html,body').animate({ scrollTop: error_row.offset().top}, 0.0);
        }
      } else {
        fieldset.find('*[tabindex]').first().focus();
      }
    };
    this.show = show;

    function hide() {
      fieldset.hide();
    };
    this.hide = hide;
  };
};

E_PETS.FormController.validation_methods = {
  validate_presence: function validate_presence() {
    return !!this.value;
  },
  validate_format: function validate_format(regex) {
    this.value = this.value.replace(/^\s+|\s+$/g, '');
    this.value = this.value.replace(/ +/, ' ');
    return !!(regex.exec(this.value));
  },
  validate_confirmation: function validate_confirmation(field) {
    this.value = this.value.replace(/^\s+|\s+$/g, '');
    return (this.value == $('input[name="'+ field +'"]').val());
  },
  validate_radio_group_value: function validate_radio_group_value(value) {
    var radio_buttons = $('input[name="'+ this.name +'"]');
    var checked_button;
    for(var i=0; i<radio_buttons.length; i++) {
      if (radio_buttons[i].checked) {
        checked_button = radio_buttons[i];
        break;
      }
    }
    return checked_button && checked_button.value == value;
  },
  validate_length: function validate_length(start, end) {
    return ((start == null || this.value.length >= start) && (end == null || this.value.length <= end));
  },
  validate_checked: function validate_checked() {
    return this.checked;
  }
};

E_PETS.FormController.validation_formats = {
  email: /^([A-Za-z0-9_\.%\+\-\'])+\@([A-Za-z0-9\-\.])+\.([A-Za-z]{2,4})$/,
  postcode: /^(([A-Z]{1,2}[0-9][0-9A-Z]? ?[0-9][A-BD-HJLNP-UW-Z]{2})|(BFPO? ?(C\/O)? ?[0-9]{1,4}))$/i
};
