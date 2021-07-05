class ImagesController < ActiveStorage::Representations::ProxyController
  def admin_request?
    false
  end
end
