class TrendingIpsByPetitionJob < ApplicationJob
  delegate :enable_logging_of_trending_ips?, to: :rate_limit
  delegate :threshold_for_logging_trending_ip, to: :rate_limit
  delegate :threshold_for_notifying_trending_ip, to: :rate_limit
  delegate :trending_ips_by_petition, to: :Signature

  def perform(now = Time.current)
    return unless enable_logging_of_trending_ips?

    trending_ips(now).each do |id, ips|
      petition = Petition.find(id)

      ips.each do |ip, count|
        next unless ip.present?

        begin
          trending_ip = petition.trending_ips.log!(starts_at(now), ip, count)

          if count >= threshold_for_notifying_trending_ip
            NotifyTrendingIpJob.perform_later(trending_ip)
          end
        rescue StandardError => e
          Appsignal.send_exception e
        end
      end
    end
  end

  private

  def rate_limit
    @rate_limit ||= RateLimit.first_or_create!
  end

  def trending_ips(now)
    trending_ips_by_petition(window(now), threshold_for_logging_trending_ip)
  end

  def petitions
    Petition.where(id: petition_ids)
  end

  def window(now)
    starts_at(now)..ends_at(now)
  end

  def starts_at(now)
    @starts_at ||= ends_at(now).advance(hours: -1)
  end

  def ends_at(now)
    @ends_at ||= now.at_beginning_of_hour
  end
end
