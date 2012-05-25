E_PETS.Accessibility = new function Accessibility() {
  function init() {
    this.feedback_controller = new FeedbackController();
  }
  this.init = init;
  
  function FeedbackController() {
    var feedback_field;
    var queued_feedback = [];
    var next_field;

    feedback_field = $('<input type="radio" tabindex="3"/>');
    feedback_field.css({
      position: 'fixed',
      left: '-9999px',
      top: '10px',
      display: 'none',
      width: '1px',
      height: '1px'
    });
    $(document.body).append(feedback_field);
    feedback_field.keypress(evt_keypress);
    
    function push(text) {
      queued_feedback.push(text);
    }
    window.push_feedback = this.push = push;
    function read_all(_next_field) {
      next_field = $(_next_field);
      var text = queued_feedback.join(" ");
      text += " Press space to return focus to the form. This field is provided for giving feedback only and is not meant to be interacted with.";
      feedback_field.attr('title', text);
      feedback_field.show();
      feedback_field.focus();
    }
    window.read_all_feedback = this.read_all = read_all;
    function clear() {
      queued_feedback = [];
      feedback_field.hide();
    }
    window.clear_feedback = this.clear = clear;
    
    function go_to_next() {
      if (next_field) {
        next_field.focus();
      }
    }
    
    function evt_keypress(e) {
      if (e.keyCode == 32) {
        go_to_next();
        return false;
      } 
    }
  };
}();
