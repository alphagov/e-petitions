namespace :epets do
  namespace :paperclip do
    task migrate: :environment do
      require "aws-sdk-s3"

      helper = Module.new do
        extend ActiveSupport::Concern

        included do
          class_attribute :paperclip_path, instance_writer: false

          has_one_attached :image
        end

        module ClassMethods
          def needs_migrating
            where(arel_table[:commons_image_file_size].gt(0))
          end
        end

        def id_path
          ("%09d" % id).scan(/\d{3}/).join("/")
        end

        def source_file
          "#{paperclip_path}/#{id_path}/original/#{commons_image_file_name}"
        end

        def migrate_image(bucket)
          object = bucket.object(source_file)
          puts "Migrating: #{source_file}"

          if object.exists?
            response = object.get

            self.image = {
              io: response.body,
              filename: commons_image_file_name,
              content_type: commons_image_content_type
            }

            save!

            puts "Done!"
          end
        end
      end

      archived_debate_outcomes = Class.new(ActiveRecord::Base) do
        include helper

        self.table_name = "archived_debate_outcomes"
        self.paperclip_path = "archived/debate_outcomes/commons_images"

        def self.name
          "Archived::DebateOutcome"
        end
      end

      debate_outcomes = Class.new(ActiveRecord::Base) do
        include helper

        self.table_name = "debate_outcomes"
        self.paperclip_path = "debate_outcomes/commons_images"

        def self.name
          "DebateOutcome"
        end
      end

      s3 = Aws::S3::Resource.new
      bucket = s3.bucket(ENV.fetch("UPLOADED_IMAGES_S3_BUCKET"))

      archived_debate_outcomes.needs_migrating.find_each do |outcome|
        outcome.migrate_image(bucket)
      end

      debate_outcomes.needs_migrating.find_each do |outcome|
        outcome.migrate_image(bucket)
      end
    end
  end
end
