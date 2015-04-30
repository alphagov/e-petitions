require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RejectionReason do

  describe "#options_for_select" do
    it "should load the reasons and codes from the rejection reasons file" do
      expect(RejectionReason.options_for_select.size).to eq(6)
      expect(RejectionReason.options_for_select.map(&:second).sort).to eq(["duplicate", "honours", "irrelevant", "libellous", "no-action", "offensive"])
      expect(RejectionReason.options_for_select.map(&:first).sort).to eq(["Confidential, libellous, false or defamatory statements (will be hidden)", "Does not include a request for action", "Duplicate of an existing e-petition", "Matters relating to honours or appointments", "Matters which are not the responsibility of HM Government", "Offensive, joke or nonsense e-petitions (will be hidden)"])
    end
  end

  describe "#find_by_code" do
    it "should return a hash of the code's attributes" do
      reason = RejectionReason.find_by_code("duplicate")
      expect(reason.published).to eq(true)
      expect(reason.title).to eq("Duplicate of an existing e-petition")
      expect(reason.description).to eq("<p>There is already an e-petition about this issue.</p>")
    end
    
    it "should return nil if code is not found" do
      reason = RejectionReason.find_by_code("will_not_be_found")
      expect(reason).to be_nil
    end
  end
end
