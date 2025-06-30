class PetitionMailshotDrop < ApplicationDrop
  def initialize(mailshot)
    @mailshot = mailshot
  end

  with_options to: :@mailshot do
    delegate :subject, :body
  end
end
