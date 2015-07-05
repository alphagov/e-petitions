module SharingHelper
  def share_via_facebook(petition, options = {})
    link_to(share_button(:facebook), share_via_facebook_url(petition), options)
  end

  def share_via_facebook_url(petition)
    "http://www.facebook.com/sharer.php?#{share_via_facebook_params(petition)}"
  end

  def share_via_email(petition, options = {})
    link_to(share_button(:email), share_via_email_url(petition), options)
  end

  def share_via_email_url(petition)
    "mailto:?#{share_via_email_params(petition)}"
  end

  def share_via_twitter(petition, options = {})
    link_to(share_button(:twitter), share_via_twitter_url(petition), options)
  end

  def share_via_twitter_url(petition)
    "http://twitter.com/share?#{share_via_twitter_params(petition)}"
  end

  def share_via_whatsapp(petition, options = {})
    link_to(share_button(:whatsapp), share_via_whatsapp_url(petition), options)
  end

  def share_via_whatsapp_url(petition)
    "whatsapp://send?#{share_via_whatsapp_params(petition)}"
  end

  private

  def share_via_facebook_params(petition)
    { t: share_title(petition), u: petition_url(petition) }.to_query
  end

  def share_via_email_params(petition)
    { subject: share_title(petition), body: petition_url(petition) }.to_query
  end

  def share_via_twitter_params(petition)
    { text: share_title(petition), url: petition_url(petition) }.to_query
  end

  def share_via_whatsapp_params(petition)
    { text: "#{share_title(petition)}\n#{petition_url(petition)}" }.to_query
  end

  def share_title(petition)
    t(:share_title, scope: :petitions, petition: petition.action)
  end

  def share_button(service)
    t(:"#{service}.html", scope: :"petitions.sharing")
  end
end
