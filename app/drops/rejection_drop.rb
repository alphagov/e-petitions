class RejectionDrop < ApplicationDrop
  def initialize(rejection)
    @rejection = rejection
  end

  delegate :code, :details, to: :@rejection

  def description
    reason && reason.description
  end

  private

  def reason
    @reason ||= RejectionReason.find_by(code: code)
  end
end
