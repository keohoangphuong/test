//
//  CCBRArticleCollectionViewController.m
//  NewsFeed
//
//  Created by tungngo on 10/15/20.
//

#import "CCBRNewsViewController.h"

#import "CCBRNewsViewModel.h"
#import "CCBRNewsBigCardView.h"
#import "CCBRNewsMediumCardView.h"
#import "CCBRNewsSmallCardView.h"
#import "CCBRCommands.h"

typedef enum : NSUInteger {
    NewsV2CardTypeBig,
    NewsV2CardTypeMedium,
    NewsV2CardTypeSmall,
} NewsV2CardType;

@interface CCBRNewsViewController ()<UICollectionViewDataSource, UICollectionViewDelegate>

@property(nonatomic, strong) CCBRNewsViewModel*viewModel;
@property(nonatomic, assign) id<CCBRCommands> dispatcher;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadingIndicatorView;
@property (weak, nonatomic) IBOutlet UILabel *errorMessageLabel;
@property (weak, nonatomic) IBOutlet UIView *collectionContainerView;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIButton *settingsButton;

@property (nonatomic, assign) NewsV2CardType cardType;

@end

@implementation CCBRNewsViewController

static NSString * const kCCBRNewsBigCardView = @"CCBRNewsBigCardView";
static NSString * const kCCBRNewsMediumCardView = @"CCBRNewsMediumCardView";
static NSString * const kCCBRNewsSmallCardView = @"CCBRNewsSmallCardView";

- (instancetype)initWithViewModel:(CCBRNewsViewModel*)viewModel
                       dispatcher:(id<CCBRCommands>)dispatcher{
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        self.dispatcher = dispatcher;
        
        __weak CCBRNewsViewController *weakSelf = self;
        self.viewModel.updateCallback = ^{
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf updateUI];
            });
        };
        self.viewModel.errorCallback = ^(NSError *error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf loadDataError:error];
            });
        };
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.cardType = NewsV2CardTypeBig;
//    self.cardType = NewsV2CardTypeSmall;
    self.cardType = NewsV2CardTypeMedium;
    
    __weak CCBRNewsViewController *weakSelf = self;
    [self.collectionView addInfiniteScrollingWithActionHandler:^{
        [weakSelf.viewModel loadMore];
    }];
    
    if (self.cardType == NewsV2CardTypeMedium || self.cardType == NewsV2CardTypeSmall) {
        UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *) self.collectionView.collectionViewLayout;
        layout.minimumLineSpacing = 0;
    }
    
    [self.collectionView registerNib:[UINib nibWithNibName:kCCBRNewsBigCardView
                                                    bundle:nil]
          forCellWithReuseIdentifier:kCCBRNewsBigCardView];
    [self.collectionView registerNib:[UINib nibWithNibName:kCCBRNewsMediumCardView
                                                    bundle:nil]
          forCellWithReuseIdentifier:kCCBRNewsMediumCardView];
    [self.collectionView registerNib:[UINib nibWithNibName:kCCBRNewsSmallCardView
                                                    bundle:nil]
          forCellWithReuseIdentifier:kCCBRNewsSmallCardView];
    
    [self updateUI];
}

- (void)updateUI {
    self.loadingIndicatorView.hidden = YES;
    self.collectionView.hidden = self.viewModel.collectionViewHidden;
    self.errorMessageLabel.hidden = self.viewModel.errorMessageLabelHidden;
    [self.collectionView reloadData];
    [self.collectionView.infiniteScrollingView stopAnimating];
}

- (void)loadDataError: (NSError*)error {
    NSString* message = @"API errors";
    if (![error.localizedDescription isEqualToString:@""]) {
        message = error.localizedDescription;
    }
    if (self.viewModel.collectionViewHidden && !self.viewModel.errorMessageLabelHidden) {
        self.errorMessageLabel.text = message;
    } else {
        [self showMessage:message];
    }
    self.loadingIndicatorView.hidden = YES;
    self.collectionView.hidden = self.viewModel.collectionViewHidden;
    self.errorMessageLabel.hidden = self.viewModel.errorMessageLabelHidden;
    [self.collectionView.infiniteScrollingView stopAnimating];
}

- (void)showMessage: (NSString*)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error"
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *firstAction = [UIAlertAction actionWithTitle:@"Close"
                                                          style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
        NSLog(@"You pressed button close");
    }]; // 2
    
    [alert addAction:firstAction];
    
    [self presentViewController:alert animated:YES completion:nil];
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.viewModel.itemCount;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell;
    
    if (self.cardType == NewsV2CardTypeSmall) {
        CCBRNewsSmallCardView *smallCardView = (CCBRNewsSmallCardView *)[collectionView dequeueReusableCellWithReuseIdentifier:kCCBRNewsSmallCardView forIndexPath:indexPath];
        CCBRNewsCardViewModel *itemViewModel = [self.viewModel itemViewModelAtIndex:indexPath.row];
        smallCardView.viewModel = itemViewModel;
        cell = smallCardView;
    } else if (self.cardType == NewsV2CardTypeMedium) {
        CCBRNewsMediumCardView *mediumCardView = (CCBRNewsMediumCardView *)[collectionView dequeueReusableCellWithReuseIdentifier:kCCBRNewsMediumCardView forIndexPath:indexPath];
        CCBRNewsCardViewModel *itemViewModel = [self.viewModel itemViewModelAtIndex:indexPath.row];
        mediumCardView.viewModel = itemViewModel;
        cell = mediumCardView;
    } else if (self.cardType == NewsV2CardTypeBig) {
        CCBRNewsBigCardView *bigCardView = (CCBRNewsBigCardView *)[collectionView dequeueReusableCellWithReuseIdentifier:kCCBRNewsBigCardView forIndexPath:indexPath];
        CCBRNewsCardViewModel *itemViewModel = [self.viewModel itemViewModelAtIndex:indexPath.row];
        bigCardView.viewModel = itemViewModel;
        cell = bigCardView;
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.viewModel logCardImpressionWithIndex:indexPath.row];
}

#pragma mark <UICollectionViewDelegate>

/*
 // Uncomment this method to specify if the specified item should be highlighted during tracking
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
 return YES;
 }
 */

/*
 // Uncomment this method to specify if the specified item should be selected
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
 return YES;
 }
 */

/*
 // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
 - (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
 return NO;
 }
 
 - (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
 return NO;
 }
 
 - (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
 
 }
 */

- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self.dispatcher showNewsWithDataSource:self.viewModel.dataSource
                                 startIndex:indexPath.row];
    [self.viewModel logCardClickEventWithIndex:indexPath.row];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat screenWidth = CGRectGetWidth(UIScreen.mainScreen.bounds);
    CGFloat itemWidth = screenWidth - 2 * 8;
    CGFloat itemHeight = 114;
    
    if (self.cardType == NewsV2CardTypeBig) {
        itemHeight = 324;
    } else if (self.cardType == NewsV2CardTypeMedium) {
        itemHeight = 168;
    } else {
        itemHeight = 114;
    }
    
    return CGSizeMake(itemWidth, itemHeight);
}

#pragma mark - Event Handlers

- (IBAction)didTapButton:(UIButton *)sender {
    if (sender == self.settingsButton) {
        // TODO: Show Settings screen
        [self.dispatcher showSettings];
    }
}

@end

