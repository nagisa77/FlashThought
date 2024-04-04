Pod::Spec.new do |spec|
    spec.name         = "FlashThoughtPlatform"
    spec.version      = "0.1.0"
    spec.summary      = "A short description of FlashThought."
    spec.description  = <<-DESC
                         FlashThought is a framework for doing something very interesting.
                         DESC
    spec.homepage     = "http://example.com/FlashThought"
    spec.license      = { :type => "MIT", :file => "LICENSE" }
    spec.author       = { "Your Name" => "your_email@example.com" }
    spec.platform     = :ios, "13.0"
    spec.source       = { :git => "http://example.com/FlashThought.git", :tag => "#{spec.version}" }
    spec.source_files  = "FlashThoughtPlatform/**/*.{h,m}"
    spec.exclude_files = "Classes/Exclude"
    spec.license      = { :type => "MIT", :file => "LICENSE" }
    
    # Dependencies
    spec.dependency "Firebase/Auth"
    spec.dependency 'Firebase/Database'
    spec.dependency 'GoogleSignIn'
  end
  
