module StagedObjectHelpers
  def for_stage(name, next_is:, back_is:, not_moving_is:)
    context "and the previous_stage was \"#{name}\"" do
      let(:stage) { name }
      context 'and we are moving forwards' do
        let(:move) { 'next' }
        it "is \"#{next_is}\"" do
          expect(subject.stage).to eq next_is
        end
      end
      context 'and we are moving backwards' do
        let(:move) { 'back' }
        it "is \"#{back_is}\"" do
          expect(subject.stage).to eq back_is
        end
      end
      context 'and we are not moving' do
        let(:move) { nil }
        it "is \"#{not_moving_is}\"" do
          expect(subject.stage).to eq not_moving_is
        end
      end
    end
  end
end
