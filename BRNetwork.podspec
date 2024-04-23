Pod::Spec.new do |s|
  s.name         = "BRNetwork"  # 框架的名称
  s.version      = "2.0.6"  # 框架的版本号
  s.summary      = "BRNetwork是一个基于AFNetworking和YYCache封装的轻量级网络请求工具" # 框架的简单介绍
  # 框架的详细描述(详细介绍，要比简介长)
  s.description  = <<-DESC
                    BRNetwork是一个基于AFNetworking和YYCache封装的轻量级网络请求工具,支持本地数据缓存. Support the Objective - C language.
                DESC
  s.homepage     = "https://github.com/agiapp/BRNetwork"  # 框架的主页
  s.license      = { :type => "MIT", :file => "LICENSE" } # 证书类型
  s.author       = { "renbo" => "developer@irenb.com" }  # 作者
  s.social_media_url = 'https://www.irenb.com'  # 社交网址
  
  s.platform     = :ios, '9.0'    # 框架支持的平台和版本
  s.ios.deployment_target = '9.0' # 最低支持的target
  s.source       = { :git => "https://github.com/agiapp/BRNetwork.git", :tag => s.version.to_s }  # GitHib下载地址和版本
  s.resource_bundles = { 'BRNetwork.Privacy' => 'BRNetwork/PrivacyInfo.xcprivacy' }  # 隐私清单
  s.requires_arc = true   # 框架要求ARC环境下使用
  
  s.default_subspec = 'Core'  # 默认集成的子模块（全部）
  
  # 二级目录（根目录是s，使用s.subspec设置子目录，这里设置子目录为ss）
  s.subspec 'Core' do |ss|
    ss.source_files = 'BRNetwork/Core/*.{h,m}'
    ss.dependency 'AFNetworking'
    ss.dependency 'BRNetwork/YYCache'
  end
  
  s.subspec 'YYCache' do |ss|
    ss.source_files = 'BRNetwork/YYCache/*.{h,m}'
    ss.library = 'sqlite3'
    ss.frameworks = 'UIKit', 'CoreFoundation', 'QuartzCore'
  end
 
end
