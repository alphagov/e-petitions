require 'rails_helper'

RSpec.describe AutoLinkHelper, type: :helper do
  describe "#auto_link" do
    it "auto links urls embedded in a text block" do
      email_raw    = "david@loudthinking.com"
      email_result = "<a href=\"mailto:#{email_raw}\">#{email_raw}</a>"
      link_raw     = "http://www.rubyonrails.com"
      link_result  = "<a href=\"#{link_raw}\">#{link_raw}</a>"
      link_result_with_options = %{<a target="_blank" href="#{link_raw}">#{link_raw}</a>}

      expect(helper.auto_link(nil)).to eq("")
      expect(helper.auto_link("")).to eq("")
      expect(helper.auto_link("#{link_raw} #{link_raw} #{link_raw}")).to eq("#{link_result} #{link_result} #{link_result}")
      expect(helper.auto_link("hello #{email_raw}", link: :email_addresses)).to eq("hello #{email_result}")
      expect(helper.auto_link("Go to #{link_raw}", link: :urls)).to eq("Go to #{link_result}")
      expect(helper.auto_link("Go to #{link_raw}", link: :email_addresses)).to eq("Go to #{link_raw}")
      expect(helper.auto_link("Go to #{link_raw} and say hello to #{email_raw}")).to eq("Go to #{link_result} and say hello to #{email_result}")
      expect(helper.auto_link("<p>Link #{link_raw}</p>")).to eq("<p>Link #{link_result}</p>")
      expect(helper.auto_link("<p>#{link_raw} Link</p>")).to eq("<p>#{link_result} Link</p>")
      expect(helper.auto_link("<p>Link #{link_raw}</p>", link: :all, html: { target: "_blank" })).to eq("<p>Link #{link_result_with_options}</p>")
      expect(helper.auto_link("Go to #{link_raw}.")).to eq("Go to #{link_result}.")
      expect(helper.auto_link("<p>Go to #{link_raw}, then say hello to #{email_raw}.</p>")).to eq("<p>Go to #{link_result}, then say hello to #{email_result}.</p>")
      expect(helper.auto_link("#{link_result} #{link_raw}")).to eq("#{link_result} #{link_result}")

      email2_raw    = "+david@loudthinking.com"
      email2_result = "<a href=\"mailto:%2Bdavid@loudthinking.com\">+david@loudthinking.com</a>"
      expect(helper.auto_link(email2_raw)).to eq(email2_result)
      expect(helper.auto_link(email2_raw, link: :all)).to eq(email2_result)
      expect(helper.auto_link(email2_raw, link: :email_addresses)).to eq(email2_result)

      link2_raw    = "www.rubyonrails.com"
      link2_result = "<a href=\"http://www.rubyonrails.com\">www.rubyonrails.com</a>"
      expect(helper.auto_link("Go to #{link2_raw}", link: :urls)).to eq("Go to #{link2_result}")
      expect(helper.auto_link("Go to #{link2_raw}", link: :email_addresses)).to eq("Go to #{link2_raw}")
      expect(helper.auto_link("<p>Go to #{link2_raw}</p>")).to eq("<p>Go to #{link2_result}</p>")
      expect(helper.auto_link("<p>#{link2_raw} Link</p>")).to eq("<p>#{link2_result} Link</p>")
      expect(helper.auto_link("Go to #{link2_raw}.")).to eq("Go to #{link2_result}.")
      expect(helper.auto_link("<p>Say hello to #{email_raw}, then go to #{link2_raw}.</p>")).to eq("<p>Say hello to #{email_result}, then go to #{link2_result}.</p>")

      link3_raw    = 'http://manuals.ruby-on-rails.com/read/chapter.need_a-period/103#page281'
      link3_result = "<a href=\"http://manuals.ruby-on-rails.com/read/chapter.need_a-period/103#page281\">http://manuals.ruby-on-rails.com/read/chapter.need_a-period/103#page281</a>"
      expect(helper.auto_link("Go to #{link3_raw}", link: :urls)).to eq("Go to #{link3_result}")
      expect(helper.auto_link("Go to #{link3_raw}", link: :email_addresses)).to eq("Go to #{link3_raw}")
      expect(helper.auto_link("<p>Go to #{link3_raw}</p>")).to eq("<p>Go to #{link3_result}</p>")
      expect(helper.auto_link("<p>#{link3_raw} Link</p>")).to eq("<p>#{link3_result} Link</p>")
      expect(helper.auto_link("Go to #{link3_raw}.")).to eq("Go to #{link3_result}.")
      expect(helper.auto_link(
        "<p>Go to #{link3_raw}. Seriously, #{link3_raw}? I think I'll say hello to #{email_raw}. Instead.</p>"
      )).to eq(
        "<p>Go to #{link3_result}. Seriously, #{link3_result}? I think I'll say hello to #{email_result}. Instead.</p>"
      )

      link4_raw    = "http://foo.example.com/controller/action?parm=value&p2=v2#anchor123"
      link4_result = "<a href=\"http://foo.example.com/controller/action?parm=value&amp;p2=v2#anchor123\">http://foo.example.com/controller/action?parm=value&amp;p2=v2#anchor123</a>"
      expect(helper.auto_link("<p>Link #{link4_raw}</p>")).to eq("<p>Link #{link4_result}</p>")
      expect(helper.auto_link("<p>#{link4_raw} Link</p>")).to eq("<p>#{link4_result} Link</p>")

      link5_raw    = "http://foo.example.com:3000/controller/action"
      link5_result = "<a href=\"#{link5_raw}\">#{link5_raw}</a>"
      expect(helper.auto_link("<p>#{link5_raw} Link</p>")).to eq("<p>#{link5_result} Link</p>")

      link6_raw    = "http://foo.example.com:3000/controller/action+pack"
      link6_result = "<a href=\"#{link6_raw}\">#{link6_raw}</a>"
      expect(helper.auto_link("<p>#{link6_raw} Link</p>")).to eq("<p>#{link6_result} Link</p>")

      link7_raw    = "http://foo.example.com/controller/action?parm=value&p2=v2#anchor-123"
      link7_result = "<a href=\"http://foo.example.com/controller/action?parm=value&amp;p2=v2#anchor-123\">http://foo.example.com/controller/action?parm=value&amp;p2=v2#anchor-123</a>"
      expect(helper.auto_link("<p>#{link7_raw} Link</p>")).to eq("<p>#{link7_result} Link</p>")

      link8_raw    = "http://foo.example.com:3000/controller/action.html"
      link8_result = "<a href=\"#{link8_raw}\">#{link8_raw}</a>"
      expect(helper.auto_link("Go to #{link8_raw}", link: :urls)).to eq("Go to #{link8_result}")
      expect(helper.auto_link("Go to #{link8_raw}", link: :email_addresses)).to eq("Go to #{link8_raw}")
      expect(helper.auto_link("<p>Go to #{link8_raw}</p>")).to eq("<p>Go to #{link8_result}</p>")
      expect(helper.auto_link("<p>#{link8_raw} Link</p>")).to eq("<p>#{link8_result} Link</p>")
      expect(helper.auto_link("Go to #{link8_raw}.")).to eq("Go to #{link8_result}.")
      expect(helper.auto_link(
        "<p>Go to #{link8_raw}. Seriously, #{link8_raw}? I think I'll say hello to #{email_raw}. Instead.</p>"
      )).to eq(
        "<p>Go to #{link8_result}. Seriously, #{link8_result}? I think I'll say hello to #{email_result}. Instead.</p>"
      )

      link9_raw    = "http://business.timesonline.co.uk/article/0,,9065-2473189,00.html"
      link9_result = "<a href=\"#{link9_raw}\">#{link9_raw}</a>"
      expect(helper.auto_link("Go to #{link9_raw}", link: :urls)).to eq("Go to #{link9_result}")
      expect(helper.auto_link("Go to #{link9_raw}", link: :email_addresses)).to eq("Go to #{link9_raw}")
      expect(helper.auto_link("<p>Go to #{link9_raw}</p>")).to eq("<p>Go to #{link9_result}</p>")
      expect(helper.auto_link("<p>#{link9_raw} Link</p>")).to eq("<p>#{link9_result} Link</p>")
      expect(helper.auto_link("Go to #{link9_raw}.")).to eq("Go to #{link9_result}.")
      expect(helper.auto_link(
        "<p>Go to #{link9_raw}. Seriously, #{link9_raw}? I think I'll say hello to #{email_raw}. Instead.</p>"
      )).to eq(
        "<p>Go to #{link9_result}. Seriously, #{link9_result}? I think I'll say hello to #{email_result}. Instead.</p>"
      )

      link10_raw    = "http://www.mail-archive.com/ruby-talk@ruby-lang.org/"
      link10_result = "<a href=\"#{link10_raw}\">#{link10_raw}</a>"
      expect(helper.auto_link("<p>#{link10_raw} Link</p>")).to eq("<p>#{link10_result} Link</p>")

      link11_raw    = "http://asakusa.rubyist.net/"
      link11_result = "<a href=\"#{link11_raw}\">#{link11_raw}</a>"
      expect(helper.auto_link("浅草.rbの公式サイトはこちら#{link11_raw}")).to eq("浅草.rbの公式サイトはこちら#{link11_result}")

      link12_raw    = "http://tools.ietf.org/html/rfc3986"
      link12_result = "<a href=\"#{link12_raw}\">#{link12_raw}</a>"
      expect(helper.auto_link(
        "<p>#{link12_raw} text-after-nonbreaking-space</p>"
      )).to eq(
        "<p>#{link12_result} text-after-nonbreaking-space</p>"
      )

      link13_raw    = "HTtP://www.rubyonrails.com"
      expect(helper.auto_link(link13_raw)).to eq("<a href=\"#{link13_raw}\">#{link13_raw}</a>")
    end

    it "doesn't auto link urls inside tag attributes" do
      text = "<img src=\"http://www.rubyonrails.org/images/rails.png\">"
      result = "<img src=\"http://www.rubyonrails.org/images/rails.png\">"

      expect(helper.auto_link(text)).to eq(result)
    end

    it "auto links urls with parentheses" do
      text = "(link: http://en.wikipedia.org/wiki/Sprite_(computer_graphics))"
      result = "(link: <a href=\"http://en.wikipedia.org/wiki/Sprite_(computer_graphics)\">http://en.wikipedia.org/wiki/Sprite_(computer_graphics)</a>)"

      expect(helper.auto_link(text)).to eq(result)
    end

    it "auto links urls with brackets" do
      text = "[link: http://en.wikipedia.org/wiki/Sprite_[computer_graphics]]"
      result = "[link: <a href=\"http://en.wikipedia.org/wiki/Sprite_[computer_graphics]\">http://en.wikipedia.org/wiki/Sprite_[computer_graphics]</a>]"

      expect(helper.auto_link(text)).to eq(result)
    end

    it "auto links urls with braces" do
      text = "{link: http://en.wikipedia.org/wiki/Sprite_{computer_graphics}}"
      result = "{link: <a href=\"http://en.wikipedia.org/wiki/Sprite_{computer_graphics}\">http://en.wikipedia.org/wiki/Sprite_{computer_graphics}</a>}"

      expect(helper.auto_link(text)).to eq(result)
    end

    it "accepts options" do
      text = "Welcome to my new blog at http://www.myblog.com/. Please e-mail me at me@email.com."
      options = { link: :all, html: { class: "menu", target: "_blank" } }
      result = "Welcome to my new blog at <a class=\"menu\" target=\"_blank\" href=\"http://www.myblog.com/\">http://www.myblog.com/</a>. Please e-mail me at <a class=\"menu\" target=\"_blank\" href=\"mailto:me@email.com\">me@email.com</a>."

      expect(helper.auto_link(text, options)).to eq(result)
    end

    it "handles multiple trailing punctuations" do
      text = "(link: http://youtube.com)."
      result = "(link: <a href=\"http://youtube.com\">http://youtube.com</a>)."

      expect(helper.auto_link(text)).to eq(result)
    end

    it "accepts a block" do
      text = "<p>http://api.rubyonrails.com/Foo.html<br>fantabulous@shiznadel.ic<br></p>"
      result = "<p><a href=\"http://api.rubyonrails.com/Foo.html\">http://...</a><br><a href=\"mailto:fantabulous@shiznadel.ic\">fantabu...</a><br></p>"

      expect(helper.auto_link(text) { |u| truncate(u, length: 10) }).to eq(result)
    end

    it "accepts a block that returns HTML" do
      text = "My pic: http://example.com/pic.png -- full album here http://example.com/album?a&amp;b=c"
      result = "My pic: <a href=\"http://example.com/pic.png\"><img src=\"http://example.com/pic.png\" width=\"160px\"></a> -- full album here <a href=\"http://example.com/album?a&amp;b=c\">http://example.com/album?a&amp;b=c</a>"

      block = lambda do |link|
        if link =~ /\.(jpg|gif|png|bmp|tif)$/i
          raw "<img src=\"#{link}\" width=\"160px\">"
        else
          link
        end
      end

      expect(helper.auto_link(text, &block)).to eq(result)
    end

    it "sanitizes input when sanitize option is not false" do
      text = "http://www.rubyonrails.com?id=1&num=2<script>alert('malicious!')</script>"
      result = "<a href=\"http://www.rubyonrails.com?id=1&amp;num=2alert('malicious!')\">http://www.rubyonrails.com?id=1&amp;num=2alert('malicious!')</a>"

      expect(helper.auto_link(text)).to eq(result)
      expect(helper.auto_link(text)).to be_html_safe
    end

    it "sanitizes input with the sanitize_options" do
      text = "http://www.rubyonrails.com?id=1&num=2<script>alert('malicious!')</script><a href=\"http://ruby-lang-org\" target=\"_blank\" data-malicious=\"inject\">Ruby</a>"
      result = "<a class=\"big\" href=\"http://www.rubyonrails.com?id=1&amp;num=2alert('malicious!')\">http://www.rubyonrails.com?id=1&amp;num=2alert('malicious!')</a><a href=\"http://ruby-lang-org\" target=\"_blank\">Ruby</a>"

      options = {
        html: { class: "big" },
        sanitize_options: { attributes: %w[target href] }
      }

      expect(helper.auto_link(text, options)).to eq(result)
      expect(helper.auto_link(text, options)).to be_html_safe
    end

    it "doesn't sanitize input when sanitize option is false" do
      text = "http://www.rubyonrails.com?id=1&num=2<script>alert('malicious!')</script>"
      result = "<a href=\"http://www.rubyonrails.com?id=1&num=2\">http://www.rubyonrails.com?id=1&num=2</a><script>alert('malicious!')</script>"

      expect(helper.auto_link(text, sanitize: false)).to eq(result)
      expect(helper.auto_link(text, sanitize: false)).not_to be_html_safe
    end

    it "auto links other protocols" do
      [
        "ftp://example.com/file.txt",
        "https://example.com/file.txt"
      ].each do |input|
        expect(helper.auto_link(input)).to eq("<a href=\"#{input}\">#{input}</a>")
      end
    end

    it "doesn't auto link already linked urls" do
      [
        "<a href=\"http://www.rubyonrails.com\">Ruby on Rails</a>",
        "<a href=\"http://www.example.com\">www.example.com</a>",
        "<a href=\"http://www.example.com\"><b>www.example.com</b></a>",
        "<a href=\"#close\">close</a> <a href=\"http://www.example.com\"><b>www.example.com</b></a>"
      ].each do |input|
        expect(helper.auto_link(input)).to eq(input)
      end
    end

    it "doesn't auto link already linked urls when sanitize is false" do
      text = "<a href=\"http://www.example.com\" rel=\"nofollow\">www.example.com</a>"
      result = "<a href=\"http://www.example.com\" rel=\"nofollow\">www.example.com</a>"

      expect(helper.auto_link(text, sanitize: false)).to eq(result)
    end

    it "doesn't auto link already linked urls when using sanitize_options" do
      text = "<a href=\"#close\">close</a> <a href=\"http://www.example.com\" target=\"_blank\" data-ruby=\"ror\"><b>www.example.com</b></a>"
      result = "<a href=\"#close\">close</a> <a href=\"http://www.example.com\" target=\"_blank\" data-ruby=\"ror\"><b>www.example.com</b></a>"

      expect(helper.auto_link(text, sanitize_options: { attributes: %w[href target data-ruby] })).to eq(result)
    end

    it "doesn't auto link already linked mailto: urls" do
      text = "<a href=\"mailto:david@loudthinking.com\">Mail me</a>"
      result = "<a href=\"mailto:david@loudthinking.com\">Mail me</a>"

      expect(helper.auto_link(text)).to eq(result)
    end

    it "handles malicious attributes" do
      text = "<p>http://api.rubyonrails.com/Foo.html\"onmousemove=\"prompt()</p>"
      result = "<p><a href=\"http://api.rubyonrails.com/Foo.html\">http://api.rubyonrails.com/Foo.html</a>\"onmousemove=\"prompt()</p>"

      expect(helper.auto_link(text)).to eq(result)
    end

    it "auto links urls at the end of the line" do
      text = "<p>http://api.rubyonrails.com/Foo.html<br>http://www.ruby-doc.org/core/Bar.html<br></p>"
      result = "<p><a href=\"http://api.rubyonrails.com/Foo.html\">http://api.rubyonrails.com/Foo.html</a><br><a href=\"http://www.ruby-doc.org/core/Bar.html\">http://www.ruby-doc.org/core/Bar.html</a><br></p>"

      expect(helper.auto_link(text)).to eq(result)
    end

    it "is marked as HTML safe" do
      [
        nil,
        "",
        "hello santiago@wyeworks.com",
        "hello santiago@wyeworks.com <script>alert('malicious!')</script>",
        "hello http://www.rubyonrails.org"
      ].each do |input|
        expect(helper.auto_link(input)).to be_html_safe
      end
    end

    it "is not marked as HTML safe when sanitize is false" do
      [
        "hello",
        "hello santiago@wyeworks.com",
        "hello http://www.rubyonrails.org"
      ].each do |input|
        expect(helper.auto_link(input, sanitize: false)).not_to be_html_safe
      end
    end

    it "auto links email addresses" do
      text = "aaron@tenderlovemaking.com"
      result = "<a href=\"mailto:aaron@tenderlovemaking.com\">aaron@tenderlovemaking.com</a>"

      expect(helper.auto_link(text)).to eq(result)
    end

    it "auto links email addresses with special chars" do
      text = "andre$la*+r-a.o'rea=l~ly@tenderlovemaking.com"
      result = "<a href=\"mailto:andre%24la%2A%2Br-a.o%27rea%3Dl%7Ely@tenderlovemaking.com\">andre$la*+r-a.o&#39;rea=l~ly@tenderlovemaking.com</a>"

      expect(helper.auto_link(text)).to eq(result)
    end

    it "parses urls correctly" do
      urls = %w(
        http://www.rubyonrails.com
        http://www.rubyonrails.com:80
        http://www.rubyonrails.com/~minam
        https://www.rubyonrails.com/~minam
        http://www.rubyonrails.com/~minam/url%20with%20spaces
        http://www.rubyonrails.com/foo.cgi?something=here
        http://www.rubyonrails.com/foo.cgi?something=here&and=here
        http://www.rubyonrails.com/contact;new
        http://www.rubyonrails.com/contact;new%20with%20spaces
        http://www.rubyonrails.com/contact;new?with=query&string=params
        http://www.rubyonrails.com/~minam/contact;new?with=query&string=params
        http://en.wikipedia.org/wiki/Wikipedia:Today%27s_featured_picture_%28animation%29/January_20%2C_2007
        http://www.mail-archive.com/rails@lists.rubyonrails.org/
        http://www.amazon.com/Testing-Equal-Sign-In-Path/ref=pd_bbs_sr_1?ie=UTF8&s=books&qid=1198861734&sr=8-1
        http://en.wikipedia.org/wiki/Texas_hold%39em
        https://www.google.com/doku.php?id=gps:resource:scs:start
        http://connect.oraclecorp.com/search?search[q]=green+france&search[type]=Group
        http://of.openfoundry.org/projects/492/download#4th.Release.3
        http://maps.google.co.uk/maps?f=q&q=the+london+eye&ie=UTF8&ll=51.503373,-0.11939&spn=0.007052,0.012767&z=16&iwloc=A
        http://около.кола/колокола
      )

      urls.each do |url|
        expect(helper.auto_link(url)).to eq("<a href=\"#{CGI.escapeHTML(url)}\">#{CGI.escapeHTML(url)}</a>")
      end
    end

    it "handles trailing equals on links" do
      text = "http://www.rubyonrails.com/foo.cgi?trailing_equals="
      result = "<a href=\"http://www.rubyonrails.com/foo.cgi?trailing_equals=\">http://www.rubyonrails.com/foo.cgi?trailing_equals=</a>"

      expect(helper.auto_link(text)).to eq(result)
    end

    it "handles trailing ampersands on links" do
      text = "http://www.rubyonrails.com/foo.cgi?trailing_ampersand=value&"
      result = "<a href=\"http://www.rubyonrails.com/foo.cgi?trailing_ampersand=value&amp;\">http://www.rubyonrails.com/foo.cgi?trailing_ampersand=value&amp;</a>"

      expect(helper.auto_link(text)).to eq(result)
    end

    it "doesn't timeout when parsing odd email input" do
      inputs = %W(
        foo@...................................
        foo@........................................
        foo@.............................................

        #{"foo" * 20000}@
      )

      inputs.each do |input|
        Timeout.timeout(0.2) do
          expect(helper.auto_link(input)).to eq(input)
        end
      end
    end
  end
end
