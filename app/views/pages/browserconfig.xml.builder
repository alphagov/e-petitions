cache :browserconfig, expires_in: 5.minutes do
  xml.instruct! :xml, version: "1.0"
  xml.browserconfig do
    xml.msapplication do
      xml.tile do
        xml.square70x70logo src: path_to_image('os-social/windows/tiny.png')
        xml.square150x150logo src: path_to_image('os-social/windows/square.png')
        xml.wide310x150logo src: path_to_image('os-social/windows/wide.png')
        xml.square310x310logo src: path_to_image('os-social/windows/large.png')
        xml.TileColor "#008800"
      end
    end
  end
end
