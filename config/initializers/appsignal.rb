if ENV["SERVER_TYPE"] == "counter"
  Appsignal::Minutely.probes.register :delayed_job_probe, -> {
    Appsignal.set_gauge("delayed_job_queue_length", Delayed::Job.count)
  }
end
