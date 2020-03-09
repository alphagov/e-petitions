require 'spec_helper'
require 'domain_autocorrect'

RSpec.describe DomainAutocorrect do
  describe ".call" do
    it "returns nil if the argument is nil" do
      expect(
        described_class.call(nil)
      ).to eq(nil)
    end

    it "returns '' if the argument is ''" do
      expect(
        described_class.call("")
      ).to eq("")
    end

    context "with typos for the domain 'aol.com'" do
      it "doesn't change a correct email address" do
        expect(
          described_class.call("bob.jones@aol.com")
        ).to eq("bob.jones@aol.com")
      end

      %w[ail.com aol.co.uk aol.con apl.com].each do |domain|
        it "autocorrects '#{domain}' to 'aol.com'" do
          expect(
            described_class.call("bob.jones@#{domain}")
          ).to eq("bob.jones@aol.com")
        end
      end
    end

    context "with typos for the domain 'btinternet.com'" do
      it "doesn't change a correct email address" do
        expect(
          described_class.call("bob.jones@btinternet.com")
        ).to eq("bob.jones@btinternet.com")
      end

      %w[
        binternet.com
        brinternet.com
        btinernet.com
        btingernet.com
        btintenet.com
        btintermet.com
        btinterner.com
        btinternet.co
        btinternet.co.uk
        btinternet.con
        btintetnet.com
        btinyernet.com
        btnternet.com
        byinternet.com
      ].each do |domain|
        it "autocorrects '#{domain}' to 'btinternet.com'" do
          expect(
            described_class.call("bob.jones@#{domain}")
          ).to eq("bob.jones@btinternet.com")
        end
      end
    end

    context "with typos for the domain 'gmail.com'" do
      it "doesn't change a correct email address" do
        expect(
          described_class.call("bob.jones@gmail.com")
        ).to eq("bob.jones@gmail.com")
      end

      %w[
        gmail.com
        fmail.com
        g.mail.com
        gail.com
        gamail.com
        gamil.com
        gmai.com
        gmaik.com
        gmail.cim
        gmail.clm
        gmail.cm
        gmail.co
        gmail.co.uk
        gmail.com.com
        gmail.com.uk
        gmail.comm
        gmail.con
        gmail.om
        gmail.uk
        gmail.vom
        gmaill.com
        gmal.com
        gmaol.com
        gmaul.com
        gmial.com
        gmil.com
        gmsil.com
        gnail.com
      ].each do |domain|
        it "autocorrects '#{domain}' to 'gmail.com'" do
          expect(
            described_class.call("bob.jones@#{domain}")
          ).to eq("bob.jones@gmail.com")
        end
      end
    end

    context "with typos for the domain 'googlemail.com'" do
      it "doesn't change a correct email address" do
        expect(
          described_class.call("bob.jones@googlemail.com")
        ).to eq("bob.jones@googlemail.com")
      end

      %w[
        googlemail.co.uk
        googlemail.con
        googlemial.com
        googlemsil.com
        googlmail.com
        goolemail.com
      ].each do |domain|
        it "autocorrects '#{domain}' to 'googlemail.com'" do
          expect(
            described_class.call("bob.jones@#{domain}")
          ).to eq("bob.jones@googlemail.com")
        end
      end
    end

    context "with typos for the domain 'hotmail.com'" do
      it "doesn't change a correct email address" do
        expect(
          described_class.call("bob.jones@hotmail.com")
        ).to eq("bob.jones@hotmail.com")
      end

      %w[
        hitmail.com
        homail.com
        hormail.com
        hotmai.com
        hotmail.cim
        hotmail.cm
        hotmail.co
        hotmail.con
        hotmaill.com
        hotmal.com
        hotmil.com
        hotmial.com
        hotmsil.com
        hotnail.com
      ].each do |domain|
        it "autocorrects '#{domain}' to 'hotmail.com'" do
          expect(
            described_class.call("bob.jones@#{domain}")
          ).to eq("bob.jones@hotmail.com")
        end
      end
    end

    context "with typos for the domain 'hotmail.co.uk'" do
      it "doesn't change a correct email address" do
        expect(
          described_class.call("bob.jones@hotmail.co.uk")
        ).to eq("bob.jones@hotmail.co.uk")
      end

      %w[
        hitmail.co.uk
        homail.co.uk
        hormail.co.uk
        hotmai.co.uk
        hotmaik.co.uk
        hotmail.co.ik
        hotmail.co.uj
        hotmail.co.ul
        hotmail.co.um
        hotmail.co.un
        hotmail.co.yk
        hotmail.com.uk
        hotmail.conuk
        hotmail.couk
        hotmail.uk
        hotmailco.uk
        hotmal.co.uk
        hotmaul.co.uk
        hotmil.co.uk
        hotmial.co.uk
        hotmsil.co.uk
        hotnail.co.uk
      ].each do |domain|
        it "autocorrects '#{domain}' to 'hotmail.co.uk'" do
          expect(
            described_class.call("bob.jones@#{domain}")
          ).to eq("bob.jones@hotmail.co.uk")
        end
      end
    end

    context "with typos for the domain 'icloud.com'" do
      it "doesn't change a correct email address" do
        expect(
          described_class.call("bob.jones@icloud.com")
        ).to eq("bob.jones@icloud.com")
      end

      %w[
        cloud.com
        icloud.co.uk
        icloud.con
        icoud.com
        icould.com
        ivloud.com
      ].each do |domain|
        it "autocorrects '#{domain}' to 'icloud.com'" do
          expect(
            described_class.call("bob.jones@#{domain}")
          ).to eq("bob.jones@icloud.com")
        end
      end
    end

    context "with typos for the domain 'live.com'" do
      it "doesn't change a correct email address" do
        expect(
          described_class.call("bob.jones@live.com")
        ).to eq("bob.jones@live.com")
      end

      %w[live.co live.con].each do |domain|
        it "autocorrects '#{domain}' to 'live.com'" do
          expect(
            described_class.call("bob.jones@#{domain}")
          ).to eq("bob.jones@live.com")
        end
      end
    end

    context "with typos for the domain 'live.co.uk'" do
      it "doesn't change a correct email address" do
        expect(
          described_class.call("bob.jones@live.co.uk")
        ).to eq("bob.jones@live.co.uk")
      end

      %w[live.co.ik live.co.um live.co.un].each do |domain|
        it "autocorrects '#{domain}' to 'live.co.uk'" do
          expect(
            described_class.call("bob.jones@#{domain}")
          ).to eq("bob.jones@live.co.uk")
        end
      end
    end

    context "with typos for the domain 'mac.com'" do
      it "doesn't change a correct email address" do
        expect(
          described_class.call("bob.jones@mac.com")
        ).to eq("bob.jones@mac.com")
      end

      %w[mac.con].each do |domain|
        it "autocorrects '#{domain}' to 'mac.com'" do
          expect(
            described_class.call("bob.jones@#{domain}")
          ).to eq("bob.jones@mac.com")
        end
      end
    end

    context "with typos for the domain 'me.com'" do
      it "doesn't change a correct email address" do
        expect(
          described_class.call("bob.jones@me.com")
        ).to eq("bob.jones@me.com")
      end

      %w[me.con].each do |domain|
        it "autocorrects '#{domain}' to 'me.com'" do
          expect(
            described_class.call("bob.jones@#{domain}")
          ).to eq("bob.jones@me.com")
        end
      end
    end

    context "with typos for the domain 'msn.com'" do
      it "doesn't change a correct email address" do
        expect(
          described_class.call("bob.jones@msn.com")
        ).to eq("bob.jones@msn.com")
      end

      %w[msn.con].each do |domain|
        it "autocorrects '#{domain}' to 'msn.com'" do
          expect(
            described_class.call("bob.jones@#{domain}")
          ).to eq("bob.jones@msn.com")
        end
      end
    end

    context "with typos for the domain 'ntlworld.com'" do
      it "doesn't change a correct email address" do
        expect(
          described_class.call("bob.jones@ntlworld.com")
        ).to eq("bob.jones@ntlworld.com")
      end

      %w[ntlword.com ntlworld.con].each do |domain|
        it "autocorrects '#{domain}' to 'ntlworld.com'" do
          expect(
            described_class.call("bob.jones@#{domain}")
          ).to eq("bob.jones@ntlworld.com")
        end
      end
    end

    context "with typos for the domain 'outlook.com'" do
      it "doesn't change a correct email address" do
        expect(
          described_class.call("bob.jones@outlook.com")
        ).to eq("bob.jones@outlook.com")
      end

      %w[
        oulook.com
        outliok.com
        outlook.co.uk
        outlook.con
        outloook.com
        outook.com
      ].each do |domain|
        it "autocorrects '#{domain}' to 'outlook.com'" do
          expect(
            described_class.call("bob.jones@#{domain}")
          ).to eq("bob.jones@outlook.com")
        end
      end
    end

    context "with typos for the domain 'sky.com'" do
      it "doesn't change a correct email address" do
        expect(
          described_class.call("bob.jones@sky.com")
        ).to eq("bob.jones@sky.com")
      end

      %w[sky.con].each do |domain|
        it "autocorrects '#{domain}' to 'sky.com'" do
          expect(
            described_class.call("bob.jones@#{domain}")
          ).to eq("bob.jones@sky.com")
        end
      end
    end

    context "with typos for the domain 'talktalk.net'" do
      it "doesn't change a correct email address" do
        expect(
          described_class.call("bob.jones@talktalk.net")
        ).to eq("bob.jones@talktalk.net")
      end

      %w[talktalk.com].each do |domain|
        it "autocorrects '#{domain}' to 'talktalk.net'" do
          expect(
            described_class.call("bob.jones@#{domain}")
          ).to eq("bob.jones@talktalk.net")
        end
      end
    end

    context "with typos for the domain 'yahoo.com'" do
      it "doesn't change a correct email address" do
        expect(
          described_class.call("bob.jones@yahoo.com")
        ).to eq("bob.jones@yahoo.com")
      end

      %w[yahoo.co yahoo.con].each do |domain|
        it "autocorrects '#{domain}' to 'yahoo.com'" do
          expect(
            described_class.call("bob.jones@#{domain}")
          ).to eq("bob.jones@yahoo.com")
        end
      end
    end

    context "with typos for the domain 'yahoo.co.uk'" do
      it "doesn't change a correct email address" do
        expect(
          described_class.call("bob.jones@yahoo.co.uk")
        ).to eq("bob.jones@yahoo.co.uk")
      end

      %w[
        yahoo.co.uk
        tahoo.co.uk
        uahoo.co.uk
        yaho.co.uk
        yahoo.co.ik
        yahoo.co.uj
        yahoo.co.ul
        yahoo.co.um
        yahoo.co.un
        yahoo.co.yk
        yahoo.conuk
        yahoo.couk
        yahoo.uk
        yahooco.uk
        yhoo.co.uk
        yshoo.co.uk
      ].each do |domain|
        it "autocorrects '#{domain}' to 'yahoo.co.uk'" do
          expect(
            described_class.call("bob.jones@#{domain}")
          ).to eq("bob.jones@yahoo.co.uk")
        end
      end
    end
  end
end
