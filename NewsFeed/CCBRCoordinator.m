//
//  CCBRCoordinator.m
//  NewsFeed
//
//  Created by tungngo on 12/2/20.
//

#import "CCBRCoordinator.h"

#import "CCBRNewsPageViewModel.h"
#import "CCBRNewsPageViewController.h"
#import "CCBRNewsDataStore.h"
#import "CCBRSettingsViewController.h"
#import "AppDelegate.h"

@interface CCBRCoordinator ()

@property (nonatomic, strong) UIViewController *baseViewController;
@property (nonatomic, strong) CCBRNewsDataStore *articleDataStore;

@end

@implementation CCBRCoordinator

- (instancetype)initWithBaseViewController:(UIViewController *)viewController {
    self = [super init];
    if (self) {
        self.baseViewController = viewController;
    }
    return self;
}

- (void)showNewsWithDataSource:(id<CCBRArticleDataSource>)dataSource
                    startIndex:(NSUInteger)startIndex {
    CCBRNewsPageViewModel*viewModel = [[CCBRNewsPageViewModel alloc] initWithDataSource:dataSource startIndex:startIndex];
    CCBRNewsPageViewController *viewController = [[CCBRNewsPageViewController alloc] initWithViewModel:viewModel];
    viewController.dispatcher = self;
    
    [self.baseViewController presentViewController:viewController animated:YES completion:nil];
}

- (void)showSettings {
    CCBRSettingsViewModel *viewModel = [[CCBRSettingsViewModel alloc] init];
    CCBRSettingsViewController *viewController = [[CCBRSettingsViewController alloc] initWithViewModel:viewModel];
    viewController.dispatcher = self;
    [[APPDELEGATE topMostController] presentViewController:viewController animated:YES completion:nil];
}

- (void)hideNews {
    [self.baseViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)dismiss {
    [[APPDELEGATE topMostController] dismissViewControllerAnimated:YES completion:nil];
}

@end
