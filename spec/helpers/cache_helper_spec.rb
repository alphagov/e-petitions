require 'rails_helper'

RSpec.describe CacheHelper, type: :helper do
  describe "dependencies" do
    let(:klass) { CacheHelper::CacheKey::Dependencies }
    let(:dependencies) { klass.new(fragments) }

    describe "#fetch" do
      let(:fragments) do
        {
          petition: { },
          status:   { dependencies: [:petition] },
          notes:    { dependencies: [:status] },
          outcome:  { dependencies: [:notes, :petition] }
        }
      end

      it "returns an array of dependencies" do
        expect(dependencies.for(:status)).to eq([:petition])
      end

      it "returns an nested dependencies" do
        expect(dependencies.for(:notes)).to eq([:status, :petition])
      end

      it "eliminates duplicate dependencies" do
        expect(dependencies.for(:outcome)).to eq([:notes, :status, :petition])
      end
    end
  end

  describe "keys" do
    let(:klass) { CacheHelper::CacheKey::Keys }
    let(:keys) { klass.new(helper) }

    describe "#archived_petition_page" do
      it "delegates to the template context" do
        expect(helper).to receive(:archived_petition_page?).and_return(true)
        expect(keys.archived_petition_page).to eq(true)
      end
    end

    describe "#create_petition_page" do
      it "delegates to the template context" do
        expect(helper).to receive(:create_petition_page?).and_return(true)
        expect(keys.create_petition_page).to eq(true)
      end
    end

    describe "#home_page" do
      it "delegates to the template context" do
        expect(helper).to receive(:home_page?).and_return(true)
        expect(keys.home_page).to eq(true)
      end
    end

    describe "#last_petition_created_at" do
      let(:now) { Time.current }

      it "delegates to the Site instance" do
        expect(Site).to receive(:last_petition_created_at).and_return(now)
        expect(keys.last_petition_created_at).to eq(now)
      end
    end

    describe "#last_signature_at" do
      let(:now) { Time.current }

      it "delegates to the template context" do
        expect(helper).to receive(:last_signature_at).and_return(now)
        expect(keys.last_signature_at).to eq(now)
      end
    end

    describe "#last_government_response_updated_at" do
      let(:now) { Time.current }

      it "delegates to the template context" do
        expect(helper).to receive(:last_government_response_updated_at).and_return(now)
        expect(keys.last_government_response_updated_at).to eq(now)
      end
    end

    describe "#last_debate_outcome_updated_at" do
      let(:now) { Time.current }

      it "delegates to the template context" do
        expect(helper).to receive(:last_debate_outcome_updated_at).and_return(now)
        expect(keys.last_debate_outcome_updated_at).to eq(now)
      end
    end

    describe "#page_title" do
      it "delegates to the template context" do
        expect(helper).to receive(:page_title).and_return("Petitions")
        expect(keys.page_title).to eq("Petitions")
      end
    end

    describe "#petition_page" do
      it "delegates to the template context" do
        expect(helper).to receive(:petition_page?).and_return(true)
        expect(keys.petition_page).to eq(true)
      end
    end

    describe "#petition" do
      context "when not on the petition show page" do
        before do
          expect(helper).to receive(:petition_page?).and_return(false)
        end

        it "returns nil" do
          expect(keys.petition).to be_nil
        end
      end

      context "when on the petition show page" do
        let(:petition) { double(:petition) }

        before do
          assign('petition', petition)
          expect(helper).to receive(:petition_page?).and_return(true)
        end

        it "returns the petition" do
          expect(keys.petition).to eq(petition)
        end
      end
    end

    describe "#reveal_response" do
      before do
        expect(helper).to receive(:params).and_return(params)
      end

      context "when 'reveal_response' is set to 'yes'" do
        let(:params) do
          { reveal_response: 'yes' }.with_indifferent_access
        end

        it "returns true" do
          expect(keys.reveal_response).to eq(true)
        end
      end

      context "when 'reveal_response' is set to 'no'" do
        let(:params) do
          { reveal_response: 'no' }.with_indifferent_access
        end

        it "returns false" do
          expect(keys.reveal_response).to eq(false)
        end
      end

      context "when 'reveal_response' is not set" do
        let(:params) do
          {}.with_indifferent_access
        end

        it "returns false" do
          expect(keys.reveal_response).to eq(false)
        end
      end
    end

    describe "#site_updated_at" do
      let(:now) { Time.current }

      it "delegates to the Site instance" do
        expect(Site).to receive(:updated_at).and_return(now)
        expect(keys.site_updated_at).to eq(now)
      end
    end

    describe "#url" do
      let(:request) { double(:request, original_url: "/petitions/123") }

      it "delegates to the request's original_url method" do
        expect(helper).to receive(:request).and_return(request)
        expect(keys.url).to eq("/petitions/123")
      end
    end

    describe "#method_missing" do
      it "returns an assigned variable in the template context" do
        assign('signature_count', 32)
        expect(keys.signature_count).to eq(32)
      end
    end

    describe "#for" do
      let(:last_signature_at) { "2015-07-08 09:00:00".in_time_zone }

      it "returns an array of key-value pairs" do
        assign('signature_count', 32)
        expect(keys.for([:signature_count])).to eq([[:signature_count, "32"]])
      end

      it "expands array values" do
        assign('signature_counts', [1, 2, 3])
        expect(keys.for([:signature_counts])).to eq([[:signature_counts, "1/2/3"]])
      end

      it "expands time values" do
        expect(helper).to receive(:last_signature_at).and_return(last_signature_at)
        expect(keys.for([:last_signature_at])).to eq([[:last_signature_at, "20150708090000000000000"]])
      end

      it "expands value that respond to cache_key" do
        assign('signature', double(:signature, cache_key: "signature/1-20150708090000000000000"))
        expect(keys.for([:signature])).to eq([[:signature, "signature/1-20150708090000000000000"]])
      end

      it "calls to_param otherwise" do
        assign('message', { foo: "bar" })
        expect(keys.for([:message])).to eq([[:message, "foo=bar"]])
      end
    end
  end

  describe "fragment" do
    let(:klass) { CacheHelper::CacheKey::Fragment }

    describe "#keys" do
      context "when there is no key information" do
        let(:fragment) { klass.new({}) }

        it "defaults to []" do
          expect(fragment.keys).to eq([])
        end
      end

      context "when there is key information" do
        let(:fragment) { klass.new({ keys: [:petition] }) }

        it "returns the keys from the hash" do
          expect(fragment.keys).to eq([:petition])
        end
      end
    end

    describe "#dependencies" do
      context "when there is no dependency information" do
        let(:fragment) { klass.new({}) }

        it "defaults to []" do
          expect(fragment.dependencies).to eq([])
        end
      end

      context "when there is dependency information" do
        let(:fragment) { klass.new({ dependencies: [:petition] }) }

        it "returns the dependencies from the hash" do
          expect(fragment.dependencies).to eq([:petition])
        end
      end
    end

    describe "#version" do
      context "when there is no version information" do
        let(:fragment) { klass.new({}) }

        it "defaults to 1" do
          expect(fragment.version).to eq(1)
        end
      end

      context "when there is version information" do
        let(:fragment) { klass.new({ version: 3 }) }

        it "returns the version from the hash" do
          expect(fragment.version).to eq(3)
        end
      end
    end

    describe "#options" do
      context "when there are no options" do
        let(:fragment) { klass.new({}) }

        it "defaults to {}" do
          expect(fragment.options).to eq({})
        end
      end

      context "when there are options" do
        let(:fragment) { klass.new({ options: { expires_in: 5.minutes } }) }

        it "returns the options from the hash" do
          expect(fragment.options).to eq({ expires_in: 5.minutes })
        end
      end
    end
  end

  describe "cache key" do
    let(:klass) { CacheHelper::CacheKey }
    let(:config) { Rails.root.join("config", "fragments.yml") }
    let(:yaml) { YAML.load(source) }
    let(:source) do
      <<-YAML.strip_heredoc
        head:
          keys:
            - :site_updated_at
          options:
            expires_in: 300
      YAML
    end

    describe ".build" do
      let(:now) { Time.current }
      let(:hash) { { site_updated_at: now.to_s(:nsec) } }
      let(:digest) { Digest::SHA1.hexdigest(hash.to_param) }

      before do
        CacheHelper::CacheKey.reset_fragments
        expect(YAML).to receive(:load_file).with(config).and_return(yaml)
        expect(Site).to receive(:updated_at).and_return(now)
      end

      after do
        CacheHelper::CacheKey.reset_fragments
      end

      it "builds a cache key and options pair" do
        expect(klass.build(helper, :head)).to eq(["head-1/#{digest}", {expires_in: 300}])
      end
    end
  end
end
