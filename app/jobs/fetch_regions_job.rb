class FetchRegionsJob < ApplicationJob
  rescue_from StandardError do |exception|
    Appsignal.send_exception exception
  end

  def perform
    regions.each do |external_id, name, ons_code|
      begin
        Region.for(external_id) do |region|
          region.update!(name: name, ons_code: ons_code)
        end
      rescue ActiveRecord::RecordNotUnique => e
        retry
      end
    end
  end

  private

  def regions
    @regions ||= Feed::Regions.new
  end
end
