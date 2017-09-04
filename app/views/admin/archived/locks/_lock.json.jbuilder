if user = @petition.locked_by
  json.locked true
  json.locked_at @petition.locked_at
  json.locked_by do
    json.id user.id
    json.name user.pretty_name
  end
else
  json.locked false
end
