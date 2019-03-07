//
//  MTBaseWebViewController.m
//  MTCommon
//
//  Created by 辛忠志 on 2018/7/31.
//  Copyright © 2018年 X了个J. All rights reserved.
//

#import "MTBaseWebViewController.h"
#import <WebKit/WebKit.h>
#import "MTGlobalInfo.h"
#import "MTPullDownView.h"/*多功能下拉弹窗*/


#pragma mark - MTBaseWebViewURLOption
@interface MTBaseWebViewURLOption ()
{
    NSString *_originUrl;//只从外部传进来的Url 没有做任何处理的
    NSString *_serverUrl;//服务器地址
}
@property (nonatomic, copy, nullable) void(^setUrlBlock)(void); //设置url完成回调
@end

@implementation MTBaseWebViewURLOption

+ (MTBaseWebViewURLOption *)defaultUrlOption{
    MTBaseWebViewURLOption *option = [[MTBaseWebViewURLOption alloc] init];
    option.isUrlTranscoding = YES;
    option.isUseServerUrl   = YES;
    option->_serverUrl      = [MTGlobalInfo sharedInstance].SERVER_ADDRESS;
    return option;
}

- (NSString *)commonUrl {
    
    //  如果没有原始路径 则不用进行后续拼接
    if (!(_originUrl && _originUrl.length)) {
        return @"";
    }
    
    NSString *realUrl = _originUrl;
    
    /** 1. 去空格 */
    realUrl = [realUrl stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    /** 2. 拼接域名 */
    if (_isUseServerUrl) {  //有设置域名
        if ([realUrl hasPrefix:@"http"] || [realUrl hasPrefix:@"https"]) {  //参数赋值有问题 传递了_serverUrl _originUrl中就不应该存在http(https)
            NSString *desc = [NSString stringWithFormat:@"参数赋值有误%@", self];
//            NSAssert(0, desc);/
            return @"";
        } else {
            if (![realUrl hasPrefix:@"/"]) { //如果路径前面没有 '/' 则应先拼接一个
                realUrl = [@"/" stringByAppendingString:realUrl];
            }
            
            realUrl = [NSString stringWithFormat:@"http://%@%@", _serverUrl, realUrl];
        }
    } else {    //没有设置域名
        if (!([realUrl hasPrefix:@"http"] || [realUrl hasPrefix:@"https"])) {  //没有http或https开头的
            
            if ([realUrl hasPrefix:@"/"]) { //路径最前面出现 '/' 字符的
                realUrl = [realUrl substringFromIndex:1];
            }
            
            realUrl = [NSString stringWithFormat:@"http://%@",realUrl];
        }
    }
    
    
    /** 3.1 拼接参数 */
    if (_urlParams) {
        realUrl = [self checkUrlForAppendParams:realUrl];
        if (realUrl.length == 0) {
            return realUrl;
        }
        realUrl = [realUrl stringByAppendingString:[self convertUrlParamToStr:_urlParams]];
    }
    
    /** 3.2 拼接公共参数 */
    if ([realUrl containsString:_serverUrl]) {  //只有我们自己的开发的界面才需要添加公共参数
        if (self.commonUrlParams) {
            realUrl = [self checkUrlForAppendParams:realUrl];
            if (realUrl.length == 0) {
                return realUrl;
            }
            realUrl = [realUrl stringByAppendingString:[self convertUrlParamToStr:self.commonUrlParams]];
        }
    }
    
    
    /** 4. 转码 */
    if (_isUrlTranscoding) {
        realUrl = [realUrl stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    }
    return realUrl;
}

/**
 *  关于html?的校验
 *  1. 判断是否包含html        如果没有html 则提示错误 url有误
 *  2. 判断有没有html?        如果没有html? 则修改为 html?
 *  3. 判断后缀是不是html?     如果不是 则证明有参数了 拼接参数前需要加一个 &
 */
- (NSString *)checkUrlForAppendParams:(NSString *)realUrl {
    if ([realUrl containsString:@"html"]) {
        if (![realUrl containsString:@"html?"]) {
            realUrl = [realUrl stringByReplacingOccurrencesOfString:@"html" withString:@"html?"];
        }
        if (![realUrl hasSuffix:@"html?"]) {
            realUrl = [realUrl stringByAppendingString:@"&"];
        }
    } else {
//        NSString *desc = [NSString stringWithFormat:@"url有误%@", self];  //不能没有html
//        NSAssert(0, desc);
//        realUrl = @"";
    }
    return realUrl;
}

- (void)setIsUseServerUrl:(BOOL)isUseServerUrl {
    _isUseServerUrl = isUseServerUrl;
    [self responseToSetUrlBlock];
}

- (void)setCommonUrl:(NSString *)commonUrl{
    _originUrl = commonUrl;
    [self responseToSetUrlBlock];
}

- (void)setUrlParams:(NSDictionary *)urlParams {
    _urlParams = urlParams;
    [self responseToSetUrlBlock];
}

- (void)setIsUrlTranscoding:(BOOL)isUrlTranscoding {
    _isUrlTranscoding = isUrlTranscoding;
    [self responseToSetUrlBlock];
}

//设置url 回调
- (void)responseToSetUrlBlock {
    if (self.setUrlBlock) {
        self.setUrlBlock();
    }
}

- (NSString *)convertUrlParamToStr:(NSDictionary *)urlParams {
    __block NSString *urlSuffixStr = @"";
    if (urlParams && urlParams.count) {
        
        [urlParams enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            urlSuffixStr = [urlSuffixStr stringByAppendingString:[NSString stringWithFormat:@"%@=%@", key, obj]];
            urlSuffixStr = [urlSuffixStr stringByAppendingString:@"&"];
        }];
        
        //去除最后一个 '&'
        urlSuffixStr = [urlSuffixStr substringToIndex:urlSuffixStr.length-1];
    }
    return urlSuffixStr;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"【web地址信息】\n【服务器地址】：%@\n【通用地址】：%@\n【地址参数】：%@\n【是否转码】：%@", _serverUrl, _originUrl, _urlParams, _isUrlTranscoding?@"是":@"否"];
}

@end
#pragma mark -




#pragma mark - MTBaseWebViewNavOption
@implementation MTBaseWebViewNavOption
+ (MTBaseWebViewNavOption *)defaultNavOption {
    MTBaseWebViewNavOption *navOption = [[MTBaseWebViewNavOption alloc] init];
    navOption.isAllowsBack   = YES;
    navOption.isShowProgress = YES;
    navOption.navType        = MTBaseWebViewNavType_Back;
    return navOption;
}
@end
#pragma mark -


#pragma mark - MTBaseWebViewNavFuncOption
@implementation MTBaseWebViewNavFuncOption
+ (MTBaseWebViewNavFuncOption *)defaultNavFuncOption {
    MTBaseWebViewNavFuncOption *navFuncOption = [[MTBaseWebViewNavFuncOption alloc] init];
    navFuncOption.isShowMoreFuncBtn  = NO;
    navFuncOption.backGroundColor = [UIColor blackColor];
    navFuncOption.titleTextColor = [UIColor whiteColor];
    navFuncOption.dataArray = @[];
    navFuncOption.images = @[];
    navFuncOption.row_height = 50.0;
    navFuncOption.row_width = 120.0;
    navFuncOption.frame_width_y = 28.0;
    navFuncOption.frame_width_x = 30.0;
    navFuncOption.textAlignment = NSTextAlignmentCenter;
    navFuncOption.fontSize = 13;
    return navFuncOption;
}
@end
#pragma mark -




#pragma mark - MTBaseWebViewController
@interface MTBaseWebViewController ()<WKUIDelegate,WKScriptMessageHandler,MTSelectIndexPathDelegate>


@property (nonatomic,strong) UIProgressView *progress;  /* 进度条 */
@property (nonatomic, strong) NSArray *jsToOcMethods;   /* js调用oc方法列表 */

@end

@implementation MTBaseWebViewController


//  !!!:接受通过配置文件配置参数 通过KVC赋值URL配置项
- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    
    NSArray *urlOptionKeys = @[@"urlParams", @"isUrlTranscoding", @"commonUrl", @"isUseServerUrl"];
    if ([urlOptionKeys containsObject:key]) {
        [_urlOption setValue:value forKey:key];
    }
    
    NSArray *navOptionKeys = @[@"naviTitle", @"navTitle", @"navType", @"isShowProgress", @"isAllowsBack"];
    if ([navOptionKeys containsObject:key]) {
        if ([[navOptionKeys subarrayWithRange:NSMakeRange(0, 2)] containsObject:key]) {
            [_navOption setValue:value forKey:@"navTitle"];
        } else {
            [_navOption setValue:value forKey:key];
        }
    }
    
    NSArray *navFuncOptionKeys = @[@"isShowMoreFuncBtn"];
    if ([navFuncOptionKeys containsObject:key]) {
        [_navFuncOption setValue:value forKey:key];
    }
}

- (void)reload {
    [self.webView reload];
}

#pragma mark - 生命周期

- (instancetype)init
{
    if (self = [super init])
    {
        _urlOption = [MTBaseWebViewURLOption defaultUrlOption];
        _navOption = [MTBaseWebViewNavOption defaultNavOption];
        _navFuncOption = [MTBaseWebViewNavFuncOption defaultNavFuncOption];
        
        __weak typeof(self) weakSelf = self;
        _urlOption.setUrlBlock = ^{
            [weakSelf configWebView];
        };
    }
    return self;
}

-(void)dealloc{
    [self removeObservers];
    NSLog(@"%s", __func__);
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self.view setBackgroundColor:MTTableColor];
    
    [self setupWebView];
    [self configWebView];
}

- (void)viewWillAppear:(BOOL)animated {
    //配置导航栏样式
    [self setupNaviBar];
    
    //iPhone X 上下滑动的时候 底部按钮不固定 修复
    if (@available(iOS 11.0, *)) {
        self.webView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    
    /*否则底部上拉和顶部下拉，*/
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.automaticallyAdjustsScrollViewInsets = false;
    
    [super viewWillAppear:animated];
}



#pragma mark - 视图管理
- (UIProgressView *)progress {
    if (_progress == nil)
    {
        _progress = [[UIProgressView alloc]initWithFrame:CGRectZero];
        _progress.tintColor = [UIColor blueColor];
        _progress.backgroundColor = [UIColor lightGrayColor];
        [self.webView addSubview:_progress];
        
        _progress.translatesAutoresizingMaskIntoConstraints = NO;

        [_progress mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.webView.mas_top).offset(0);
            make.height.equalTo(@2);
            make.left.equalTo(self.webView.mas_left).offset(0);
            make.right.equalTo(self.webView.mas_right).offset(0);
        }];
    }
    return _progress;
}

- (WKWebView *)webView {
    if (!_webView) {
        WKUserContentController *userVC = [[WKUserContentController alloc] init];
        [self addScriptMessageHandler:userVC];
        
        /* webview config */
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc] init];
        config.preferences = [[WKPreferences alloc] init];
        config.preferences.minimumFontSize = 10;
        config.preferences.javaScriptEnabled= YES;
        config.preferences.javaScriptCanOpenWindowsAutomatically = NO;
        config.userContentController = userVC;
        
        _webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:config];
        _webView.navigationDelegate = self;
        _webView.UIDelegate = self;
        _webView.scrollView.bounces = NO;
        [self.view addSubview:_webView];
        
        CGFloat bottom = MTIPhoneX ? 20 : 0;
        
        _webView.translatesAutoresizingMaskIntoConstraints = NO;
        [_webView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view.mas_top).offset(0);
            make.bottom.equalTo(self.view.mas_bottom).offset(0);
            make.left.equalTo(self.view.mas_left).offset(0);
            make.right.equalTo(self.view.mas_right).offset(0);
        }];

    }
    return _webView;
}


- (void)setupNaviBar {
    
    self.navigationBarHidden = NO;
    
    //定义左侧按钮 【回退按钮，退出按钮】
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"btn_back_normal"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self
                                                                action:@selector(backAction:)];
    UIBarButtonItem *stopItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
                                                                              target:self
                                                                              action:@selector(stopBarBtnAction:)];
    
    /*默认导航栏右侧刷新按钮*/
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"webRefreshButton"]
                                                                  style:UIBarButtonItemStylePlain
                                                                 target:self
                                                                 action:@selector(refreshUIBtnAction:)];
    
    NSMutableArray *leftItems = [NSMutableArray array];
    if (_navOption.navType & MTBaseWebViewNavType_Back) {
        [leftItems addObject:backItem];
    }
    if (_navOption.navType & MTBaseWebViewNavType_Exit) {
        [leftItems addObject:stopItem];
    }
    
    self.navigationItem.leftBarButtonItems = [leftItems copy];
    
    if (_navOption.navType & MTBaseWebViewNavType_Refresh) {
        self.navigationItem.rightBarButtonItem = rightItem;
    }
    
    if (_navOption.rightBarItems) {   //使用外部定义的按钮
        self.navigationItem.rightBarButtonItems = _navOption.rightBarItems;
    }
    
    /** 如果 isShowMoreFuncBtn 属性设置为YES 那代表导航栏功能按钮过多,此时可以开启多功能下拉弹窗 &&self.navigationItem.rightBarButtonItems.count>2*/
    if (_navFuncOption.isShowMoreFuncBtn) {
        [self configNavMoreFuncView];
    }
}

- (void)setupWebView {
    
    /*判断 web 否支持手动滑动*/
    if (_navOption.isAllowsBack) {
        self.webView.allowsBackForwardNavigationGestures = YES;
    }
    
    /*是否需要进度条*/
    if (!_navOption.isShowProgress) {
        self.progress = nil;
    }
    
    //TODO:kvo监听页面title和加载进度值
    [self addObservers];
}

-(void)configWebView {
    
    if (self.webView.isLoading) {
        [self.webView stopLoading];
    }
    NSURL *url = [NSURL URLWithString:_urlOption.commonUrl];
    if (_isLoadLocalFile) {
        url = [NSURL fileURLWithPath:self.localfilePath];
    }
    [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
}

-(void)configNavMoreFuncView{
    
    /** 01、获取已经存在的导航栏功能按钮*/
    NSMutableArray*listBarItems = [NSMutableArray array];
    
    /** 02、将多功能按钮添加到已经存在的按钮集合中*/
    if (![self.navigationItem.rightBarButtonItem isKindOfClass:[NSNull class]]&&!(self.navigationItem.rightBarButtonItem == nil)) {
        [listBarItems addObject:self.navigationItem.rightBarButtonItem];
    }
 
    UIBarButtonItem *moreFuncItem = [[UIBarButtonItem alloc] initWithImage:[self reSizeImage:[UIImage imageNamed:MTCommonImage(@"navMoreBtn@2x")] toSize:CGSizeMake(27, 27)]
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:@selector(moreFuncItemAction:event:)];
    [listBarItems addObject:moreFuncItem];
    
    self.navigationItem.rightBarButtonItems = listBarItems;
    
}

- (UIImage *)reSizeImage:(UIImage *)image toSize:(CGSize)reSize
{
    UIGraphicsBeginImageContext(CGSizeMake(reSize.width, reSize.height));
    [image drawInRect:CGRectMake(0, 0, reSize.width, reSize.height)];
    UIImage *reSizeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [reSizeImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
}
/** 不需要使用父类导航栏的任何控件 包括返回按钮 */
- (void)setNaviTitle:(NSString *)title leftButtonShow:(BOOL)leftButtonShow rightButtom:(id)rightButtom {
    //!!!:拦截父类对导航栏设置
    _navOption.navTitle = title;//设置默认标题
}


#pragma mark - js to oc
- (NSArray *)jsToOcMethods {
    if (!_jsToOcMethods) {
        if (self.bridgeDelegate &&
            [self.bridgeDelegate respondsToSelector:@selector(jsToOcMethodsInWebBridge)]) {
            _jsToOcMethods = [self.bridgeDelegate jsToOcMethodsInWebBridge];
        } else {
            _jsToOcMethods = [NSArray array];
        }
    }
    return _jsToOcMethods;
}

- (void)addScriptMessageHandler:(WKUserContentController *)userVC {
    for (NSString *method in self.jsToOcMethods) {
        [userVC addScriptMessageHandler:self name:method];
    }
}

- (void)removeScriptMessageHandler {
    for (NSString *method in self.jsToOcMethods) {
        [self.webView.configuration.userContentController removeScriptMessageHandlerForName:method];
    }
}

#pragma mark - 点击事件
/* 父类退出事件 */
- (void)backAction {
    
    [self removeScriptMessageHandler];
    
    [super backAction];
}

/* 自己回退事件 */
-(void)backAction:(UIBarButtonItem *)item{
    //判断是否有上一层H5页面
    if ([self.webView canGoBack]) {   //如果有则返回
        [self.webView goBack];
    } else {    //如果没有则退出
        [self backAction];
    }
}

/* 自己退出事件 */
-(void)stopBarBtnAction:(UIBarButtonItem *)item {
    [self backAction];
}

/* 重新加载web */
-(void)refreshUIBtnAction:(UIBarButtonItem *)item {
    
    [self reload];
}
/** More Func Click */
-(void)moreFuncItemAction:(UIBarButtonItem *)item event:(UIEvent *)event{
    /** 01、计算触摸的位置*/
    CGRect fromRect = [[event.allTouches anyObject] view].frame;
    CGPoint point = MTIPhoneX?CGPointMake(kScWidth-self.navFuncOption.frame_width_y, fromRect.origin.y + fromRect.size.width+self.navFuncOption.frame_width_x ):CGPointMake(kScWidth-self.navFuncOption.frame_width_y, fromRect.origin.y + fromRect.size.width+self.navFuncOption.frame_width_x );
    /** 02、初始化 配置参数*/
    MTPullDownTableView *popView = [[MTPullDownTableView alloc] initWithOrigin:point Width:self.navFuncOption.row_width Height:self.navFuncOption.row_height * self.navFuncOption.dataArray.count Type:MTTypeOfUpRight Color:self.navFuncOption.backGroundColor];
    popView.dataArray       = self.navFuncOption.dataArray;
    popView.images          = self.navFuncOption.images;
    popView.row_height      = self.navFuncOption.row_height ;
    popView.delegate        = self;
    popView.titleTextColor  = self.navFuncOption.titleTextColor;
    popView.fontSize = self.navFuncOption.fontSize;
    popView.textAlignment = self.navFuncOption.textAlignment;
    [popView show];
}
-(void)ocToJsClick:(NSString *)OcToJsKey OcToJsParams:(NSDictionary *)OcToJsParams {
    //OC调用JS  changeColor()是JS方法名，completionHandler是异步回调block
    NSString *jsString = [NSString stringWithFormat:@"%@('%@')",OcToJsKey, OcToJsParams];
    
    [_webView evaluateJavaScript:jsString completionHandler:^(id _Nullable data, NSError * _Nullable error) {
        
        if (self.bridgeDelegate) {
            [self.bridgeDelegate ocToJsPrintData:data error:error];
        }
    }];
}


#pragma mark - KVO监听
- (void)addObservers {
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
    [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:NULL];
    [self.webView addObserver:self forKeyPath:@"loading" options:NSKeyValueObservingOptionNew context:NULL];
}

- (void)removeObservers {
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [self.webView removeObserver:self forKeyPath:@"title"];
    [self.webView removeObserver:self forKeyPath:@"loading"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    //加载进度值
    if ([keyPath isEqualToString:@"estimatedProgress"])
    {
        if (object == self.webView)
        {
            [self.progress setAlpha:1.0f];
            [self.progress setProgress:self.webView.estimatedProgress animated:YES];
            if(self.webView.estimatedProgress >= 1.0f)
            {
                [UIView animateWithDuration:0.5f
                                      delay:0.3f
                                    options:UIViewAnimationOptionCurveEaseOut
                                 animations:^{
                                     [self.progress setAlpha:0.0f];
                                 }
                                 completion:^(BOOL finished) {
                                     [self.progress setProgress:0.0f animated:NO];
                                 }];
            }
        }
        else
        {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
    //网页title
    else if ([keyPath isEqualToString:@"title"])
    {
        if (object == self.webView)
        {
            self.title = self.webView.title;
        }
        else
        {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
    else if ([keyPath isEqualToString:@"loading"])
    {
        if (object == self.webView)
        {
            NSLog(@"%d",self.webView.loading);
        }
        else
        {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
    else
    {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}




#pragma mark -
#pragma mark - WKNavigationDelegate
// 页面开始加载时调用
-(void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation{
    
}
// 当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation{
    
}
// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{//这里修改导航栏的标题，动态改变
    if (webView.title && webView.title.length) {
        self.title = webView.title;
    } else {
        self.title = _navOption.navTitle;
    }
    
    
    [webView evaluateJavaScript:@"document.title" completionHandler:^(id _Nullable repoen, NSError * _Nullable error) {
        NSLog(@"%@",repoen);
    }];
    
    [[NSURLSession sharedSession] dataTaskWithURL:webView.URL completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        NSHTTPURLResponse *tmpresponse = (NSHTTPURLResponse*)response;
        
        NSLog(@"statusCode:%ld", (long)tmpresponse.statusCode);
        
    }];
    
}
// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation{
    NSLog(@"didFailProvisionalNavigation!!!");
    [self.view configBlankPage:EaseBlankPageTypeInternetError hasData:NO hasError:NO reloadButtonBlock:nil];
}
// 接收到服务器跳转请求之后再执行
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation{
    
}
// 在收到响应后，决定是否跳转
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler{
    
    WKNavigationResponsePolicy actionPolicy = WKNavigationResponsePolicyAllow;
    
    NSLog(@"%@",webView);
    NSLog(@"%@",navigationResponse);
    
    if ([navigationResponse.response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)navigationResponse.response;
        if (httpResponse.statusCode == 404) {
            [self.view configBlankPage:EaseBlankPageTypeNoButton hasData:NO hasError:NO reloadButtonBlock:nil];
            actionPolicy = WKNavigationResponsePolicyCancel;
        }
    }
    
    
    //这句是必须加上的，不然会异常
    decisionHandler(actionPolicy);
    
}
// 决定导航的动作，通常用于处理跨域的链接能否导航。
// WebKit对跨域进行了安全检查限制，不允许跨域，因此我们要对不能跨域的链接单独处理。
// 但是，对于Safari是允许跨域的，不用这么处理。
// 这个是决定是否Request

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler{
    
    if (webView.title && webView.title.length) {
        self.title = webView.title;
    } else {
        self.title = _navOption.navTitle;
    }
    
    WKNavigationActionPolicy actionPolicy = WKNavigationActionPolicyAllow;
    
    if (navigationAction.navigationType==WKNavigationTypeBackForward) {//判断是返回类型
        
        //同时设置返回按钮和关闭按钮为导航栏左边的按钮 这里可以监听左滑返回事件，仿微信添加关闭按钮。
        //        self.navigationItem.leftBarButtonItems = @[self.backBtn, self.closeBtn];
        //可以在这里找到指定的历史页面做跳转
        //        if (webView.backForwardList.backList.count>0) {                                  //得到栈里面的list
        //            DLog(@"%@",webView.backForwardList.backList);
        //            DLog(@"%@",webView.backForwardList.currentItem);
        //            WKBackForwardListItem * item = webView.backForwardList.currentItem;          //得到现在加载的list
        //            for (WKBackForwardListItem * backItem in webView.backForwardList.backList) { //循环遍历，得到你想退出到
        //                //添加判断条件
        //                [webView goToBackForwardListItem:[webView.backForwardList.backList firstObject]];
        //            }
        //        }
    }
    //这句是必须加上的，不然会异常
    decisionHandler(actionPolicy);
}
//用于授权验证的API，与AFN、UIWebView的授权验证API是一样的
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *__nullable credential))completionHandler{
//    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling ,nil);
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        if ([challenge previousFailureCount] == 0) {
            NSURLCredential *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        } else {
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }
    } else {
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
}


#pragma mark - WKUIDelegate

/**
 webView中弹出警告框时调用, 只能有一个按钮
 @param webView webView
 @param message 提示信息
 @param frame 可用于区分哪个窗口调用的
 @param completionHandler 警告框消失的时候调用, 回调给JS
 
 // 在JS端调用alert函数时，会触发此代理方法。
 
 // JS端调用alert时所传的数据可以通过message拿到
 
 // 在原生得到结果后，需要回调JS，是通过completionHandler回调
 */
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [self presentViewController:alertController animated:YES completion:nil];
}

/** 对应js的prompt方法
 webView中弹出输入框时调用, 两个按钮 和 一个输入框
 @param webView webView description
 @param prompt 提示信息
 @param defaultText 默认提示文本
 @param frame 可用于区分哪个窗口调用的
 @param completionHandler 输入框消失的时候调用, 回调给JS, 参数为输入的内容
 
 // JS端调用prompt函数时，会触发此方法
 
 // 要求输入一段文本
 
 // 在原生输入得到文本内容后，通过completionHandler回调给JS
 */
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * __nullable result))completionHandler{
    

}

/** 对应js的confirm方法
 webView中弹出选择框时调用, 两个按钮
 @param webView webView description
 @param message 提示信息
 @param frame 可用于区分哪个窗口调用的
 @param completionHandler 确认框消失的时候调用, 回调给JS, 参数为选择结果: YES or NO
 
 // JS端调用confirm函数时，会触发此方法
 
 // 通过message可以拿到JS端所传的数据
 
 // 在iOS端显示原生alert得到YES/NO后
 
 // 通过completionHandler回调给JS端
 */
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler{

}


- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler:(void (^ _Nullable)(_Nullable id, NSError * _Nullable error))completionHandler{
    
}

/*! @abstract Invoked when an error occurs while starting to load data for
 the main frame.
 @param webView The web view invoking the delegate method.
 @param navigation The navigation.
 @param error The error that occurred.
 */
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error{
    
}

/*! @abstract Invoked when an error occurs during a committed main frame
 navigation.
 @param webView The web view invoking the delegate method.
 @param navigation The navigation.
 @param error The error that occurred.
 当main frame最后下载数据失败时，会回调
 */
- (void)webView:(WKWebView *)webView didFailNavigation:(null_unspecified WKNavigation *)navigation withError:(NSError *)error{
    
}
#pragma mark - WKScriptMessageHandler

/**
 *  通过接收JS传出消息的name进行捕捉的回调方法
 *
 *  message.name        方法名
 *  message.body        参数内容
 *  message.frameInfo   布局相关信息
 */
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    
    NSString    *msgName       = message.name;
    id          msgBody        = message.body;
    WKFrameInfo *msgFrameInfo  = message.frameInfo;
    
    NSLog(@"name:%@\n body:%@\n frameInfo:%@\n", msgName, msgBody, msgFrameInfo);
    
    if (self.bridgeDelegate) {
        if ([self.bridgeDelegate respondsToSelector:@selector(jsToOcMethod:body:)]) {
            [self.bridgeDelegate jsToOcMethod:msgName body:msgBody];
        }
        if ([self.bridgeDelegate respondsToSelector:@selector(systemContentController:didReceiveScriptMessage:)]) {
            [self.bridgeDelegate systemContentController:userContentController didReceiveScriptMessage:message];
        }
    }
}
#pragma mark - MTSelectIndexPathDelegate
- (void)selectIndexPathRow:(NSInteger )index{
    switch (index) {
        case 0:
        {
            NSLog(@"大志最帅");
        }
            break;
         /*
            ... ... ...
            */
        default:
            break;
    }
    
}

@end
