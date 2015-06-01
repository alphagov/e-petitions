# == Schema Information
#
# Table name: sponsors
#
#  id               :integer          not null, primary key
#  encrypted_email  :string(255)
#  perishable_token :string(255)
#  petition_id      :integer
#  signature_id     :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'rails_helper'

describe Sponsor do

  it "has a valid factory" do
    expect(FactoryGirl.build(:sponsor)).to be_valid
  end

  context "validations" do
    it { is_expected.to validate_presence_of(:petition).with_message(/Needs a petition/) }
  end

  context 'signature association' do
    let(:sponsor) { FactoryGirl.build(:sponsor) }
    let(:attributes) { {} }

    shared_examples_for 'constructing a signature from a sponsor' do
      it 'is has the same petition as the sponsor' do
        expect(subject.petition).to eq sponsor.petition
      end

      it 'does not allow overriding the petition (by object)' do
        other_petition = FactoryGirl.create(:petition)
        attributes[:petition] = other_petition
        expect(subject.petition).not_to eq other_petition
      end

      it 'does not allow overriding the petition (by id)' do
        other_petition = FactoryGirl.create(:petition)
        attributes[:petition_id] = other_petition.id
        expect(subject.petition_id).not_to eq other_petition.id
      end
    end

    context '#build_signature' do
      subject { sponsor.build_signature(attributes) }
      it_behaves_like 'constructing a signature from a sponsor'
    end

    context '#create_signature' do
      subject { sponsor.create_signature(attributes) }

      it_behaves_like 'constructing a signature from a sponsor'
    end

    context '#create_signature' do
      let(:attributes) { FactoryGirl.attributes_for(:signature) }
      before { sponsor.save! }
      subject { sponsor.create_signature!(attributes) }

      it_behaves_like 'constructing a signature from a sponsor'
    end
  end

  context '.for_email' do
    it 'finds sponsors with a signature that matches the supplied email address' do
      no_sig = FactoryGirl.create(:sponsor)
      matching_pending_sig = FactoryGirl.create(:sponsor, :pending, email: 'dave@example.com')
      matching_validated_sig = FactoryGirl.create(:sponsor, :pending, email: 'dave@example.com')
      non_matching_pending_sig = FactoryGirl.create(:sponsor, :pending, email: 'laura@example.com')
      non_matching_validated_sig = FactoryGirl.create(:sponsor, :pending, email: 'suzy@example.com')

      for_email_sponsors = Sponsor.for_email('dave@example.com')
      expect(for_email_sponsors).to include(matching_pending_sig, matching_validated_sig)
      expect(for_email_sponsors).not_to include(no_sig, non_matching_pending_sig, non_matching_validated_sig)
    end
  end

  context 'supporting the petition' do
    let(:sponsor) { FactoryGirl.create(:sponsor) }

    context 'when the sponsor has no signature' do
      it 'does not support the petition' do
        expect(sponsor.supports_the_petition?).to be_falsey
      end
      it 'is not included in the supporting_the_petition scope' do
        expect(Sponsor.supporting_the_petition).not_to include(sponsor)
      end
    end

    context 'when the sponsor has a signature' do

      context 'that is pending' do
        before { sponsor.create_signature!(FactoryGirl.attributes_for(:pending_signature)) }

        it 'does not support the petition' do
          expect(sponsor.supports_the_petition?).to be_falsey
        end
        it 'is not included in the supporting_the_petition scope' do
          expect(Sponsor.supporting_the_petition).not_to include(sponsor)
        end
      end

      context 'thas has been validated' do
        before { sponsor.create_signature!(FactoryGirl.attributes_for(:validated_signature)) }

        it 'supports the petition' do
          expect(sponsor.supports_the_petition?).to be_truthy
        end
        it 'is included in the supporting_the_petition scope' do
          expect(Sponsor.supporting_the_petition).to include(sponsor)
        end
      end
    end
  end
end
