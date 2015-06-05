require 'singleton'

class AppConfig
  include Singleton

  class << self
    def method_missing(name, *args)
      if instance.respond_to?(name)
        instance.send(name, *args)
      else
        super
      end
    end
  end

  def respond_to?(name, *args)
    config.key?(name.to_s)
  end

  def method_missing(name, *args)
    config.key?(name.to_s) ? config[name.to_s] : super
  end

  private

  def config
    @config ||= load_app_config[Rails.env]
  end

  def load_app_config
    YAML.load(ERB.new(yaml).result)
  end

  def yaml
    File.read(Rails.root.join(*%w[config application.yml]))
  end
end
