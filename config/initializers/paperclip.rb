# Add a custom interpolation for S3 to prefix the url with '/attachments'.
# This is so we don't publish asset urls with S3 domains, making it easier
# to migrate to different hosting in the future.

Paperclip.interpolates(:s3_attachment_url) do |attachment, style|
  "/attachments#{attachment.path(style)}"
end
