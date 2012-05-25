# Use firefox 7 if possible
require "selenium-webdriver"
["/Applications/Firefox7.app/Contents/MacOS/firefox-bin",
 "/Applications/Firefox 7.app/Contents/MacOS/firefox-bin"].each do |path|
  if (FileTest.exist?(path))
    Selenium::WebDriver::Firefox.path=path
    break
  end
end