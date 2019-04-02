require 'slack-notifier'

class NotifyTrendingDomainJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :low_priority

  delegate :trending_ip_notification_url, to: :rate_limit

  def perform(domain)
    slack.ping(message(domain))
  end

  private

  def message(domain)
    params = []
    params << domain.count
    params << start_time(domain)
    params << end_time(domain)
    params << petition_link(domain)
    params << domain_address_link(domain)

    "%d signatures between %s and %s on %s from %s" % params
  end

  def rate_limit
    @rate_limit ||= RateLimit.first_or_create!
  end

  def slack
    @slack ||= Slack::Notifier.new(trending_ip_notification_url)
  end

  def time_format
    "%-I:%M%P"
  end

  def start_time(domain)
    domain.starts_at.strftime(time_format)
  end

  def end_time(domain)
    domain.ends_at.strftime(time_format)
  end

  def petition_link(domain)
    "<#{admin_petition_url(domain.petition)}|#{domain.petition.action}>"
  end

  def domain_address_link(domain)
    "<#{admin_petition_signatures_url(domain.petition, q: domain.domain)}|#{domain.domain}>"
  end
end
