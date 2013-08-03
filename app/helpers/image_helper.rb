# encoding: utf-8

module Helpers
  module ImageHelper
    ###
    # File.expand_path($0):
    #   il path assoluto compreso il file
    # File.dirname($0):
    #   il path assoluto senza il file
    # File.basename($0):
    #   solo il file
    ###
  
    module_function
    
    # ritorna un oggetto di tipo Wx::Icon
    def make_icon(imgname, size = nil, grayscale = false, resize = nil)
  
      if defined? RUBYSCRIPT2EXE
        filename = (size) ? File.join( RUBYSCRIPT2EXE.appdir, 'views', 'images', size.to_s, imgname ) : File.join( RUBYSCRIPT2EXE.appdir, 'views', 'images', imgname )
      else
        filename = (size) ? File.join( File.dirname($0), ApplicationHelper::WXBRA_IMAGES_PATH, size.to_s, imgname ) : ApplicationHelper::WXBRA_IMAGES_PATH
      end
      #    filename = (size) ? File.join( ApplicationHelper::WXBRA_IMAGES_PATH, size.to_s, imgname ) : ApplicationHelper::WXBRA_IMAGES_PATH

      img = Wx::Image.new(filename)
      # image resize
      if resize
        img = img.scale(resize, resize)
      end
    
      # grayscale image
      if grayscale
        img.convert_to_greyscale()
      end
      #    if Wx::PLATFORM == "WXMSW"
      #      img = img.scale(16, 16)
      #    elsif Wx::PLATFORM == "WXGTK"
      #      img = img.scale(22, 22)
      #    end
      # WXMAC can be any size up to 128x128, so don't scale
      icon = Wx::Icon.new
      icon.copy_from_bitmap(Wx::Bitmap.new(img))
      return icon
    end

    # ritorna un oggetto di tipo Wx::Bitmap
    def make_bitmap(imgname)
      filename = File.join(ApplicationHelper::WXBRA_IMAGES_PATH, imgname)

      return Wx::Bitmap.new(filename, Wx::BITMAP_TYPE_PNG)
    end

    # ritorna un oggetto di tipo Wx::Bitmap
    def make_image(imgname, size = nil, grayscale = false, resize = nil)
#      if defined? RUBYSCRIPT2EXE
#        filename = (size) ? File.join( RUBYSCRIPT2EXE.appdir, 'views', 'images', size.to_s, imgname ) : File.join( RUBYSCRIPT2EXE.appdir, 'views', 'images', imgname )
#      else
#        filename = (size) ? File.join( File.dirname($0), ApplicationHelper::WXBRA_IMAGES_PATH, size.to_s, imgname ) : ApplicationHelper::WXBRA_IMAGES_PATH
#      end

      filename = File.join(ApplicationHelper::WXBRA_IMAGES_PATH, imgname)
#      img = Wx::Bitmap.new(filename, Wx::BITMAP_TYPE_PNG)

      img = Wx::Image.new(filename, Wx::BITMAP_TYPE_PNG)
      # image resize
      if resize
        img = img.scale(resize, resize)
      end
    
      # grayscale image
      if grayscale
        img.convert_to_greyscale()
      end

      return img
    end
  end
  
end