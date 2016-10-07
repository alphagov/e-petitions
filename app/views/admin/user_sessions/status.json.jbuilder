if current_session
  json.time_remaining current_session.time_remaining
else
  json.time_remaining 0
end
