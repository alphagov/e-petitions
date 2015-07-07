module CacheHelper
  def last_signature_at
    @_last_signature_at ||= Petition.maximum(:last_signed_at)
  end
end
