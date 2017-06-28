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
    end
  end

  describe "class methods" do
    let!(:taggable_record_a) { taggable.create(tags: ["tag 1", "tag 2"]) }
    let!(:taggable_record_b) { taggable.create(tags: ["tag 1", "tag 3"]) }
    let!(:taggable_record_c) { taggable.create(tags: ["tag 1", "tag 2", "tag 3"]) }

    let(:tags_query) { ["tag 1", "tag 2"] }

    describe ".with_all_tags" do
      it "fetches records tagged with all tags in the query" do
        expect(taggable.with_all_tags(tags_query)).to be_an(ActiveRecord::Relation)
        expect(taggable.with_all_tags(tags_query)).to match_array [taggable_record_a, taggable_record_c]
      end
    end

    describe "all_tags" do
      it "returns all tags being used on taggable records" do
        expect(taggable.all_tags).to match_array ["tag 1", "tag 2", "tag 3"]
      end
    end

    describe "with_tag" do
      it "returns all records tagged with tag" do
        expect(taggable.with_tag("tag 3")).to match_array [taggable_record_b, taggable_record_c]
      end
    end

    describe "taggable?" do
      it "returns true" do
        expect(taggable.taggable?).to eq true
      end
    end
  end

  describe "instance methods" do
    describe "including the module" do
      describe "tags validation" do
        let(:taggable_record) { taggable.create }

        it "validates tags can be set as an array" do
          taggable_record.tags = ["tag 1", "tag 2"]
          expect(taggable_record).to be_valid
        end

        it "validates tags can be empty" do
          taggable_record.tags = ""
          expect(taggable_record).to be_valid
        end

        it "validates tags can not be nil" do
          taggable_record.class.class_eval do
            def self.model_name
              ActiveModel::Name.new(self, nil, "temp")
            end
          end

          taggable_record.tags = nil
          expect(taggable_record).to be_invalid
        end
      end
    end

    describe "#tags=" do
      let(:taggable_record) { taggable.create }

      context "tags includes empty strings" do
        it "removes empty strings from the array" do
          taggable_record.tags = ["", "tag 1"]
          expect(taggable_record).to be_valid
          expect(taggable_record.tags).to eq ["tag 1"]
        end
      end

      context "tags is a string" do
        it "raises a TypeError with helpful message" do
          expect{ taggable_record.tags = "tag 1\ntag 2" }.to raise_error(TypeError)
            .with_message("All strings are converted to an empty tags array. Are you sure you didn't mean [\"tag 1\", \"tag 2\"]?")
        end

        context "tags is an empty string" do
          it "does not attempt to remove empty strings or raise a TypeError" do
            expect{ taggable_record.tags = "" }.not_to raise_error
          end
        end
      end

      context "tags is nil" do
        it "does not raise an error" do
          expect{ taggable_record.tags = nil }.not_to raise_error
        end
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
