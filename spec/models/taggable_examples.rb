RSpec.shared_examples_for "a taggable model" do
  let(:table_name) { described_class.table_name }
  let(:connection) { described_class.connection }
  let(:indexes) { connection.indexes(table_name) }
  let(:index) { indexes.detect { |i| i.name == "index_#{table_name}_on_tags" } }

  it { is_expected.to have_db_column(:tags).of_type(:integer).with_options(array: true, null: false, default: []) }

  it "indexes the tags column using a gin index" do
    expect(index).to be_present
    expect(index.using).to eq(:gin)
  end

  it "validates the existence of the tags" do
    subject.update(tags: [999])
    expect(subject.errors[:tags]).to eq(["The submitted tags were invalid - please reselect and try again"])
  end

  let(:factory) { described_class.model_name.singular.to_sym }

  describe ".tagged_with" do
    let!(:tag_1) { FactoryBot.create(:tag) }
    let!(:tag_2) { FactoryBot.create(:tag) }
    let!(:model_1) { FactoryBot.create(factory, tags: []) }
    let!(:model_2) { FactoryBot.create(factory, tags: [tag_1.id]) }
    let!(:model_3) { FactoryBot.create(factory, tags: [tag_1.id, tag_2.id]) }
    let!(:model_4) { FactoryBot.create(factory, tags: [tag_2.id]) }

    context "when using no tags" do
      it "returns all models" do
        expect(described_class.tagged_with([])).to include(model_1, model_2, model_3, model_4)
      end
    end

    context "when using one tag" do
      it "returns all models tagged with that tag" do
        expect(described_class.tagged_with([tag_1.id])).to include(model_2, model_3)
      end

      it "doesn't return models that aren't tagged with that tag" do
        expect(described_class.tagged_with([tag_1.id])).not_to include(model_4)
      end

      it "doesn't return models that are untagged" do
        expect(described_class.tagged_with([tag_1.id])).not_to include(model_1)
      end
    end

    context "when using multiple tags" do
      it "returns all models tagged with both tags" do
        expect(described_class.tagged_with([tag_1.id, tag_2.id])).to include(model_3)
      end

      it "doesn't return models that are tagged with only one of the tags" do
        expect(described_class.tagged_with([tag_1.id, tag_2.id])).not_to include(model_2, model_4)
      end

      it "doesn't return models that are untagged" do
        expect(described_class.tagged_with([tag_1.id, tag_2.id])).not_to include(model_1)
      end
    end
  end

  describe ".tagged_with_all" do
    let!(:tag_1) { FactoryBot.create(:tag) }
    let!(:tag_2) { FactoryBot.create(:tag) }
    let!(:model_1) { FactoryBot.create(factory, tags: []) }
    let!(:model_2) { FactoryBot.create(factory, tags: [tag_1.id]) }
    let!(:model_3) { FactoryBot.create(factory, tags: [tag_1.id, tag_2.id]) }
    let!(:model_4) { FactoryBot.create(factory, tags: [tag_2.id]) }

    context "when using no tags" do
      it "returns all models" do
        expect(described_class.tagged_with_all([])).to include(model_1, model_2, model_3, model_4)
      end
    end

    context "when using one tag" do
      it "returns all models tagged with that tag" do
        expect(described_class.tagged_with_all([tag_1.id])).to include(model_2, model_3)
      end

      it "doesn't return models that aren't tagged with that tag" do
        expect(described_class.tagged_with_all([tag_1.id])).not_to include(model_4)
      end

      it "doesn't return models that are untagged" do
        expect(described_class.tagged_with_all([tag_1.id])).not_to include(model_1)
      end
    end

    context "when using multiple tags" do
      it "returns all models tagged with both tags" do
        expect(described_class.tagged_with_all([tag_1.id, tag_2.id])).to include(model_3)
      end

      it "doesn't return models that are tagged with only one of the tags" do
        expect(described_class.tagged_with_all([tag_1.id, tag_2.id])).not_to include(model_2, model_4)
      end

      it "doesn't return models that are untagged" do
        expect(described_class.tagged_with_all([tag_1.id, tag_2.id])).not_to include(model_1)
      end
    end
  end

  describe ".tagged_with_any" do
    let!(:tag_1) { FactoryBot.create(:tag) }
    let!(:tag_2) { FactoryBot.create(:tag) }
    let!(:model_1) { FactoryBot.create(factory, tags: []) }
    let!(:model_2) { FactoryBot.create(factory, tags: [tag_1.id]) }
    let!(:model_3) { FactoryBot.create(factory, tags: [tag_1.id, tag_2.id]) }
    let!(:model_4) { FactoryBot.create(factory, tags: [tag_2.id]) }

    context "when using no tags" do
      it "returns no models" do
        expect(described_class.tagged_with_any([])).to be_empty
      end
    end

    context "when using one tag" do
      it "returns all models tagged with that tag" do
        expect(described_class.tagged_with_any([tag_1.id])).to include(model_2, model_3)
      end

      it "doesn't return models that aren't tagged with that tag" do
        expect(described_class.tagged_with_any([tag_1.id])).not_to include(model_4)
      end

      it "doesn't return models that are untagged" do
        expect(described_class.tagged_with_any([tag_1.id])).not_to include(model_1)
      end
    end

    context "when using multiple tags" do
      it "returns all models tagged with both tags" do
        expect(described_class.tagged_with_any([tag_1.id, tag_2.id])).to include(model_3)
      end

      it "returns models that are tagged with only one of the tags" do
        expect(described_class.tagged_with_any([tag_1.id, tag_2.id])).to include(model_2, model_4)
      end

      it "doesn't return models that are untagged" do
        expect(described_class.tagged_with_any([tag_1.id, tag_2.id])).not_to include(model_1)
      end
    end
  end

  describe ".untagged" do
    let!(:tag) { FactoryBot.create(:tag) }
    let!(:model_1) { FactoryBot.create(factory, tags: []) }
    let!(:model_2) { FactoryBot.create(factory, tags: [tag.id]) }

    it "returns untagged models" do
      expect(described_class.untagged).to include(model_1)
    end

    it "doesn't return tagged models" do
      expect(described_class.untagged).not_to include(model_2)
    end
  end

  describe ".normalize_tags" do
    it "removes non-numeric strings" do
      expect(described_class.normalize_tags(["foo"])).to eq([])
    end

    it "removes zero strings" do
      expect(described_class.normalize_tags(["0"])).to eq([])
    end

    it "removes nil values" do
      expect(described_class.normalize_tags([nil])).to eq([])
    end

    it "converts strings to integers" do
      expect(described_class.normalize_tags(["1"])).to eq([1])
    end
  end

  describe "#normalize_tags" do
    it "delegates to the class method" do
      expect(described_class).to receive(:normalize_tags).with(["foo"]).and_call_original
      expect(subject.normalize_tags(["foo"])).to eq([])
    end
  end

  describe "#tags=" do
    it "normalizes tag values" do
      subject.tags = ["foo", nil, "0", 0, "1", 2]
      expect(subject.tags).to eq([1, 2])
    end
  end

  describe "#tag_names" do
    before do
      foo = FactoryBot.create(:tag, name: "Foo")
      bar = FactoryBot.create(:tag, name: "Bar")

      subject.tags = [foo.id, bar.id]
    end

    it "returns the array of tag names" do
      expect(subject.tag_names).to eq(%w[Foo Bar])
    end
  end
end
