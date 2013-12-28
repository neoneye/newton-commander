Pod::Spec.new do |s|
  s.name         = "PSMTabBarControl"
  s.version      = "1.0.2"
  s.summary      = "Safari-style tabs"
  s.description  = <<-DESC
	 PSMTabBarControl seeks to provide developers with a high-quality, 
	 easy to use GUI to manage an NSTabView (or subclasses) in a manner 
	 similar to Safari's tabbed browsing implementation.  
	 It attempts to add a few features as well.  
	 
	 Here's what you get:
     
	 The look  
	 --------
	 A control/cell architecture that draws the expected tab appearance below a toolbar or similar view.  Included styles work consistently in Aqua, Metal, or customized metal variations by basing fills on the window's background color.  Includes drawing of a close button, and rollover states for the close button and tab cell.  Also provides pop-up button and menu when tabs overflow available space, and support for individual tab progress indicators, icons, and object counters.  Tabs can be drawn sized to fit the string content of the label, or uniformly sized.
	 
	 The functionality
	 -----------------
	 Close button removes tabs, click on a tab cell selects.  Indicators start, stop, and hide if things are hooked up correctly.

	 Extras
	 ------
	 
	 Supports multi-window drag-and-drop reordering of the tabs with aqua-licious animation.

     DESC
  s.homepage     = "https://github.com/neoneye/PSMTabBarControl"
  s.screenshots  = "https://raw.github.com/neoneye/PSMTabBarControl/master/Documents/screenshot1.png"
  s.license      = 'BSD'
  s.author       = { "Simon Strandgaard" => "simon@opcoders.com" }
  s.source       = { :git => "https://github.com/neoneye/PSMTabBarControl.git", :tag => s.version.to_s }

  s.platform     = :osx, '10.9'
  s.osx.deployment_target = '10.9'
  s.requires_arc = true

  s.source_files = 'Classes/**/*.{h,m}'
  s.resources = 'Assets'

  s.ios.exclude_files = 'Classes/osx'
  s.osx.exclude_files = 'Classes/ios'
  s.public_header_files = 'Classes/**/*.h'
  # s.frameworks = 'SomeFramework', 'AnotherFramework'
  # s.dependency 'JSONKit', '~> 1.4'
end
