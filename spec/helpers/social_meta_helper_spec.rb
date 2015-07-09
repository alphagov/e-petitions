require 'rails_helper'

RSpec.describe SocialMetaHelper, type: :helper do
  describe "#open_graph_tag" do
    context "when using a string for content" do
      subject do
        helper.open_graph_tag("type", "article")
      end

      it "generates a meta tag with the content" do
        expect(subject).to match(%r{<meta property="og:type" content="article" /})
      end
    end

    context "when using a symbol for content" do
      subject do
        helper.open_graph_tag("site_name", :site_name)
      end

      it "generates a meta tag with the i18n content" do
        expect(subject).to match(%r{<meta property="og:site_name" content="Petitions - UK Government and Parliament" /})
      end
    end

    context "when using a symbol for content with interpolation" do
      subject do
        helper.open_graph_tag("title", :title, petition: "Show us the money")
      end

      it "generates a meta tag with the i18n content" do
        expect(subject).to match(%r{<meta property="og:title" content="Petition: Show us the money" /})
      end
    end

    context "when using a image path for content" do
      subject do
        helper.open_graph_tag("image", "os-social/opengraph-image.png")
      end

      it "generates a meta tag with the correct asset image path" do
        expect(subject).to match(%r{<meta property="og:image" content="/assets/os-social/opengraph-image.png" /})
      end
    end
  end

  describe "#twitter_card_tag" do
    context "when using a string for content" do
      subject do
        helper.twitter_card_tag("site", "@hocpetitions")
      end

      it "generates a meta tag with the content" do
        expect(subject).to match(%r{<meta name="twitter:site" content="@hocpetitions" /})
      end
    end

    context "when using a symbol for content" do
      subject do
        helper.twitter_card_tag("title", :default_title)
      end

      it "generates a meta tag with the i18n content" do
        expect(subject).to match(%r{<meta name="twitter:title" content="Petitions - UK Government and Parliament" /})
      end
    end

    context "when using a symbol for content with interpolation" do
      subject do
        helper.twitter_card_tag("title", :title, petition: "Show us the money")
      end

      it "generates a meta tag with the i18n content" do
        expect(subject).to match(%r{<meta name="twitter:title" content="Petition: Show us the money" /})
      end
    end

    context "when using a image path for content" do
      subject do
        helper.twitter_card_tag("image", "os-social/opengraph-image.png")
      end

      it "generates a meta tag with the correct asset image path" do
        expect(subject).to match(%r{<meta name="twitter:image" content="/assets/os-social/opengraph-image.png" /})
      end
    end
  end
end
