# Based on http://www.benr75.com/articles/2008/01/04/attachment_fu-now-with-local-file-fu
#
# This is to help get around problems with migrating local files into attachment_fu files
require 'tempfile'
class LocalFile
  IMAGE_MIME_TYPES = { ".gif" => "image/gif", ".ief" => "image/ief", ".jpe" => "image/jpeg", ".jpeg" => "image/jpeg", ".jpg" => "image/jpeg", ".pbm" => "image/x-portable-bitmap", ".pgm" => "image/x-portable-graymap", ".png" => "image/png", ".pnm" => "image/x-portable-anymap", ".ppm" => "image/x-portable-pixmap", ".ras" => "image/cmu-raster", ".rgb" => "image/x-rgb", ".tif" => "image/tiff", ".tiff" => "image/tiff", ".xbm" => "image/x-xbitmap", ".xpm" => "image/x-xpixmap", ".xwd" => "image/x-xwindowdump" }.freeze 

  # The filename, *not* including the path, of the "uploaded" file
  attr_reader :original_filename
  # The content type of the "uploaded" file
  attr_reader :content_type

  def initialize(path, options = {})
    raise "#{path} file does not exist" unless File.exist?(path)
    content_type ||= options[:content_type] || IMAGE_MIME_TYPES[File.extname(path).downcase] || 'application/octet-stream'
    raise "Unrecognized MIME type for #{path}" unless content_type
    @content_type = content_type
    @original_filename = options[:original_filename] || File.basename(path)
    @tempfile = Tempfile.new(@original_filename)
    FileUtils.copy_file(path, @tempfile.path)
  end

  def path #:nodoc:
    @tempfile.path
  end
  alias local_path path

  def method_missing(method_name, *args, &block) #:nodoc:
    @tempfile.send(method_name, *args, &block)
  end
end