# == Schema Information
#
# Table name: system_settings
#
#  id          :integer(4)      not null, primary key
#  key         :string(64)      not null
#  value       :text
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#

require 'rails_helper'

describe SystemSetting do
  describe "validations" do
    before :each do
      @s = FactoryGirl.build(:system_setting)
    end

    it "should be valid" do
      expect(@s).to be_valid
    end

    describe "on key:" do
      it "not blank" do
        @s.key = ''
        expect(@s).not_to be_valid
        expect(@s.errors[:key]).not_to be_blank
      end

      it "can be the maximum length." do
        @s.key = "a" * 64
        expect(@s).to be_valid
      end

      it "cannot be too long." do
        @s.key = "a" * 65
        expect(@s).not_to be_valid
        expect(@s.errors[:key]).not_to be_blank
      end

      it "must be unique" do
        s2 = FactoryGirl.create(:system_setting, {:key => 'testkey'})
        @s.key = 'testkey'
        expect(@s).not_to be_valid
        expect(@s.errors[:key]).not_to be_blank
      end

      describe 'allows valid characters' do
        ['key_name', 'key', 'key2'].each do |key_str|
          it "'#{key_str}'" do
            @s.key = key_str
            expect(@s).to be_valid
          end
        end
      end

      describe 'disallows invalid characters' do
        ["tab\t", "newline\n",
         "Iñtërnâtiônàlizætiøn",
         'semicolon;',
         'quote"',
         'tick\'',
         'backtick`',
         'percent%',
         'plus+',
         'space '].each do |key_str|
          it "'#{key_str}'" do
            @s.key = key_str
            expect(@s).not_to be_valid
            expect(@s.errors[:key]).not_to be_blank
          end
        end
      end
    end
  end

  describe "named_scopes" do
    it "by_key should order by key" do
      s1 = FactoryGirl.create(:system_setting, :key => 'b_key')
      s2 = FactoryGirl.create(:system_setting, :key => 'a_key')
      s3 = FactoryGirl.create(:system_setting, :key => 'c_key')
      expect(SystemSetting.by_key).to eq([s2, s1, s3])
    end
  end

  it "should return the key for to_param" do
    s = FactoryGirl.create(:system_setting, :key => 'test_key')
    expect(s.to_param).to eq('test_key')
  end

  it "human_name should return 'System setting'" do
    expect(SystemSetting.human_name).to eq('System setting')
  end

  describe "#seed" do
    context "when no system setting with the specified key exists" do
      it "creates a new one with that key" do
        SystemSetting.seed("some_key")
        expect(SystemSetting.find_by_key("some_key")).not_to be_nil
      end

      it "sets the new one's description to an empty string if none is specified" do
        SystemSetting.seed("some_key")
        expect(SystemSetting.find_by_key("some_key").description).to eq("")
      end

      it "sets the description of the new one if specified" do
        SystemSetting.seed("some_key", :description => "important setting")
        expect(SystemSetting.find_by_key("some_key").description).to eq("important setting")
      end

      it "sets the new one's initial value to an empty string if none is specified" do
        SystemSetting.seed("some_key")
        expect(SystemSetting.find_by_key("some_key").value).to eq("")
      end

      it "sets the initial value of the new one if specified" do
        SystemSetting.seed("some_key", :initial_value => "the initial value")
        expect(SystemSetting.find_by_key("some_key").value).to eq("the initial value")
      end
    end

    context "when a system setting with the specified key already exists" do
      it "does not change the value of the existing one" do
        FactoryGirl.create(:system_setting, :key => "existing_key", :value => "the existing value")
        SystemSetting.seed("existing_key", :initial_value => "the new value")
        expect(SystemSetting.find_by_key("existing_key").value).to eq("the existing value")
      end

      it "changes the description of the existing one" do
        FactoryGirl.create(:system_setting, :key => "existing_key", :description => "the existing description")
        SystemSetting.seed("existing_key", :description => "the new description")
        expect(SystemSetting.find_by_key("existing_key").description).to eq("the new description")
      end

      it "does not blank the description of the existing one if a new one is not specified" do
        FactoryGirl.create(:system_setting, :key => "existing_key", :description => "the existing description")
        SystemSetting.seed("existing_key")
        expect(SystemSetting.find_by_key("existing_key").description).to eq("the existing description")
      end
    end

    it "raises an error when the system setting is not valid" do
      expect { SystemSetting.seed("x" * 65) }.to raise_error
    end

    it "raises an error when a non-supported option is passed" do
      expect { SystemSetting.seed("key", :unknown_option => "foo") }.to raise_error
    end

    it "does not save a system setting if a non-supported option is passed" do
      begin
        SystemSetting.seed("key", :unknown_option => "foo")
      rescue
      end
      expect(SystemSetting.find_by_key("key")).to be_nil
    end
  end

  describe "value_of_key" do
    it "is nil if no system setting with the key exists" do
      expect(SystemSetting.value_of_key("non_existing")).to be_nil
    end

    it "is the value of the system setting with that key" do
      FactoryGirl.create(:system_setting, :key => "the_key", :value => "the value")
      expect(SystemSetting.value_of_key("the_key")).to eq("the value")
    end
  end
end
