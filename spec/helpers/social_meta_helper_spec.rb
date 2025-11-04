require 'rails_helper'

RSpec.describe SocialMetaHelper, type: :helper do
  let(:headers) { helper.request.env }

  describe "#meta_description_tag" do
    let(:params) do
      ActionController::Parameters.new(params_hash)
    end

    subject { helper.meta_description_tag }

    before do
      allow(controller).to receive(:params).and_return(params)
    end

    context "when on a page with description in the locale file" do
      let(:params_hash) do
        { controller: "petitions", action: "index" }
      end

      it "returns a meta description tag" do
        expect(subject).to eq(%[<meta name="description" content="Search results for open petitions. You can sign and share petitions.">])
      end
    end

    context "when on a namespaced page with description in the locale file" do
      let(:params_hash) do
        { controller: "archived/petitions", action: "index" }
      end

      it "returns a meta description tag" do
        expect(subject).to eq(%[<meta name="description" content="Search results for archived petitions. These petitions cannot be signed anymore.">])
      end
    end

    context "when on the first petition creator page" do
      let(:params_hash) do
        { controller: "petitions", action: "new" }
      end

      before do
        assign(:new_petition, PetitionCreator.new(params, request))
      end

      it "returns a meta description tag" do
        expect(subject).to eq(%[<meta name="description" content="Check if you meet the criteria to create and submit a petition for the UK Parliament or UK Government.">])
      end
    end

    context "when on a petition creator page" do
      let(:params_hash) do
        { controller: "petitions", action: "create", stage: "action" }
      end

      before do
        assign(:new_petition, PetitionCreator.new(params, request))
      end

      it "returns a meta description tag" do
        expect(subject).to eq(%[<meta name="description" content="Add a clear and concise title to your petition for the UK Parliament or UK Government.">])
      end
    end

    context "when on the first signature creator page" do
      let(:petition) { FactoryBot.create(:open_petition) }

      let(:params_hash) do
        { controller: "signatures", action: "new", petition_id: petition.to_param }
      end

      before do
        assign(:petition, petition)
        assign(:signature, SignatureCreator.new(petition, params, request))
      end

      it "returns a meta description tag" do
        expect(subject).to eq(%[<meta name="description" content="Confirm your are a British citizen or UK resident to be able to sign this petition.">])
      end
    end

    context "when on a signature creator page" do
      let(:petition) { FactoryBot.create(:open_petition) }

      let(:params_hash) do
        { controller: "signatures", action: "create", petition_id: petition.to_param, stage: "signature" }
      end

      before do
        assign(:petition, petition)
        assign(:signature, SignatureCreator.new(petition, params, request))
      end

      it "returns a meta description tag" do
        expect(subject).to eq(%[<meta name="description" content="Confirm all your details before signing this petition.">])
      end
    end

    context "when on a page without a description in the locale file" do
      let(:params_hash) do
        { controller: "pages", action: "manifest" }
      end

      it "returns nil" do
        expect(subject).to be_nil
      end
    end
  end

  describe "#open_graph_tag" do
    context "when using a string for content" do
      subject do
        helper.open_graph_tag("type", "article")
      end

      it "generates a meta tag with the content" do
        expect(subject).to match(%r{<meta property="og:type" content="article">})
      end
    end

    context "when using a symbol for content" do
      subject do
        helper.open_graph_tag("site_name", :site_name)
      end

      it "generates a meta tag with the i18n content" do
        expect(subject).to match(%r{<meta property="og:site_name" content="Petitions - UK Government and Parliament">})
      end
    end

    context "when using a symbol for content with interpolation" do
      subject do
        helper.open_graph_tag("title", :title, petition: "Show us the money")
      end

      it "generates a meta tag with the i18n content" do
        expect(subject).to match(%r{<meta property="og:title" content="Petition: Show us the money">})
      end
    end

    context "when using a image path for content" do
      before do
        headers["HTTP_HOST"]   = "petition.parliament.uk"
        headers["HTTPS"]       = "on"
        headers["SERVER_PORT"] = 443
      end

      subject do
        helper.open_graph_tag("image", "os-social/opengraph-image.png")
      end

      it "generates a meta tag with the correct asset image url" do
        expect(subject).to match(%r{<meta property="og:image" content="https://petition.parliament.uk/assets/os-social/opengraph-image-b0f8a20f.png">})
      end
    end
  end

  describe "#x_card_tag" do
    context "when using a string for content" do
      subject do
        helper.x_card_tag("site", "@hocpetitions")
      end

      it "generates a meta tag with the content" do
        expect(subject).to match(%r{<meta name="twitter:site" content="@hocpetitions">})
      end
    end

    context "when using a symbol for content" do
      subject do
        helper.x_card_tag("title", :default_title)
      end

      it "generates a meta tag with the i18n content" do
        expect(subject).to match(%r{<meta name="twitter:title" content="Petitions - UK Government and Parliament">})
      end
    end

    context "when using a symbol for content with interpolation" do
      subject do
        helper.x_card_tag("title", :title, petition: "Show us the money")
      end

      it "generates a meta tag with the i18n content" do
        expect(subject).to match(%r{<meta name="twitter:title" content="Petition: Show us the money">})
      end
    end

    context "when using a image path for content" do
      before do
        headers["HTTP_HOST"]   = "petition.parliament.uk"
        headers["HTTPS"]       = "on"
        headers["SERVER_PORT"] = 443
      end

      subject do
        helper.x_card_tag("image", "os-social/opengraph-image.png")
      end

      it "generates a meta tag with the correct asset image url" do
        expect(subject).to match(%r{<meta name="twitter:image" content="https://petition.parliament.uk/assets/os-social/opengraph-image-b0f8a20f.png">})
      end
    end
  end
end
