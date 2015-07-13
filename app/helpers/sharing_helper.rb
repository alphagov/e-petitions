module SharingHelper
  def share_via_facebook(petition, options = {})
    link_to(share_button(:facebook), share_via_facebook_url(petition), options)
  end

  def share_via_facebook_url(petition)
    "https://www.facebook.com/sharer/sharer.php?#{share_via_facebook_params(petition)}"
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
    "https://twitter.com/intent/tweet?#{share_via_twitter_params(petition)}"
  end

  def share_via_whatsapp(petition, options = {})
    link_to(share_button(:whatsapp), share_via_whatsapp_url(petition), options)
  end

  def share_via_whatsapp_url(petition)
    "whatsapp://send?#{share_via_whatsapp_params(petition)}"
  end

  private

  def share_via_facebook_params(petition)
    share_params(u: petition_url(petition), ref: "responsive")
  end

  def share_via_email_params(petition)
    share_params(subject: share_title(petition), body: petition_url(petition))
  end

  def share_via_twitter_params(petition)
    share_params(text: share_title(petition), url: petition_url(petition))
  end

  def share_via_whatsapp_params(petition)
    share_params(text: "#{share_title(petition)}\n#{petition_url(petition)}")
  end

  def share_title(petition)
    t(:share_title, scope: :petitions, petition: petition.action)
  end

  def share_params(hash)
    hash.to_query.gsub('+', '%20')
  end

  def share_button(service)
    t(:"#{service}.html", scope: :"petitions.sharing")
  end
end
