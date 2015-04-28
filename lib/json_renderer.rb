require 'fileutils'

class JsonRenderer
  def render_all_petitions
    FileUtils.mkdir_p(dir)
    File.open("#{dir}.json", "w") do |file|
      file.write(Rabl::Renderer.json(Petition.visible, 'api/petitions/index', :view_path => 'app/views'))
    end
  end

  def render_individual_over_threshold_petitions
    FileUtils.mkdir_p(dir)
    Petition.visible.find(:all, :conditions => "signature_count > 999").each do |petition|
      File.open("#{dir}/#{petition.id}.json", "w") do |file|
        file.write(Rabl::Renderer.json(petition, 'api/petitions/show', :view_path => 'app/views'))
      end
    end
  end

  private

  def dir
    @dir ||= Rails.root + "public/api/petitions"
  end

end
