require 'rails_helper'

RSpec.describe Taggable, type: :model do
  before(:all) do
    create_table
  end

  after(:all) do
    drop_table
  end

  let(:taggable) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "taggable_table"

      include Taggable
      acts_as_taggable_array_on :tags
    end
  end

  let(:taggable_default) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "taggable_table"

      include Taggable
    end
  end

  describe "class methods" do
    let!(:taggable_record_a) { taggable.create(tags: ["tag 1", "tag 2"]) }
    let!(:taggable_record_b) { taggable.create(tags: ["tag 1", "tag 3"]) }
    let!(:taggable_record_c) { taggable.create(tags: ["tag 1", "tag 2", "tag 3"]) }

    let(:tags_query) { ["tag 1", "tag 2"] }

    describe "including the module" do
      it "adds a tag_column class attribute" do
        expect(taggable).to respond_to(:tag_column)
      end

      it "defaults tag_column to :tags" do
        expect(taggable_default.tag_column).to eq :tags
      end
    end

    describe ".acts_as_taggable_array_on" do
      it "sets the tag_column class attribute" do
        taggable.acts_as_taggable_array_on :categories
        expect(taggable.tag_column).to eq :categories
      end
    end

    describe ".with_all" do
      it "fetches records tagged with all tags in the query" do
        expect(taggable.with_all_tags(tags_query)).to be_an(ActiveRecord::Relation)
        expect(taggable.with_all_tags(tags_query)).to eq [taggable_record_a, taggable_record_c]
      end
    end

    describe "all_tags" do
      it "returns all tags being used on taggable records" do
        expect(taggable.all_tags).to match_array ["tag 1", "tag 2", "tag 3"]
      end
    end

    describe "taggable?" do
      it "returns true" do
        expect(taggable.taggable?).to eq true
      end
    end
  end

  describe "instance methods" do
    let(:taggable_record) { taggable.create(tags: ["TAG 1", "tAg 2", "tAG 3"]) }

    describe "tags_for_comparison" do
      it "returns the records tags in downcase" do
        expect(taggable_record.tags_for_comparison).to eq ["tag 1", "tag 2", "tag 3"]
      end
    end
  end

  def create_table
    ActiveRecord::Base.connection.create_table :taggable_table do |t|
      t.column :tags, :string, array: true, default: '{}'
    end
  end

  def drop_table
    ActiveRecord::Base.connection.drop_table :taggable_table
  end
end
