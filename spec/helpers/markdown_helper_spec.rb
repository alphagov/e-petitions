require 'rails_helper'

RSpec.describe MarkdownHelper, type: :helper do
  describe "#markdown_to_html" do
    it "converts markdown to html" do
      expect(helper.markdown_to_html("## Petitions: UK Government and Parliament")).to eq(%[<h2>Petitions: UK Government and Parliament</h2>\n])
    end

    it "autolinks urls" do
      expect(helper.markdown_to_html("www.example.com")).to eq(%[<p><a href="http://www.example.com">www.example.com</a></p>\n])
    end

    it "sanitizes href attributes" do
      expect(helper.markdown_to_html(%[<a href="javascript:alert('Hello, World!');">Hello, World!</a>])).to eq(%[<p><a>Hello, World!</a></p>\n])
    end

    it "sanitizes event handlers" do
      expect(helper.markdown_to_html(%[<a onclick="alert('Hello, World!');">Hello, World!</a>])).to eq(%[<p><a>Hello, World!</a></p>\n])
    end

    it "sanitizes <script> tags" do
      expect(helper.markdown_to_html(%[<script>alert('Hello, World!');</script>])).to eq(%[alert('Hello, World!');\n])
    end
  end

  describe "#markdown_to_text" do
    it "converts markdown to text" do
      markdown = <<~MD
        # Petitions: UK Government and Parliament

        Create or sign a petition to demand UK Government or UK Parliament to act.

        1.  Create a petition

            Go to https://petition.parliament.uk/petitions/start.

        2.  Find sponsors to support your petition

            You will receive an email to share when you create a petition.

        3.  Share your petition once it's published

            It will take ten working days to moderate your petition once it has enough supporters.

        Your petition must comply with the [petition standards][1]:

        * Not be offensive
        * Be something that the UK Government or UK Parliament is responsible for

        If you have any questions, contact the [Petitions Committee][2]

        [1]: https://petition.parliament.uk/standards
        [2]: mailto:petitions@parliament.uk
      MD

      text = <<~TXT
        Petitions: UK Government and Parliament
        ---------------------------------------

        Create or sign a petition to demand UK Government or UK Parliament to act.

        1. Create a petition

        Go to https://petition.parliament.uk/petitions/start.

        2. Find sponsors to support your petition

        You will receive an email to share when you create a petition.

        3. Share your petition once it's published

        It will take ten working days to moderate your petition once it has enough supporters.

        Your petition must comply with the petition standards[1]:

        * Not be offensive
        * Be something that the UK Government or UK Parliament is responsible for

        If you have any questions, contact the Petitions Committee[2]

        [1]: https://petition.parliament.uk/standards
        [2]: mailto:petitions@parliament.uk
      TXT

      expect(helper.markdown_to_text(markdown)).to eq(text.strip)
    end

    it "doesn't autolinks urls" do
      expect(helper.markdown_to_text("www.example.com")).to eq(%[www.example.com])
    end
  end
end
