if current_user
  json.time_remaining current_user.time_remaining(last_request_at)
else
  json.time_remaining 0
end
