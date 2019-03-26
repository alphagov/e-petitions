module ModerationHelper
  def moderation_delay?
    Petition.in_moderation.count >= Site.threshold_for_moderation_delay
  end
end
