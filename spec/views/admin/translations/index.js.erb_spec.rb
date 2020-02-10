require 'rails_helper'

RSpec.describe "admin/translations/index.js.erb", type: :view do
  before do
    view.singleton_class.class_exec do
      def current_user
        return @current_user if defined?(@current_user)
      end

      def logged_in?
        current_user
      end
    end
  end

  context "when not logged in" do
    it "renders a script to remove translation tags" do
      expect(render).to eq <<~JS
        window.addEventListener('DOMContentLoaded', (event) => {
          var translations = document.querySelectorAll('span[data-translation-link]');

          translations.forEach((translation) => {
            translation.remove();
          })

          console.log('Translation tags removed');
        });
      JS
    end
  end

  shared_examples_for "a logged in translation user" do
    it "renders a script to link translation tags" do
      expect(render).to eq <<~JS
        window.addEventListener('DOMContentLoaded', (event) => {
          var translations = document.querySelectorAll('span[data-translation-link]');

          translations.forEach((translation) => {
            var parent = translation.parentElement;
            parent.dataset.translationLink = translation.dataset.translationLink;

            parent.addEventListener('click', (event) => {
              if (event.altKey) {
                event.preventDefault();
                event.stopPropagation();

                window.open(parent.dataset.translationLink, '_blank');
              }
            });

            translation.remove();
          })

          console.log('Translation helper loaded');
        });
      JS
    end
  end

  context "when logged in as a moderator" do
    let(:moderator) { FactoryBot.create(:moderator_user) }
    before { assign :current_user, moderator }

    it_behaves_like "a logged in translation user"
  end

  context "when logged in as a sysadmin" do
    let(:sysadmin) { FactoryBot.create(:sysadmin_user) }
    before { assign :current_user, sysadmin }

    it_behaves_like "a logged in translation user"
  end
end
