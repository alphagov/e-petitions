map_preview(@petition) do |preview|
  preview.constituencies do |constituency|
    constituency.polygons do |polygon|
      preview.draw(polygon.path, polygon.stroke_color, polygon.fill_color)
    end
  end
end
