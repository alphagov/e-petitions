RSpec.shared_examples_for "a model with topics" do
  let(:table_name) { described_class.table_name }
  let(:connection) { described_class.connection }
  let(:indexes) { connection.indexes(table_name) }
  let(:index) { indexes.detect { |i| i.name == "index_#{table_name}_on_topics" } }

  it { is_expected.to have_db_column(:topics).of_type(:integer).with_options(null: false, default: []) }

  it "indexes the topics column using a gin index" do
    expect(index).to be_present
    expect(index.using).to eq(:gin)
  end

  it "validates the existence of the topics" do
    subject.update(topics: [999])
    expect(subject.errors[:topics]).to eq(["The submitted topics were invalid - please reselect and try again"])
  end

  let(:factory) { described_class.model_name.singular.to_sym }

  describe ".for_topic" do
    let!(:topic_1) { FactoryBot.create(:topic) }
    let!(:topic_2) { FactoryBot.create(:topic) }
    let!(:model_1) { FactoryBot.create(factory, topics: []) }
    let!(:model_2) { FactoryBot.create(factory, topics: [topic_1.id]) }
    let!(:model_3) { FactoryBot.create(factory, topics: [topic_1.id, topic_2.id]) }
    let!(:model_4) { FactoryBot.create(factory, topics: [topic_2.id]) }

    context "when using no topics" do
      it "returns all models" do
        expect(described_class.for_topic([])).to include(model_1, model_2, model_3, model_4)
      end
    end

    context "when using one topic" do
      it "returns all models assigned to that topic" do
        expect(described_class.for_topic([topic_1.id])).to include(model_2, model_3)
      end

      it "doesn't return models that aren't assigned to that topic" do
        expect(described_class.for_topic([topic_1.id])).not_to include(model_4)
      end

      it "doesn't return models that are unassigned" do
        expect(described_class.for_topic([topic_1.id])).not_to include(model_1)
      end
    end

    context "when using multiple topics" do
      it "returns all models assigned to both topics" do
        expect(described_class.for_topic([topic_1.id, topic_2.id])).to include(model_3)
      end

      it "doesn't return models that are assigned to only one of the topics" do
        expect(described_class.for_topic([topic_1.id, topic_2.id])).not_to include(model_2, model_4)
      end

      it "doesn't return models that are unassigned" do
        expect(described_class.for_topic([topic_1.id, topic_2.id])).not_to include(model_1)
      end
    end
  end

  describe ".all_topics" do
    let!(:topic_1) { FactoryBot.create(:topic) }
    let!(:topic_2) { FactoryBot.create(:topic) }
    let!(:model_1) { FactoryBot.create(factory, topics: []) }
    let!(:model_2) { FactoryBot.create(factory, topics: [topic_1.id]) }
    let!(:model_3) { FactoryBot.create(factory, topics: [topic_1.id, topic_2.id]) }
    let!(:model_4) { FactoryBot.create(factory, topics: [topic_2.id]) }

    context "when using no topics" do
      it "returns all models" do
        expect(described_class.for_topic([])).to include(model_1, model_2, model_3, model_4)
      end
    end

    context "when using one topic" do
      it "returns all models assigned to that topic" do
        expect(described_class.all_topics([topic_1.id])).to include(model_2, model_3)
      end

      it "doesn't return models that aren't assigned to that topic" do
        expect(described_class.all_topics([topic_1.id])).not_to include(model_4)
      end

      it "doesn't return models that are unassigned" do
        expect(described_class.all_topics([topic_1.id])).not_to include(model_1)
      end
    end

    context "when using multiple topics" do
      it "returns all models assigned to both topics" do
        expect(described_class.all_topics([topic_1.id, topic_2.id])).to include(model_3)
      end

      it "doesn't return models that are assigned to only one of the topics" do
        expect(described_class.all_topics([topic_1.id, topic_2.id])).not_to include(model_2, model_4)
      end

      it "doesn't return models that are unassigned" do
        expect(described_class.all_topics([topic_1.id, topic_2.id])).not_to include(model_1)
      end
    end
  end

  describe ".any_topics" do
    let!(:topic_1) { FactoryBot.create(:topic) }
    let!(:topic_2) { FactoryBot.create(:topic) }
    let!(:model_1) { FactoryBot.create(factory, topics: []) }
    let!(:model_2) { FactoryBot.create(factory, topics: [topic_1.id]) }
    let!(:model_3) { FactoryBot.create(factory, topics: [topic_1.id, topic_2.id]) }
    let!(:model_4) { FactoryBot.create(factory, topics: [topic_2.id]) }

    context "when using no topics" do
      it "returns no models" do
        expect(described_class.any_topics([])).to be_empty
      end
    end

    context "when using one topic" do
      it "returns all models assigned to that topic" do
        expect(described_class.any_topics([topic_1.id])).to include(model_2, model_3)
      end

      it "doesn't return models that aren't assigned to that topic" do
        expect(described_class.any_topics([topic_1.id])).not_to include(model_4)
      end

      it "doesn't return models that are unassigned" do
        expect(described_class.any_topics([topic_1.id])).not_to include(model_1)
      end
    end

    context "when using multiple topics" do
      it "returns all models assigned to both topics" do
        expect(described_class.any_topics([topic_1.id, topic_2.id])).to include(model_3)
      end

      it "returns models that are assigned with only one of the topics" do
        expect(described_class.any_topics([topic_1.id, topic_2.id])).to include(model_2, model_4)
      end

      it "doesn't return models that are unassigned" do
        expect(described_class.any_topics([topic_1.id, topic_2.id])).not_to include(model_1)
      end
    end
  end

  describe ".with_topic" do
    let!(:topic) { FactoryBot.create(:topic) }
    let!(:model_1) { FactoryBot.create(factory, topics: [topic.id]) }
    let!(:model_2) { FactoryBot.create(factory, topics: []) }

    it "returns assigned models" do
      expect(described_class.with_topic).to include(model_1)
    end

    it "doesn't return unassigned models" do
      expect(described_class.with_topic).not_to include(model_2)
    end
  end

  describe ".without_topic" do
    let!(:topic) { FactoryBot.create(:topic) }
    let!(:model_1) { FactoryBot.create(factory, topics: []) }
    let!(:model_2) { FactoryBot.create(factory, topics: [topic.id]) }

    it "returns unassigned models" do
      expect(described_class.without_topic).to include(model_1)
    end

    it "doesn't return assigned models" do
      expect(described_class.without_topic).not_to include(model_2)
    end
  end

  describe ".normalize_topics" do
    it "removes non-numeric strings" do
      expect(described_class.normalize_topics(["foo"])).to eq([])
    end

    it "removes zero strings" do
      expect(described_class.normalize_topics(["0"])).to eq([])
    end

    it "removes nil values" do
      expect(described_class.normalize_topics([nil])).to eq([])
    end

    it "converts strings to integers" do
      expect(described_class.normalize_topics(["1"])).to eq([1])
    end
  end

  describe ".normalize_topic_codes" do
    it "downcases strings" do
      expect(described_class.normalize_topic_codes("Covid-19")).to eq(%w[covid-19])
    end

    it "strips strings" do
      expect(described_class.normalize_topic_codes(" covid-19 ")).to eq(%w[covid-19])
    end

    it "removes blank strings" do
      expect(described_class.normalize_topic_codes(["covid-19", ""])).to eq(%w[covid-19])
    end
  end

  describe ".topics" do
    context "when no topics are given" do
      let!(:topic) { FactoryBot.create(:topic, code: "covid-19", name: "COVID-19") }
      let!(:petition_1) { FactoryBot.create(factory, topics: [topic.id]) }
      let!(:petition_2) { FactoryBot.create(factory, topics: []) }

      it "returns all petitions" do
        expect(described_class.topics("")).to include(petition_1, petition_2)
      end
    end

    context "when the topic doesn't exist" do
      let!(:petition_1) { FactoryBot.create(factory, topics: []) }
      let!(:petition_2) { FactoryBot.create(factory, topics: []) }

      it "returns an empty result" do
        expect(described_class.topics("covid-19")).to be_empty
      end
    end

    context "when the topic exists" do
      let!(:topic) { FactoryBot.create(:topic, code: "covid-19", name: "COVID-19") }
      let!(:petition_1) { FactoryBot.create(factory, topics: [topic.id]) }
      let!(:petition_2) { FactoryBot.create(factory, topics: []) }

      it "returns a petition with that topic" do
        expect(described_class.topics("covid-19")).to include(petition_1)
      end

      it "doesn't return a petition without that topic" do
        expect(described_class.topics("covid-19")).not_to include(petition_2)
      end
    end
  end

  describe "#normalize_topics" do
    it "delegates to the class method" do
      expect(described_class).to receive(:normalize_topics).with(["foo"]).and_call_original
      expect(subject.normalize_topics(["foo"])).to eq([])
    end
  end

  describe "#topics=" do
    it "normalizes topic values" do
      subject.topics = ["foo", nil, "0", 0, "1", 2]
      expect(subject.topics).to eq([1, 2])
    end
  end
end
