Pod::Spec.new do |s|
  s.name         = "BRNetwork"  # 框架的名称
  s.version      = "2.3.0"  # 框架的版本号
  s.summary      = "BRNetwork是一个iOS轻量级网络请求库，封装了网络请求、本地数据缓存与SSE流式通信" # 框架的简单介绍
  # 框架的详细描述(详细介绍，要比简介长)
  s.description  = <<-DESC
  BRNetwork是一个基于AFNetworking封装的轻量级网络请求工具；BRNetworkYY是基于BRNetwork并二次封装YYCache，整合了数据缓存功能；BRNetworkSSE是一个基于SSE(Server-Sent Events)协议封装的网络请求类，专为AI大模型的流式数据响应设计，支持实时接收模型返回的数据流。
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
  
  # 本地框架源文件的位置（包含所有文件）
  s.default_subspec = 'Default'
  
  # 二级目录（根目录是s，使用s.subspec设置子目录，这里设置子目录为ss）
  s.subspec 'Default' do |ss|
    ss.dependency 'BRNetwork/YY'
    ss.dependency 'BRNetwork/SSE'
  end
  
  s.subspec 'Core' do |ss|
    ss.source_files = 'BRNetwork/Core/*.{h,m}'
    ss.dependency "AFNetworking"
  end
  
  s.subspec 'YY' do |ss|
    ss.source_files = 'BRNetwork/YY/*.{h,m}'
    ss.dependency "BRNetwork/Core"
    ss.dependency 'YYCache_BR'
  end
  
  s.subspec 'SSE' do |ss|
    ss.source_files = 'BRNetwork/SSE/*.{h,m}'
  end
  
end
