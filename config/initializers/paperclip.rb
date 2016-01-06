# For production-like environments we store items in an S3 bucket.
#
# However, we don't want to expose the HTTPS urls, since if we ever move to
# a different hosting platform we don't want to deal with old links.
# We also don't want to have to get an 'assets.domainname.example' SSL
# certificate, so instead we proxy requests from the frontend webservers for
# any url that starts with /attachments/ to the S3 bucket

if ENV['UPLOADED_IMAGES_S3_BUCKET']
  Paperclip::Attachment.default_options.merge!(
    storage: :fog,
    fog_directory: ENV.fetch('UPLOADED_IMAGES_S3_BUCKET'),
    fog_credentials: {
      use_iam_profile: true,
      provider: 'AWS',
      region: 'eu-west-1',
      scheme: 'https'
    },
    # Proxied to S3 via the webserver
    fog_host: '/attachments'
  )
end
