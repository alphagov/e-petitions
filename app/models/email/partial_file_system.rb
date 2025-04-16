module Email
  class PartialFileSystem
    def self.read_template_file(name)
      partial = Email::Partial.find_by(name: name)
      partial && partial.content
    end
  end
end
