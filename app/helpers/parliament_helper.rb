module ParliamentHelper
  def parliament_dissolution_faq_notice(faq_url: Parliament.dissolution_faq_url)
    faq_link_text = t(:"ui.parliament.dissolution_faq_link")
    faq_link = link_to(faq_link_text, faq_url)
    t(:"ui.parliament.dissolution_faq_notice_html", faq_link: faq_link)
  end
end
