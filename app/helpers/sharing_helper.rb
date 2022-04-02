module SharingHelper
  def share_via_facebook(petition, options = {})
    share_button(:facebook, share_params(petition))
  end

  def share_via_email(petition, options = {})
    share_button(:email, share_params(petition))
  end

  def share_via_twitter(petition, options = {})
    share_button(:twitter, share_params(petition))
  end

  def share_via_whatsapp(petition, options = {})
    share_button(:whatsapp, share_params(petition))
  end

  private

  def share_params(petition)
    {
      url: URI.encode_www_form_component(petition_url(petition)),
      action: URI.encode_www_form_component(petition.action).gsub('+', '%20')
    }
  end

  def share_button(service, params)
    t(:"#{service}_html", **({ scope: :"ui.sharing" }.merge(params)))
  end
end
