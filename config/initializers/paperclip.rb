# For production-like environments we store items in an S3 bucket.
#
# However, we don't want to expose the HTTPS urls, since if we ever move to
# a different hosting platform we don't want to deal with old links.
# We also don't want to have to get an 'assets.domainname.example' SSL
# certificate, so instead we proxy requests from the frontend webservers for
# any url that starts with /attachments/ to the S3 bucket

if ENV['UPLOADED_IMAGES_S3_BUCKET']
  # Given that the Paperclip S3 code doesn't let you override interpolation the
  # same way as other storage, types, we need to construct a custom URL.
  def build_path_fragment(attachment, style)
    # The S3 bucket URL would be something like:
    #   https://s3-eu-west-1.amazonaws.com/bucket-name-here/debate_outcomes/commons_images/000/000/001/2x/xyz.jpg
    # We want:
    #   /debate_outcomes/commons_images/000/000/001/2x/xyz.jpg
    [
      Paperclip::Interpolations.class(attachment, style),         # debate_outcomes
      Paperclip::Interpolations.attachment(attachment, style),    # commons_images
      Paperclip::Interpolations.id_partition(attachment, style),  # 000/000/001
      Paperclip::Interpolations.style(attachment, style),         # 2x/
      Paperclip::Interpolations.filename(attachment, style)       # xyz.jpg
    ].join('/')
  end

  Paperclip.interpolates(:s3_custom_attachment_url) do |attachment, style|
    '/' + [
      ENV.fetch('UPLOADED_IMAGES_PROXY_FRAGMENT', 'attachments'),
      build_path_fragment(attachment, style)
    ].join('/')
  end

  Paperclip.interpolates(:s3_custom_path_url) do |attachment, style|
    '/' + build_path_fragment(attachment, style)
  end

  Paperclip::Attachment.default_options.merge!(
    storage: :s3,
    s3_region: 'eu-west-1',
    bucket: ENV.fetch('UPLOADED_IMAGES_S3_BUCKET'),
    url: ':s3_custom_attachment_url'
  )
  Paperclip::Attachment.default_options[:path] = ':s3_custom_path_url'
end
