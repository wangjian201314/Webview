//
//  MTBaseWebViewController.h
//  MTCommon
//
//  Created by 辛忠志 on 2018/7/31.
//  Copyright © 2018年 X了个J. All rights reserved.
//

/**
 备注文档
 1、基类实现基于  <WebKit/WebKit.h>  使用 WKWebView 来完成网页控制器的展示功能
 2、利用KVO监听的机制 随时监听 web Title 文字的变化
 3、支持多种类型 展示文件  word TXT excel PPT PDF 展示相应文件
 4、支持自定义导航栏 自定义title 接口都以暴漏出来
 5、支持js和oc 交互
 6、支持oc和js 交互
 */


#import "MTBaseViewController.h"
#import <WebKit/WebKit.h>


#pragma mark - MTWebBridgeDelegate
@protocol MTWebBridgeDelegate <NSObject>

@required

/**
 *  js调oc方法列表
 *  oc提供方法名, 如果带参也只需要方法字符串即可, 不需要 ':'
 *
 *  @return oc方法列表 可以为空
 */
- (NSArray<NSString *> *)jsToOcMethodsInWebBridge;


@optional

/**
 *  oc 调用 js 的代理回调～
 *
 *  @param data  oc 给 js 发消息 js给OC返回的内容
 *  @param error oc 给 js 发消息 js给OC返回的错误信息
 */
-(void)ocToJsPrintData:(id) data error:(NSError *)  error;


/**
 *  js 调用 oc 的代理回调
 *
 *  @param method    方法名
 *
 *  @param body      携带内容体 (js 调该方法传过来的)
 */
- (void)jsToOcMethod:(NSString *)method body:(id)body;


/**
 *  通过接收JS传出消息的name进行捕捉的回调方法 (系统代理)
 *
 *  message.name        方法名
 *  message.body        参数内容
 *  message.frameInfo   布局相关信息
 */
- (void)systemContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message;

@end


#pragma mark - MTBaseWebViewURLOption

/**
 *  配置web控制器url
 *  一般拼接规则  【http(https)://】+ 【serverUrl】+【commonUrl】+【urlParams】
 *  例如: 【http://】 【120.198.253.63:8093/gdsnew/test】 【/webapp/dist/resourcePool.html】
 *
 *  如果给定的地址就是一个完整的地址，不随环境变化的话，可直接设置【commonUrl】
 *  例如: https://120.198.253.241:50000/jk-app-web/index.html
 */
@interface MTBaseWebViewURLOption : NSObject

/** 环境地址 */
//@property (nonatomic,copy,rea) NSString *serverUrl;

/** 通用网址 */
@property (nonatomic,copy) NSString *commonUrl;

/** 是否使用框架服务器地址 默认YES （配置文件中配置0和1即可）*/
@property (nonatomic,assign) BOOL isUseServerUrl;

/** 是否支持网址转码 默认为YES （配置文件中配置0和1即可）*/
@property (nonatomic,assign) BOOL isUrlTranscoding;

/** url中额外参数可加在urlParams中 */
@property (nonatomic, strong) NSDictionary *urlParams;

/** 某个项目中通用的参数，一般在分类中重写getter方法即可 */
@property (nonatomic, strong, readonly) NSDictionary *commonUrlParams;



@end


#pragma mark - MTBaseWebViewNavOption

/** 导航栏样式对照表（请不要直接设置数值4,会让导航栏上只有一个刷新按钮,没有回退按钮） */
/**     左       右
 *  1   <           （默认样式）
 *  2   x
 *  3   < x
 *  4           ~
 *  5   <       ~
 *  6   x       ~
 *  7   < x     ~
 */
typedef NS_ENUM(NSInteger, MTBaseWebViewNavType) {
    MTBaseWebViewNavType_Back       = (1<<0),
    MTBaseWebViewNavType_Exit       = (1<<1),
    MTBaseWebViewNavType_Refresh    = (1<<2),
};

/** 配置web控制器导航栏 */
@interface MTBaseWebViewNavOption : NSObject

/**
 *  导航栏样式 （配置文件中配置对照表中的数值即可）
 *  如果要对应数值5 按以下方式赋值
 *  navType =  MTBaseWebViewNavType_Back | MTBaseWebViewNavType_Refresh
 */
@property (nonatomic, assign) MTBaseWebViewNavType navType;

/** 默认标题  如果监听到网页Title，则使用监听到的title 如果没有，则使用默认标题 */
@property (nonatomic, copy) NSString *navTitle;

/** 是否需要进度条 默认YES （配置文件中配置0和1即可）*/
@property (nonatomic, assign) BOOL isShowProgress;

/** 是否支持web页面手动滑动返回 默认YES （配置文件中配置0和1即可）*/
@property (nonatomic, assign) BOOL isAllowsBack;

/** 添加可自定义导航栏右按钮（若要隐藏右侧按钮，可设置一个透明item）  (自定义导航栏 不传递默认展示 小程序样式的 导航栏 < X  ~) */
@property (nonatomic, strong) NSArray *rightBarItems;


@end



#pragma mark - MTBaseWebViewNavFuncOption

/** 配置web控制器导航栏上的功能按钮 */
@interface MTBaseWebViewNavFuncOption : NSObject

/** 是否需要导航栏功能按钮 默认为NO  （配置文件中配置0和1即可）*/
@property (nonatomic, assign) BOOL isShowMoreFuncBtn;

/** Optional */


/** 多功能弹窗的row高度                                       默认为:50*/
@property (nonatomic, assign) CGFloat           row_height;
/** 多功能弹窗的row宽度                                       默认为:120*/
@property (nonatomic, assign) CGFloat           row_width;
/** 多功能弹窗距离上 轴的距离                                   默认为:30*/
@property (nonatomic, assign) CGFloat           frame_width_x;
/** 多功能弹窗距离右 轴的距离                                   默认为:28*/
@property (nonatomic, assign) CGFloat           frame_width_y;
/** 多功能弹窗文字的颜色                                       默认为:白色*/
@property (nonatomic, strong) UIColor           * _Nonnull titleTextColor;
/** 多功能弹窗数据源(titles) ps: titles和images 是一一配对的哦   默认为:@[] */
@property (nonatomic, strong) NSArray           * _Nonnull dataArray;
/** 多功能弹窗数据源(images) ps: titles和images 是一一配对的哦   默认为:@[]*/
@property (nonatomic, strong) NSArray           * _Nonnull images;
/** 多功能弹窗背景的颜色                                       默认: 黑色*/
@property (nonatomic, strong) UIColor           * _Nonnull backGroundColor;
/** 多功能弹窗背景的颜色                                       默认: 13*/
@property (nonatomic, assign) CGFloat           fontSize;
/** 多功能弹窗背景的颜色                                       默认: 居中*/
@property (nonatomic, assign) NSTextAlignment   textAlignment;
@end




#pragma mark - MTBaseWebViewController


/**
 *  名通web控制器基类
 */
@interface MTBaseWebViewController : MTBaseViewController<WKNavigationDelegate>

/**
 *  oc和js交互代理 实现js和oc之间的传值
 */
@property (nonatomic, weak) id<MTWebBridgeDelegate>  bridgeDelegate;



/**
 *
 */
@property (strong,nonatomic) WKWebView * webView;

/**
 *  加载本地文件 默认为NO
 */
@property (nonatomic, assign) BOOL isLoadLocalFile;

/**
 *  本地文件路径
 */
@property (nonatomic, copy) NSString *localfilePath;


/**
 *  url配置项
 *
 *  urlOption的三个参数可以通过 KVC 方式传给web控制器，内部会处理
 *  这种方式适用于配置文件配置入口时的传值方式，其他情况请直接设置urlOption的属性即可
 *
 ** 使用  setValue:forKey: 方法
 *  [webvc setValue:@{@"name":@"xiaosan"}   forKey:@"urlParams"];
 *  [webvc setValue:@(NO)                   forKey:@"isUrlTranscoding"];
 *  [webvc setValue:@"/webapp/testpath"     forKey:@"commonUrl"];
 *
 ** 使用 setValuesForKeysWithDictionary: 方法
 *  [webvc setValuesForKeysWithDictionary:@{@"urlParams":@{@"name":@"xiaosan"}, @"isUrlTranscoding":@(NO), @"commonUrl":@"/webapp/testpath"}];
 */
@property (nonatomic, strong, readonly) MTBaseWebViewURLOption *urlOption;


/**
 *  导航栏配置项
 */
@property (nonatomic, strong, readonly) MTBaseWebViewNavOption *navOption;


/**
 *  导航栏功能按钮配置项
 */

@property (nonatomic, strong, readonly) MTBaseWebViewNavFuncOption *navFuncOption;

/**
 *  oc 调用 js的点击事件
 *  备注: 当你想实现 oc调用js 你想知道js给你的回调 必须实现 MTBaseWebViewControllerOCorJSDelegate 代理方法
 *
 *  @param  OcToJsKey       oc访问 js 的key ( js当中暴漏出来 的方法 和 客户端协调好 名称保持一致)
 *  @param  OcToJsParams    oc访问 js 的参数 (字典值)
 */
-(void)ocToJsClick:(NSString *)OcToJsKey OcToJsParams:(NSDictionary *)OcToJsParams;


/**
 *  刷新webview
 */
- (void)reload;

#pragma mark - MTSelectIndexPathDelegate
/**
 * 多功能下拉弹窗点击代理
 */
- (void)selectIndexPathRow:(NSInteger )index;

@end
