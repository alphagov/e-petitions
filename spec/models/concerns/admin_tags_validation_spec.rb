require 'rails_helper'

RSpec.describe AdminTagsValidation, type: :model do
  before(:all) do
    create_table
  end

  after(:all) do
    drop_table
  end

  let(:admin_tags_validation_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = "admin_tags_validation_table"

      include AdminTagsValidation
    end
  end

  let(:admin_tags_validation_record) { admin_tags_validation_class.create }

  describe "tags validations" do
    let(:site_settings) { Admin::Site.create(petition_tags: "tag 1\ntag 2") }

    before do
      set_site_settings
    end

    describe "#tags_must_be_allowed" do
      context "with allowed tags" do
        it "record is valid" do
          admin_tags_validation_record.tags << "tag 1"
          admin_tags_validation_record.tags << "tag 2"
          expect(admin_tags_validation_record).to be_valid
        end
      end

      context "with disallowed tags" do
        it "record is invalid" do
          admin_tags_validation_record.tags << "tag 3"
          expect(admin_tags_validation_record).to be_invalid
        end

        it "displays an error message with the disallowed tags" do
          admin_tags_validation_record.tags << "tag 3"
          admin_tags_validation_record.tags << "tag 4"
          admin_tags_validation_record.valid?
          expect(admin_tags_validation_record.errors.messages[:tags]).to include "Disallowed tags: 'tag 3', 'tag 4'"
        end
      end
    end
  end

  describe "#tags_for_comparison" do
    let(:admin_tags_validation_record) { admin_tags_validation_class.create(tags: ["TAG 1", "tAg 2", "tAG 3"]) }

    it "returns the records tags in downcase" do
      expect(admin_tags_validation_record.tags_for_comparison).to eq ["tag 1", "tag 2", "tag 3"]
    end
  end

  def set_site_settings
    allow(Admin::Site).to receive(:first).and_return site_settings
  end

  def create_table
    ActiveRecord::Base.connection.create_table :admin_tags_validation_table do |t|
      t.column :tags, :string, array: true, default: '{}'
    end
  end

  def drop_table
    ActiveRecord::Base.connection.drop_table :admin_tags_validation_table
  end
end
