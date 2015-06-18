# Ensure the agent is started using Unicorn
# This is needed when using Unicorn and preload_app is not set to true.
# See http://support.newrelic.com/kb/troubleshooting/unicorn-no-data
NewRelic::Agent.after_fork(:force_reconnect => true) if defined? Unicorn

# Required for profiling garbage collection in New Relic
# See https://docs.newrelic.com/docs/agents/ruby-agent/features/garbage-collection
GC::Profiler.enable
