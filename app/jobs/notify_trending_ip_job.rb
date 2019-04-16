require 'slack-notifier'

class NotifyTrendingIpJob < ApplicationJob
  include Rails.application.routes.url_helpers

  queue_as :low_priority

  delegate :trending_items_notification_url, to: :rate_limit

  def perform(ip)
    slack.ping(message(ip))
  end

  private

  def message(ip)
    params = []
    params << ip.count
    params << start_time(ip)
    params << end_time(ip)
    params << petition_link(ip)
    params << ip_address_link(ip)

    "%d signatures between %s and %s on %s from %s" % params
  end

  def rate_limit
    @rate_limit ||= RateLimit.first_or_create!
  end

  def slack
    @slack ||= Slack::Notifier.new(trending_items_notification_url)
  end

  def time_format
    "%-I:%M%P"
  end

  def start_time(ip)
    ip.starts_at.strftime(time_format)
  end

  def end_time(ip)
    ip.ends_at.strftime(time_format)
  end

  def petition_link(ip)
    "<#{admin_petition_url(ip.petition)}|#{ip.petition.action}>"
  end

  def ip_address_link(ip)
    "<#{admin_petition_signatures_url(ip.petition, q: ip.ip_address, window: ip.window)}|#{ip.ip_address}>"
  end
end
