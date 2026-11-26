# Chrome 158 rejects the "*" origin that Capybara 3.40.0 passes to the
# Storage.clearDataForOrigin DevTools command when resetting the session,
# so every JavaScript scenario fails in teardown with:
#
#   Selenium::WebDriver::Error::InvalidArgumentError:
#     invalid argument: * is not a valid URL
#
# Instead, clear every cookie and the local storage of each origin in the
# tab's navigation history, as in teamcapybara/capybara#2867.
#
# See: https://github.com/teamcapybara/capybara/issues/2865
module CapybaraChromeReset
  def reset!
    # Use instance variable directly so we avoid starting the browser just to reset the session
    return unless @browser

    switch_to_window(window_handles.first)
    window_handles.slice(1..).each { |win| close_window(win) }

    timer = Capybara::Helpers.timer(expire_in: 10)
    begin
      clear_storage unless uniform_storage_clear?
      @browser.navigate.to("about:blank")
      wait_for_empty_page(timer)
    rescue *unhandled_alert_errors
      accept_unhandled_reset_alert
      retry
    end

    delete_all_cookies
    clear_visited_local_storage if clear_all_storage?
  end

  private

  def clear_visited_local_storage
    visited_origins.each do |origin|
      execute_cdp("Storage.clearDataForOrigin", origin: origin, storageTypes: "local_storage")
    end
  end

  def visited_origins
    execute_cdp("Page.getNavigationHistory")["entries"].filter_map { |entry| origin_of(entry["url"]) }.uniq
  end

  def origin_of(url)
    uri = URI.parse(url.to_s)
    uri.origin if uri.is_a?(URI::HTTP) && uri.host.present?
  rescue URI::InvalidURIError
    nil
  end
end

if Gem::Version.new(Capybara::VERSION) > Gem::Version.new("3.40.0")
  raise <<~MESSAGE
    Capybara has been upgraded to #{Capybara::VERSION}. If it includes the fix for
    teamcapybara/capybara#2865, delete #{__FILE__}. Otherwise check the patch still
    matches Capybara::Selenium::Driver::ChromeDriver#reset! and update the version in
    this check.
  MESSAGE
end

Capybara::Selenium::Driver::ChromeDriver.prepend(CapybaraChromeReset)
