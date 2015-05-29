require 'rails_helper'
require 'health_check'

describe HealthCheck do
  describe '.checkup' do
    let(:env) { {} }
    subject { HealthCheck.checkup(env) }

    it 'includes the hostname' do
      allow(Socket).to receive(:gethostname).and_return("testhost.example.com")

      expect(subject['hostname']).to eq 'testhost'
    end

    it 'includes the fully qualified domain name' do
      allow(Socket).to receive(:gethostname).and_return("testhost.example.com")

      expect(subject['fqdn']).to eq 'testhost.example.com'
    end

    it "includes the url of the client request (as provided by the REQUEST_URI)" do
      env['REQUEST_URI'] = 'http://example.com/can-I-look-at-the-petitions-please'
      expect(subject['url']).to eq 'http://example.com/can-I-look-at-the-petitions-please'
    end

    it 'warns if no REQUEST_URI is present from which to fetch the url of the client request' do
      env.delete('REQUEST_URI')
      expect(subject['url']).to eq 'FAILED: no REQUEST_URI present in env'
    end

    it "includes the host_ip" do
      allow(Socket).to receive(:getaddrinfo).and_return([[nil ,nil ,nil, '1.2.3.4']])

      expect(subject['host_ip']).to eq '1.2.3.4'
    end

    it 'includes the ip of the client request (as provided by the REMOTE_ADDR)' do
      env['REMOTE_ADDR'] = '10.11.12.13'
      expect(subject['client_ip']).to eq '10.11.12.13'
    end

    it 'warns if no REMOTE_ADDR is present from which to fetch the ip of the client request' do
      env.delete('REMOTE_ADDR')
      expect(subject['client_ip']).to eq 'FAILED: no REMOTE_ADDR present in env'
    end

    it 'includes the local time on the server in the timezone and as utc' do
      now = Time.parse("1 Jan 2011 12:34:56 PST")
      allow(Time).to receive(:current).and_return(now)
      local_time_string = now.rfc2822
      utc_time_string = now.getutc.rfc2822

      expect(subject['localtime']).to eq local_time_string
      expect(subject['utctime']).to eq utc_time_string
    end

    describe "includes database connection status" do
      it "is normally ok" do
        expect(subject['database_connection']).to eq 'OK'
      end

      it "detects failure" do
        allow(ActiveRecord::Base).to receive(:establish_connection).and_raise(StandardError)
        expect(subject['database_connection']).to eq 'FAILED'
      end
    end

    describe "includes database persistence status" do
      it "is normally ok" do
        expect(subject['database_persistence']).to eq 'OK'
      end

      it "detects failure to read records" do
        allow(SystemSetting).to receive(:find_by_key).with(HealthCheck::TEST_SETTINGS_KEY).and_return(nil)
        expect(subject['database_persistence']).to eq 'FAILED'
      end

      it "detects failure to write records" do
        allow(SystemSetting).to receive(:create!).and_raise(StandardError)
        expect(subject['database_persistence']).to eq 'FAILED'
      end
    end

    describe 'includes database integrity status' do
      it "is ok when we are fully migrated" do
        expect(ActiveRecord::Migrator).to receive(:needs_migration?).and_return false
        expect(subject['database_integrity']).to eq 'OK'
      end

      it "detects when we are missing some migrations" do
        expect(ActiveRecord::Migrator).to receive(:needs_migration?).and_return true
        expect(subject['database_integrity']).to eq 'FAILED'
      end
    end
  end
end
