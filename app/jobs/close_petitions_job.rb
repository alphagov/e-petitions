class ClosePetitionsJob < ActiveJob::Base
  def perform
    Petition.close_petitions!
  end
end
