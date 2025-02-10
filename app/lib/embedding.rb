require 'faraday'
require 'aws-sdk-bedrockruntime'

module Embedding
  class GenerationError < RuntimeError; end

  module Backends
    class Ollama
      with_options instance_writer: false do
        class_attribute :url, default: ENV.fetch('OLLAMA_URL', 'http://127.0.0.1:11434')
        class_attribute :path, default: '/api/embed'
        class_attribute :model, default: ENV.fetch('OLLAMA_MODEL', 'mxbai-embed-large')
        class_attribute :headers, default: { content_type: 'application/json' }
        class_attribute :open_timeout, default: 5
        class_attribute :timeout, default: 5
      end

      def generate(input)
        body = { input: input, model: model }.to_json

        response = faraday.post(path, body, headers) do |request|
          request.options[:timeout] = timeout
          request.options[:open_timeout] = open_timeout
        end

        response.body.fetch('embeddings').first
      rescue StandardError => e
        raise Embedding::GenerationError, "Unable to generate an embedding using Ollama"
      end

      private

      def faraday
        @faraday ||= Faraday.new(url) do |f|
          f.response :follow_redirects
          f.response :json
          f.response :raise_error
          f.adapter :net_http_persistent
        end
      end
    end

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
  end

  class << self
    def generate(input)
      client.generate(input)
    end

    def backend
      Backends.const_get(ENV.fetch('EMBEDDING_BACKEND', 'Ollama'))
    end

    def client
      Thread.current[:__embedding__] ||= backend.new
    end

    def reload
      Thread.current[:__embedding__] = nil
    end
  end
end
