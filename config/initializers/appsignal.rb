if ENV["SERVER_TYPE"] == "counter"
  Appsignal::Minutely.probes.register :delayed_job_probe, -> {
    Appsignal.set_gauge("delayed_job_queue_length", Delayed::Job.count)
  }
end

unless ENV["APPSIGNAL_APP_NAME"] == "epetitions-production"
  Appsignal.configure do |config|
    config.ignore_actions += [
      "UpdatePetitionStatisticsJob#perform",
      "UpdateSignatureCountsJob#perform"
    ]
  end
end
