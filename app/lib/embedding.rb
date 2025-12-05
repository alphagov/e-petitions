require 'faraday'
require 'aws-sdk-bedrockruntime'
require 'openai'
require 'digest/md5'

module Embedding
  class GenerationError < RuntimeError; end

  module Backends
    class AmazonBedrock
      with_options instance_writer: false do
        class_attribute :model_id, default: ENV.fetch('BEDROCK_MODEL_ID', 'amazon.titan-embed-text-v2:0')
      end

      def generate(input)
        params = {
          body: {
            inputText: input,
            dimensions: 1024,
            embeddingTypes: ['float']
          }.to_json,
          content_type: 'application/json',
          accept: 'application/json',
          model_id: model_id
        }

        response = bedrock.invoke_model(**params)
        json = JSON.parse(response.body.read)

        json['embedding']
      rescue StandardError => e
        raise Embedding::GenerationError, "Unable to generate an embedding using Amazon Bedrock"
      end

      private

      def bedrock
        @bedrock ||= Aws::BedrockRuntime::Client.new
      end
    end

    class OpenAI
      with_options instance_writer: false do
        class_attribute :model_id, default: ENV.fetch('OPENAI_MODEL_ID', 'text-embedding-3-small')
      end

      def generate(input)
        params = {
          input: input,
          model: model_id,
          dimensions: 1024,
          encoding_format: 'float'
        }

        response = client.embeddings.create(params)
        response.data.first.embedding
      rescue StandardError => e
        raise Embedding::GenerationError, "Unable to generate an embedding using OpenAI"
      end

      private

      def client
        @client ||= ::OpenAI::Client.new
      end
    end
  end

  class << self
    def generate(input)
      cache(input) do
        client.generate(input)
      end
    end

    def backend
      Backends.const_get(ENV.fetch('EMBEDDING_BACKEND', 'OpenAI'))
    end

    def client
      Thread.current[:__embedding__] ||= backend.new
    end

    def reload
      Thread.current[:__embedding__] = nil
    end

    private

    def cache(input, &block)
      Rails.cache.fetch(cache_key(input), &block)
    end

    def cache_key(input)
      [:embedding, normalize(input)]
    end

    def normalize(input)
      input.to_s.parameterize
    end
  end
end
