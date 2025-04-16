class ApplicationMailer < ActionMailer::Base
  default_url_options[:protocol] = Site.email_protocol
  default from: ->(email){ Site.email_from }

  helper :date_time, :rejection, :auto_link, :markdown, :number

  layout 'default_mail'

  LIQUID_VARIABLES = {
    :@site => "site",
    :@parliament => "parliament",
    :@petition => "petition",
    :@petitions => "petitions",
    :@creator => "creator",
    :@sponsor => "sponsor",
    :@signature => "signature",
    :@rejection => "rejection",
    :@government_response => "response",
    :@debate_outcome => "outcome",
    :@email => "email",
    :@mailshot => "mailshot",
    :@count => "count",
    :@remaining => "remaining",
    :@closing_time => "closing_time",
    :@closing_date => "closing_date",
    :@election_date => "election_date",
    :@registration_deadline => "registration_deadline",
    :@last_response_date => "last_response_date",
    :@subject => "subject",
    :@body => "body"
  }.freeze

  def mail(**)
    return super unless Site.enhanced_email_formatting?

    if template = Email::Template.load(mailer_name, action_name)
      @view = Email::View.new(template, liquid_context)

      super(**, subject: @view.subject) do |format|
        format.html { render "liquid", layout: false }
        format.text { render "liquid", layout: false }
      end
    else
      super
    end
  end

  def liquid_context
    {}.tap do |context|
      LIQUID_VARIABLES.each do |variable, key|
        next unless defined?(variable)

        context[key] = instance_variable_get(variable)
      end

      context["site"] ||= Site.instance
      context["parliament"] ||= Parliament.instance
    end
  end
end
