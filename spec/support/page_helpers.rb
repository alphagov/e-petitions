module Page
  module Sanitizer
    def sanitize_page(page)
      body = page.source.dup
      body.gsub!(/(href=".*?)\?\d+/, '\1')
      body.gsub!(/(src=".*?)\?\d+/, '\1')

      strip_onpaste_element_used_to_disable_pasting_emails(body)
      body
    end

    def strip_onpaste_element_used_to_disable_pasting_emails(body)
      body.gsub!(/(onpaste=\".*?\")/, '')
    end
  end
end
