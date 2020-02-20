require 'rails_helper'

RSpec.describe Language, type: :model do
  describe "schema" do
    it { is_expected.to have_db_column(:locale).of_type(:string).with_options(limit: 10, null: false) }
    it { is_expected.to have_db_column(:name).of_type(:string).with_options(limit: 30, null: false) }
    it { is_expected.to have_db_column(:translations).of_type(:jsonb).with_options(null: false, default: {}) }
    it { is_expected.to have_db_column(:created_at).of_type(:datetime).with_options(null: false) }
    it { is_expected.to have_db_column(:updated_at).of_type(:datetime).with_options(null: false) }
  end

  describe "indexes" do
    it { is_expected.to have_db_index([:locale]).unique }
    it { is_expected.to have_db_index([:name]) }
  end

  describe "scopes" do
    describe "by_name" do
      let!(:welsh) { FactoryBot.create(:language, :welsh) }
      let!(:english) { FactoryBot.create(:language, :english) }

      it "returns languages in alphabetical order" do
        expect(Language.by_name).to eq([english, welsh])
      end
    end
  end

  describe ".available_locales" do
    let!(:welsh) { FactoryBot.create(:language, :welsh) }
    let!(:english) { FactoryBot.create(:language, :english) }

    it "returns an array of symbols" do
      expect(Language.available_locales).to eq(%i[en-GB cy-GB])
    end
  end

  describe ".lookup" do
    let!(:language) { FactoryBot.create(:language, :english) }

    context "when the locale doesn't exist" do
      let(:arguments) { [:"cy-GB", :title, [], {}] }

      it "returns nil" do
        expect(Language).to receive(:find_by).with(locale: :"cy-GB").and_return(nil)
        expect(Language.lookup(*arguments)).to be_nil
      end
    end

    context "when the locale does exist" do
      let(:arguments) { [:"en-GB", :title, [], {}] }

      it "delegates to the language instance" do
        expect(Language).to receive(:find_by).with(locale: :"en-GB").and_return(language)
        expect(language).to receive(:lookup).with(*arguments).and_return("Welsh Petitions")
        expect(Language.lookup(*arguments)).to eq("Welsh Petitions")
      end
    end
  end

  describe ".reload" do
    let(:language) { FactoryBot.create(:language, :english) }

    context "when it is cached in Thread.current" do
      before do
        Thread.current[:__languages__] = { "en-GB" => language }
      end

      it "clears the cached instance in Thread.current" do
        expect{ Language.reload_translations }.to change {
          Thread.current[:__languages__]
        }.from("en-GB" => language).to(nil)
      end
    end
  end

  describe ".before_remove_const" do
    let(:language) { FactoryBot.create(:language, :english) }

    context "when it is cached in Thread.current" do
      before do
        Thread.current[:__languages__] = { "en-GB" => language }
      end

      it "clears the cached instance in Thread.current" do
        expect{ Language.before_remove_const }.to change {
          Thread.current[:__languages__]
        }.from("en-GB" => language).to(nil)
      end
    end
  end

  describe "#reload_translations" do
    let(:language) { FactoryBot.create(:language, :english) }
    let(:yaml_file) { Rails.root.join("config", "locales", "ui.en-GB.yml") }

    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(yaml_file).and_return <<~YAML
        en-GB:
          title: "Welsh Petitions"
      YAML
    end

    it "reloads the YAML file for the locale" do
      expect {
        language.reload_translations
      }.to change {
        language.translations
      }.from(
        "en-GB" => { "title" => "Petitions" }
      ).to(
        "en-GB" => { "title" => "Welsh Petitions" }
      )
    end
  end

  describe "#key?" do
    let(:language) { FactoryBot.create(:language, :english) }

    context "when the key exists" do
      it "returns true" do
        expect(language.key?(:title)).to eq(true)
      end
    end

    context "when the key doesn't exist" do
      it "returns false" do
        expect(language.key?(:strapline)).to eq(false)
      end
    end
  end

  describe "#translated?" do
    let!(:english) { FactoryBot.create(:language, :english) }
    let!(:welsh) { FactoryBot.create(:language, :welsh) }

    context "when the key exists in the other language" do
      it "returns true" do
        expect(english.translated?(:title)).to eq(true)
      end
    end

    context "when the key doesn't exist in the other language" do
      it "returns false" do
        expect(english.translated?(:strapline)).to eq(false)
      end
    end
  end

  describe "#changed?" do
    let!(:language) { FactoryBot.create(:language, :english, translations: translations) }

    around do |example|
      backend = I18n.backend
      I18n.backend = I18n::Backend::Chain.new(backend)

      example.run
    ensure
      I18n.backend = backend
    end

    context "when the key doesn't exist" do
      let(:translations) do
        { "en-GB" => {} }
      end

      it "returns false" do
        expect(language.changed?("ui.header.title")).to be_falsey
      end
    end

    context "when the key exists but is the same as in the YAML file" do
      let(:translations) do
        {  "en-GB" => { "ui" => { "header" => { "title" => "Petitions" } } } }
      end

      it "returns false" do
        expect(language.changed?("ui.header.title")).to be_falsey
      end
    end

    context "when the key exists and is different from the YAML file" do
      let(:translations) do
        { "en-GB" => { "ui" => { "header" => { "title" => "Welsh Petitions" } } } }
      end

      it "returns true" do
        expect(language.changed?("ui.header.title")).to be_truthy
      end
    end
  end

  describe "#get" do
    let(:language) { FactoryBot.create(:language, :english, translations: translations) }
    let(:translations) do
      { "en-GB" => { "header" => { "title" => "Welsh Petitions" } } }
    end

    it "returns the translation for the key" do
      expect(language.get("header.title")).to eq("Welsh Petitions")
    end
  end

  describe "#set" do
    let(:language) { FactoryBot.create(:language, :english, translations: {}) }

    it "sets the translation for the key but doesn't save it" do
      expect {
        language.set("header.title", "Welsh Petitions")
      }.to change {
        language.translations
      }.from({}).to(
        { "en-GB" => { "header" => { "title" => "Welsh Petitions" } } }
      )

      language.reload
      expect(language.translations).to eq({})
    end
  end

  describe "#set!" do
    let(:language) { FactoryBot.create(:language, :english, translations: {}) }

    it "sets and saves the translation for the key" do
      expect {
        language.set!("header.title", "Welsh Petitions")
      }.to change {
        language.translations
      }.from({}).to(
        { "en-GB" => { "header" => { "title" => "Welsh Petitions" } } }
      )

      language.reload
      expect(language.translations).to eq(
        { "en-GB" => { "header" => { "title" => "Welsh Petitions" } } }
      )
    end
  end

  describe "#delete" do
    let(:language) { FactoryBot.create(:language, :english, translations: translations) }
    let(:translations) do
      { "en-GB" => { "header" => { "title" => "Welsh Petitions" } } }
    end

    it "deletes the translation for the key but doesn't save it" do
      expect {
       language.delete("header.title")
      }.to change {
        language.translations.deep_dup
      }.from(translations).to(
        { "en-GB" => { "header" => { } } }
      )

      language.reload
      expect(language.translations).to eq(translations)
    end
  end

  describe "#delete!" do
    let(:language) { FactoryBot.create(:language, :english, translations: translations) }
    let(:translations) do
      { "en-GB" => { "header" => { "title" => "Welsh Petitions" } } }
    end

    it "deletes the translation for the key and saves it" do
      expect {
       language.delete!("header.title")
      }.to change {
        language.translations.deep_dup
      }.from(translations).to(
        { "en-GB" => { "header" => { } } }
      )

      language.reload
      expect(language.translations).to eq(
        { "en-GB" => { "header" => { } } }
      )
    end
  end

  describe "#flatten" do
    let(:language) { FactoryBot.create(:language, :english, translations: translations) }
    let(:translations) do
      { "en-GB" => { "header" => { "title" => "Petitions", "strapline" => "Senedd" } } }
    end

    it "returns a flattened hash" do
      expect(language.flatten).to eq(
        "header.title" => "Petitions",
        "header.strapline" => "Senedd"
      )
    end
  end

  describe "#keys" do
    let(:language) { FactoryBot.create(:language, :english, translations: translations) }
    let(:translations) do
      { "en-GB" => { "header" => { "title" => "Petitions", "strapline" => "Senedd" } } }
    end

    it "returns a sorted list of flattened keys" do
      expect(language.keys).to eq %w[
        header.strapline
        header.title
      ]
    end
  end

  describe "#lookup" do
    let(:language) { FactoryBot.create(:language, :english, translations: translations) }
    let(:translations) do
      {
        "en-GB" => {
          "header" => { "title" => "Welsh Petitions" },
          "signature_count" => { "one" => "1 signature", "other" => "%{count} signatures" }
        }
      }
    end

    context "a nested key" do
      context "when it doesn't exist" do
        it "returns nil" do
          expect(language.lookup(:"en-GB", :"header.strapline", [], {})).to be_nil
        end
      end

      context "when it does exist" do
        it "returns nil" do
          expect(language.lookup(:"en-GB", :"header.title", [], {})).to eq("Welsh Petitions")
        end
      end
    end

    context "a scoped key" do
      context "when it doesn't exist" do
        it "returns nil" do
          expect(language.lookup(:"en-GB", :strapline, :header, {})).to be_nil
        end
      end

      context "when it does exist" do
        it "returns nil" do
          expect(language.lookup(:"en-GB", :title, :header, {})).to eq("Welsh Petitions")
        end
      end
    end

    context "a key that returns a hash" do
      it "returns a hash with symbol keys" do
        expect(language.lookup(:"en-GB", :signature_count, [], {})).to eq(one: "1 signature", other: "%{count} signatures")
      end
    end
  end

  describe "#english?" do
    context "when the locale is English" do
      let(:language) { FactoryBot.create(:language, :english) }

      it "returns true" do
        expect(language.english?).to eq(true)
      end
    end

    context "when the locale is Welsh" do
      let(:language) { FactoryBot.create(:language, :welsh) }

      it "returns false" do
        expect(language.english?).to eq(false)
      end
    end
  end

  describe "#welsh?" do
    context "when the locale is English" do
      let(:language) { FactoryBot.create(:language, :english) }

      it "returns false" do
        expect(language.welsh?).to eq(false)
      end
    end

    context "when the locale is Welsh" do
      let(:language) { FactoryBot.create(:language, :welsh) }

      it "returns true" do
        expect(language.welsh?).to eq(true)
      end
    end
  end
end
