require 'rails_helper'
require 'health_check_middleware'

RSpec.describe HealthCheckMiddleware do
  let(:env) { {} }
  let(:app) { double }
  subject { HealthCheckMiddleware.new(app) }

  context 'invoking the healthcheck based on paths' do
    it 'matches "/health-check"' do
      expect(app).not_to receive(:call)
      expect(HealthCheck).to receive(:checkup)
      env['PATH_INFO'] = '/health-check'
      subject.call(env)
    end

    it 'matches "/health-check/" (e.g. trailing slashes)' do
      expect(app).not_to receive(:call)
      expect(HealthCheck).to receive(:checkup)
      env['PATH_INFO'] = '/health-check/'
      subject.call(env)
    end

    it 'ignores "/health-check/blah" (e.g. extra path segments after health-check)' do
      expect(app).to receive(:call)
      expect(HealthCheck).not_to receive(:checkup)
      env['PATH_INFO'] = '/health-check/blah'
      subject.call(env)
    end

    it 'ignores "/blah/health-check" (e.g. extra path segments before health-check)' do
      expect(app).to receive(:call)
      expect(HealthCheck).not_to receive(:checkup)
      env['PATH_INFO'] = '/blah/health-check'
      subject.call(env)
    end

    it 'ignores "/petitions/1/" (e.g. paths that look nothing like health-check)' do
      expect(app).to receive(:call)
      expect(HealthCheck).not_to receive(:checkup)
      env['PATH_INFO'] = '/blah/health-check'
      subject.call(env)
    end
  end

  context 'when the PATH_INFO inovkes the health check' do
    let(:checkup_data) { {} }
    before do
      env['PATH_INFO'] = '/health-check'
      allow(HealthCheck).to receive(:checkup).with(env).and_return checkup_data
    end

    it 'renders the result of the checkup as JSON' do
      checkup_data['hats'] = 'OK'
      checkup_data['cheese-board'] = ['cheddar', 'roquefort', 'casu-marzu']
      status, headers, body = subject.call(env)

      expect(status).to eq 200
      expect(headers['Content-Type']).to eq 'application/json'
      expect(body.first).to eq checkup_data.to_json
    end
  end

  context 'when the PATH_INFO does not invoke the health check' do
    before { env['PATH_INFO'] = '/petitions/1' }

    it 'calls through to the wrapped app and returns its response' do
      app_response = double
      expect(app).to receive(:call).with(env).and_return app_response
      expect(subject.call(env)).to eq app_response
    end
  end
end
