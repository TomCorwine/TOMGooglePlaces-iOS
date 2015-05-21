Pod::Spec.new do |s|
  s.name         = "TOMGooglePlaces"
  s.version      = "1.0.0"
  s.summary      = "A Library for auto completing addresses using Google Places."
  s.description  = <<-DESC
                   A Library for auto completing addresses using Google Places.
                   DESC
  s.homepage     = "http://github.com/TomCorwine/TOMGooglePlaces-iOS"
  s.license      = "Propriatary"
  s.author       = { "Tom Corwine" => "tc@corwine.org" }
  s.source       = { :git => "http://github.com/TomCorwine/TOMGooglePlaces-iOS", :tag => "1.0.0" }

  s.requires_arc = true
  s.source_files  = "**/*.{h,m}"

  s.public_header_files = "**/*.h"
end

