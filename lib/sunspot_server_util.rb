class SunspotServerUtil
   require 'net/http'
  
  # see http://blog.kabisa.nl/2010/02/03/running-cucumber-features-with-sunspot_rails/
  def self.wait_for_sunspot_to_start(port_no)
    @started = Time.now
    while starting(port_no)
      puts "Sunspot server is starting..."
    end
    puts "Sunspot server took #{'%.2f' % (Time.now - @started)} sec. to get up and running."
  end
  
  def self.starting(port_no)
    begin
      sleep(1)
      request = Net::HTTP.get_response(URI.parse("http://0.0.0.0:#{port_no}/solr/"))
      false
    rescue Errno::ECONNREFUSED
      true
    end
  end
end