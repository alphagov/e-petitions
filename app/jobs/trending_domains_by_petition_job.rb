class TrendingDomainsByPetitionJob < ApplicationJob
  delegate :enable_logging_of_trending_items?, to: :rate_limit
  delegate :threshold_for_logging_trending_items, to: :rate_limit
  delegate :threshold_for_notifying_trending_items, to: :rate_limit
  delegate :ignore_domain?, to: :rate_limit
  delegate :trending_domains_by_petition, to: :Signature

  def perform(now = Time.current)
    return unless enable_logging_of_trending_items?

    trending_domains(now).each do |id, domains|
      petition = Petition.find(id)

      domains.each do |domain, count|
        next unless domain.present?
        next if ignore_domain?(domain)

        begin
          trending_domain = petition.trending_domains.log!(starts_at(now), domain, count)

          if count >= threshold_for_notifying_trending_items
            NotifyTrendingDomainJob.perform_later(trending_domain)
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

  def trending_domains(now)
    trending_domains_by_petition(window(now), threshold_for_logging_trending_items)
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
