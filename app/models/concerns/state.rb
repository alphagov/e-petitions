module State
  PENDING_STATE = 'pending'
  VALIDATED_STATE = 'validated'
  NEEDS_MODERATION_STATE = 'needs_moderation'
  OPEN_STATE = 'open'
  REJECTED_STATE = 'rejected'
  HIDDEN_STATE = 'hidden'
  STATES = [PENDING_STATE, VALIDATED_STATE, NEEDS_MODERATION_STATE,
            OPEN_STATE, REJECTED_STATE, HIDDEN_STATE]
  VISIBLE_STATES = [OPEN_STATE, REJECTED_STATE]
  MODERATED_STATES = [OPEN_STATE, REJECTED_STATE, HIDDEN_STATE]

  # this is not a state that appears in the state column since a closed petition has
  # a state that is 'open' but the 'closed at' date time is in the past
  CLOSED_STATE = 'closed'
  SELECTABLE_STATES = [OPEN_STATE, CLOSED_STATE, REJECTED_STATE, HIDDEN_STATE]
  SEARCHABLE_STATES = [OPEN_STATE, CLOSED_STATE, REJECTED_STATE]
end
