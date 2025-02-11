//
//  CCBRArticleViewController.m
//  NewsFeed
//
//  Created by tungngo on 10/13/20.
//

#import "CCBRNewsQuickViewController.h"

#import <WebKit/WebKit.h>
#import <SDWebImage/SDWebImage.h>
#import "CCBRNewsQuickViewModel.h"
#import "CCBRCommands.h"

void *CCBRNewsQuickViewControllerContext;
NSString *const kEstimatedProgressKeyPath = @"estimatedProgress";
NSString *const kTitleKeyPath = @"title";
NSString *const kURLKeyPath = @"URL";
static NSMutableDictionary *UrlToFaviconUrlMap;

UIImage *CreateGradientImage(CGSize size, NSArray<UIColor *> *colors) {
    CAGradientLayer *gradientLayer = [[CAGradientLayer alloc] init];
    gradientLayer.frame = (CGRect){{0,0}, size};
    
    NSMutableArray *cgColors = [NSMutableArray arrayWithCapacity:colors.count];
    for (UIColor *color in colors) {
        [cgColors addObject:(id)color.CGColor];
    }
    gradientLayer.colors = cgColors;
    
    gradientLayer.startPoint = (CGPoint){0.0, 0.5};
    gradientLayer.endPoint = (CGPoint){1.0, 0.5};
    
    UIGraphicsBeginImageContext(size);
    [gradientLayer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    return image;
}

NSURL *GetBaseURL(NSURL *URL) {
    return [NSURL URLWithString:@"/" relativeToURL:URL].absoluteURL;
}

@interface CCBRNewsQuickViewController () <WKNavigationDelegate>

@property (weak, nonatomic) IBOutlet UIView *headerView;
@property(weak, nonatomic) IBOutlet UILabel*titleLabel;
@property(weak, nonatomic) IBOutlet UILabel*domainLabel;
@property(weak,nonatomic)IBOutlet UIImageView*faviconView;
@property(weak, nonatomic)IBOutlet UIButton*moreButton;
@property(weak,nonatomic)IBOutlet UIButton*closeButton;
@property (weak, nonatomic) IBOutlet UIView *webContainerView;
@property(weak, nonatomic) IBOutlet UIProgressView *progressView;
@property(nonatomic, strong) WKWebView*webView;

@end

@implementation CCBRNewsQuickViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UrlToFaviconUrlMap = [[NSMutableDictionary alloc] initWithCapacity:0];
    
    [self buildWebView];
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:self.headerView.bounds cornerRadius:0];
    self.headerView.layer.shadowPath = path.CGPath;
    self.headerView.layer.shadowColor = [UIColor.blackColor colorWithAlphaComponent:0.1].CGColor;
    self.headerView.layer.shadowOpacity = 1;
    self.headerView.layer.shadowRadius = 10;
    self.headerView.layer.shadowOffset = (CGSize){0, 4};
    self.headerView.layer.frame = self.headerView.bounds;
    
    
    UIImage *image = CreateGradientImage(self.progressView.bounds.size, @[
        [UIColor colorWithRed:151/255. green:201/255. blue:61/255. alpha:1.],
        [UIColor colorWithRed:79/255. green:186/255. blue:105/255. alpha:1.]
    ]);
    self.progressView.progressImage = image;
    
    if (self.viewModel) {
        [self updateUI];
        [self loadUrl:self.viewModel.url];
    }
}

- (void)setViewModel:(CCBRNewsQuickViewModel *)viewModel {
    _viewModel = viewModel;
    
    [self updateUI];
    [self loadUrl:viewModel.url];
}

- (void)updateUI {
    self.titleLabel.text = self.viewModel.title;
    self.domainLabel.text = self.viewModel.domain;
    self.faviconView.image = self.viewModel.favicon;
}

- (void)buildWebView {
    if (self.webView) {
        return;
    }
    
    self.webView = [[WKWebView alloc] init];
    
    [self.webView addObserver:self forKeyPath:kEstimatedProgressKeyPath options:(NSKeyValueObservingOptionNew) context:&CCBRNewsQuickViewControllerContext];
    
    self.webView.navigationDelegate = self;
    [self.webContainerView addSubview:_webView];
    
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.webView.topAnchor constraintEqualToAnchor:self.webContainerView.topAnchor].active = YES;
    [self.webView.rightAnchor constraintEqualToAnchor:self.webContainerView.rightAnchor].active = YES;
    [self.webView.bottomAnchor constraintEqualToAnchor:self.webContainerView.bottomAnchor].active = YES;
    [self.webView.leftAnchor constraintEqualToAnchor:self.webContainerView.leftAnchor].active = YES;
    
    [self.webView addObserver:self forKeyPath:kTitleKeyPath options:NSKeyValueObservingOptionNew context:&CCBRNewsQuickViewControllerContext];
    [self.webView addObserver:self forKeyPath:kURLKeyPath options:NSKeyValueObservingOptionNew context:&CCBRNewsQuickViewControllerContext];
}

- (void)loadUrl:(NSString *)url {
    [self.webView loadHTMLString:@"" baseURL:nil];
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (IBAction)didTapButton:(UIButton*)sender {
    if (sender == self.moreButton) {
        // TODO: Show More menu
    } else if (sender == self.closeButton) {
        [self.dispatcher hideNews];
    }
}

#pragma mark - WKWebView Delegate

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    
    self.progressView.hidden = YES;
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    
    self.progressView.hidden = YES;
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    self.progressView.hidden = NO;
    NSURL *faviconURL = [UrlToFaviconUrlMap objectForKey:GetBaseURL(self.webView.URL).absoluteString];
    if (faviconURL) {
        [self.faviconView sd_setImageWithURL:faviconURL placeholderImage:[UIImage imageNamed:@"ccbr_news_article_light"]];
    } else {
        [self tryToUpdateTheFavicon];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.progressView.hidden = YES;
    
    NSURL *faviconURL = [UrlToFaviconUrlMap objectForKey:GetBaseURL(self.webView.URL).absoluteString];
    if (faviconURL) {
        [self.faviconView sd_setImageWithURL:faviconURL placeholderImage:[UIImage imageNamed:@"ccbr_news_article_light"]];
    } else {
        [self tryToUpdateTheFavicon];
    }
}

- (void)tryToUpdateTheFavicon {
    NSString *urlString = self.webView.URL.absoluteString;
    NSString *key = GetBaseURL(self.webView.URL).absoluteString;
    if (![urlString isEqualToString:@""] && [urlString containsString:@"http"] && ![UrlToFaviconUrlMap objectForKey:key]) {
        NSString *strFavicon = [NSString stringWithFormat:@"http://www.google.com/s2/favicons?domain=%@",self.webView.URL.absoluteString];
        NSURL *myURL=[NSURL URLWithString: strFavicon];
        [UrlToFaviconUrlMap setValue:myURL forKey:GetBaseURL(self.webView.URL).absoluteString];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &CCBRNewsQuickViewControllerContext) {
        if ([keyPath isEqualToString:kEstimatedProgressKeyPath]) {
            CGFloat progress = self.webView.estimatedProgress;
            self.progressView.progress = progress;
            self.progressView.hidden = (progress == 1.0);
        } else if ([keyPath isEqualToString:kTitleKeyPath]) {
            self.titleLabel.text = self.webView.title?:self.viewModel.title;
        } else if ([keyPath isEqualToString:kURLKeyPath]) {
            self.domainLabel.text = self.webView.URL.host?:self.viewModel.domain;
            [self tryToUpdateTheFavicon];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
