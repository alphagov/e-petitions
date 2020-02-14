require 'faraday'

module Feed
  class Base
    include Enumerable

    with_options instance_writer: false do
      class_attribute :host, :path, :model
      class_attribute :columns, :filter
      class_attribute :open_timeout, :timeout
      class_attribute :xpath, :klass
    end

    self.host = "http://data.parliament.uk"
    self.path = "/membersdataplatform/open/OData.svc"
    self.open_timeout = 5
    self.timeout = 5
    self.xpath = "//xmlns:feed/xmlns:entry"

    def url
      "#{host}#{endpoint}"
    end

    def endpoint
      "#{path}/#{model}?$select=#{columns}&$filter=#{filter}"
    end

    def each(&block)
      entries.each(&block)
    end

    def inspect
      "#<#{self.class} [#{inspect_entries}]>"
    end

    def size
      entries.size
    end

    private

    def entries
      @entries ||= fetch_entries
    end

    def faraday
      Faraday.new(host) do |f|
        f.response :follow_redirects
        f.response :raise_error
        f.adapter :net_http_persistent
      end
    end

    def fetch_entries
      response = faraday.get(endpoint) do |request|
        request.options[:timeout] = timeout
        request.options[:open_timeout] = open_timeout
      end

      if response.success?
        parse(response.body)
      else
        []
      end
    rescue Faraday::Error => e
      Appsignal.send_exception(e)
      return []
    end

    def parse(xml)
      Nokogiri::XML(xml).xpath(xpath).map { |node| klass.new(node) }
    end

    def inspect_entries
      entries[0..5].map { |e| e.inspect }.join(", ") + (size > 5 ? ", ..." : "")
    end
  end

  class Entry
    with_options instance_writer: false do
      class_attribute :attribute_names, default: []
      class_attribute :attribute_type, default: {}
      class_attribute :attribute_xpath, default: {}
    end

    class << self
      def inherited(child)
        # The class_attribute feature in Active Support can't handle
        # in-place modification for subclasses so force it to happen
        # by assigning new values for each of the config options
        child.attribute_names = []
        child.attribute_type  = {}
        child.attribute_xpath = {}
      end

      def attribute(name, type, xpath)
        attribute_names << name
        attribute_type[name] = type
        attribute_xpath[name] = xpath

        define_method(name) do
          @attributes[name]
        end

        define_method(:"#{name}?") do
          @attributes[name].present?
        end
      end
    end

    attr_reader :attributes

    def initialize(node)
      @attributes = read_attributes(node)
    end

    def inspect
      "<#{self.class} #{inspect_attributes}>"
    end

    def to_ary
      attributes.values
    end
    alias_method :to_a, :to_ary

    private

    def inspect_attributes
      attributes.map { |k,v| "#{k}: #{v.inspect}" }.join(" ")
    end

    def read_attributes(node)
      attribute_names.each_with_object({}) do |name, hash|
        hash[name] = type_cast(read_attribute(node, name), name)
      end
    end

    def read_attribute(node, name)
      node.at_xpath(attribute_xpath[name]).text
    end

    def type_cast(value, name)
      case attribute_type[name]
      when :integer
        Integer(value)
      when :date
        Date.iso8601(value)
      when :time
        Time.iso8601(value)
      else
        value
      end
    end
  end
end
