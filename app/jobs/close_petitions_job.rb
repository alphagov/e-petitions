class ClosePetitionsJob < ActiveJob::Base
  queue_as :close_petitions

  def perform
    Petition.close_petitions!
  end
end
