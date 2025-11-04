json.name "Petitions"
json.display "standalone"
json.orientation "portrait"
json.start_url "/"

json.icons do
  json.child! do
    json.src      path_to_image("os-social/icon-192.png")
    json.type     "image/png"
    json.sizes    "192x192"
  end

  json.child! do
    json.src      path_to_image("os-social/icon-mask.png")
    json.sizes    "512x512"
    json.type     "image/png"
    json.purpose  "maskable"
  end

  json.child! do
    json.src      path_to_image("os-social/icon-512.png")
    json.sizes    "512x512"
    json.type     "image/png"
  end
end
