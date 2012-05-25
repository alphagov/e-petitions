# Load the rails application
require File.expand_path('../application', __FILE__)

Epets::Application.configure do
  #This line removes the <div class="field_with_errors"> wrapper from fields and labels in the view which have failed validation.
  config.action_view.field_error_proc = proc {|html, instance| html }
end

# Initialize the rails application
Epets::Application.initialize!
