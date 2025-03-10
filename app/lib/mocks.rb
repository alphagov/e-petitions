module Mocks
  class << self
    def Mock(model)
      Class.new(model) do
        reflect_on_all_associations.each do |association|
          attr_accessor association.name
        end

        def model_name
          @_model_name ||= ActiveModel::Name.new(self, nil, self.class.name.gsub("Mocks::", ""))
        end

        def readonly?
          true
        end

        def encode_with(coder)
          attributes.each do |key, value|
            coder[key] = value
          end
        end

        def init_with(coder, &block)
          attributes = self.class._default_attributes.deep_dup

          coder.map.each do |key, value|
            if attributes.key?(key)
              attributes.write_from_database(key, value)
            else
              self.public_send(:"#{key}=", value)
            end
          end

          attributes.freeze

          init_with_attributes(attributes, false, &block)
        end
      end
    end

    def [](mock)
      mocks.fetch(mock)
    end

    def reset!
      @mocks = nil
    end

    private

    def mocks
      @mocks ||= YAML.unsafe_load(mocks_file).symbolize_keys
    end

    def mocks_file
      File.read(mocks_path)
    end

    def mocks_path
      Rails.root.join('config', 'email', 'mocks.yml')
    end
  end

  Feedback = Mock(::Feedback)
  Signature = Mock(::Signature)
  Petition = Mock(::Petition)
  Rejection = Mock(::Rejection)
  GovernmentResponse = Mock(::GovernmentResponse)
  DebateOutcome = Mock(::DebateOutcome)
  Petition::Email = Mock(::Petition::Email)
  Petition::Mailshot = Mock(::Petition::Mailshot)
  Parliament = Mock(::Parliament)
  PrivacyNotification = Mock(::PrivacyNotification)
  PrivacyNotification::Petitions = Struct.new(:sample, :remaining_count)

  module Archived; end

  Archived::Petition = Mock(::Archived::Petition)
  Archived::Signature = Mock(::Archived::Signature)
  Archived::GovernmentResponse = Mock(::Archived::GovernmentResponse)
  Archived::DebateOutcome = Mock(::Archived::DebateOutcome)
  Archived::Petition::Email = Mock(::Archived::Petition::Email)
  Archived::Petition::Mailshot = Mock(::Archived::Petition::Mailshot)

  private

  def mock(name)
    Mocks[name]
  end
end
