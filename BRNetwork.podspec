Pod::Spec.new do |s|
  # 框架的名称
  s.name         = "BRNetwork"
  # 框架的版本号
  s.version      = "1.2.0"
  # 框架的简单介绍
  s.summary      = "BRNetwork是一个基于AFNetworking和YYCache封装的轻量级网络请求工具"
  # 框架的详细描述(详细介绍，要比简介长)
  s.description  = <<-DESC
                    BRNetwork是一个基于AFNetworking和YYCache封装的轻量级网络请求工具,支持本地数据缓存. Support the Objective - C language.
                DESC
  # 框架的主页
  s.homepage     = "https://github.com/91renb/BRNetwork"
  # 证书类型
  s.license      = { :type => "MIT", :file => "LICENSE" }

  # 作者
  s.author             = { "任波" => "developer@irenb.com" }
  # 社交网址
  s.social_media_url = 'https://www.irenb.com'
  
  # 框架支持的平台和版本
  s.platform     = :ios, "9.0"

  # GitHib下载地址和版本
  s.source       = { :git => "https://github.com/91renb/BRNetwork.git", :tag => s.version.to_s }

  # 本地框架源文件的位置
  #s.source_files  = "BRNetwork/*.{h,m}"
  # 框架包含的资源包
  #s.resources  = "xx"

  # 框架要求ARC环境下使用
  s.requires_arc = true
  
  # 默认集成的子模块（全部）
  s.default_subspec = 'Core', 'YYCache'
  
  # 核心网络请求库封装（不带缓存库）
  s.subspec 'Core' do |ss|
    ss.source_files = 'BRNetwork/Core'
    ss.dependency 'AFNetworking'
  end
  
  # 缓存库
  s.subspec 'YYCache' do |ss|
    ss.source_files = 'BRNetwork/YYCache'
  end
 
end
