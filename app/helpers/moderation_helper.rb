module ModerationHelper
  def moderation_delay?
    Petition.in_moderation.count >= Site.threshold_for_moderation_delay
  end

  def moderation_delay_message
    Site.moderation_delay_message
  end
end
