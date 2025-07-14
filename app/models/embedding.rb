require 'informers'

module Embedding
  class GenerationError < RuntimeError; end

  module Backends
    class Informers
      with_options instance_writer: false do
        class_attribute :model, default: ENV.fetch('INFORMERS_MODEL', 'sentence-transformers/all-MiniLM-L6-v2')
      end

      def generate(input)
        pipeline.call(input)
      rescue StandardError => e
        raise Embedding::GenerationError, "Unable to generate an embedding using Informers"
      end

      private

      def pipeline
        @pipeline ||= ::Informers.pipeline('embedding', model)
      end
    end

    class Random
      def generate(input)
        384.times.map { rand }
      end
    end
  end

  class << self
    def generate(input)
      client.generate(input)
    end

    def backend
      Backends.const_get(ENV.fetch('EMBEDDING_BACKEND', 'Informers'))
    end

    def client
      Thread.current[:__embedding__] ||= backend.new
    end

    def reload
      Thread.current[:__embedding__] = nil
    end
  end
end
