class ApplicationMailer < ActionMailer::Base
  default_url_options[:protocol] = Site.email_protocol
  default from: ->(email){ Site.email_from }

  helper :date_time, :rejection, :auto_link, :markdown, :moderation, :number

  layout 'default_mail'

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
      context["site"] = Site.instance
      context["petition"] = @petition if defined?(@petition)
      context["creator"] = @creator if defined?(@creator)
      context["sponsor"] = @sponsor if defined?(@sponsor)
      context["signature"] = @signature if defined?(@signature)
      context["email"] = @email if defined?(@email)
    end
  end
end
