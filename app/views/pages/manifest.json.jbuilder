json.name "Petitions"
json.display "standalone"
json.orientation "portrait"
json.start_url "/"

json.icons do
  json.child! do
    json.src      path_to_image("os-social/android/launcher-icon-0-75x.png")
    json.sizes    "36x36"
    json.type     "image/png"
    json.density  "0.75"
  end

  json.child! do
    json.src      path_to_image("os-social/android/launcher-icon-1x.png")
    json.sizes    "48x48"
    json.type     "image/png"
    json.density  "1.0"
  end

  json.child! do
    json.src      path_to_image("os-social/android/launcher-icon-1-5x.png")
    json.sizes    "72x72"
    json.type     "image/png"
    json.density  "1.5"
  end

  json.child! do
    json.src      path_to_image("os-social/android/launcher-icon-2x.png")
    json.sizes    "96x96"
    json.type     "image/png"
    json.density  "2.0"
  end

  json.child! do
    json.src      path_to_image("os-social/android/launcher-icon-3x.png")
    json.sizes    "144x144"
    json.type     "image/png"
    json.density  "3.0"
  end

  json.child! do
    json.src      path_to_image("os-social/android/launcher-icon-4x.png")
    json.sizes    "192x192"
    json.type     "image/png"
    json.density  "4.0"
  end
end
