# Preview all emails at http://localhost:3000/rails/mailers/sponsor_mailer
class SponsorMailerPreview < ActionMailer::Preview
  def new_sponsor_email
    SponsorMailer.new_sponsor_email(Sponsor.first)
  end
end
