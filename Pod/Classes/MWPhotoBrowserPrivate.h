//
//  MWPhotoBrowser_Private.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 08/10/2013.
//
//

#import <UIKit/UIKit.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import <MediaPlayer/MediaPlayer.h>
#import "MWGridViewController.h"
#import "MWZoomingScrollView.h"

// Declare private methods of browser
@interface MWPhotoBrowser ()

// Data
@property (nonatomic) NSUInteger photoCount;
@property (nonatomic, strong) NSMutableArray *photos;
@property (nonatomic, strong) NSMutableArray *thumbPhotos;
@property (nonatomic, strong) NSArray *fixedPhotosArray; // Provided via init

// Views
@property (nonatomic, strong) UIScrollView *pagingScrollView;

// Paging & layout
@property (nonatomic, strong) NSMutableSet *visiblePages, *recycledPages;
@property (nonatomic) NSUInteger currentPageIndex;
@property (nonatomic) NSUInteger previousPageIndex;
@property (nonatomic) CGRect previousLayoutBounds;
@property (nonatomic) NSUInteger pageIndexBeforeRotation;

// Navigation & controls
@property (nonatomic, strong) UIToolbar *toolbar;
@property (nonatomic, strong) NSTimer *controlVisibilityTimer;
@property (nonatomic, strong) UIBarButtonItem *previousButton, *nextButton, *actionButton, *doneButton;
@property (nonatomic, strong) MBProgressHUD *progressHUD;

// Grid
@property (nonatomic, strong) MWGridViewController *gridController;
@property (nonatomic, strong) UIBarButtonItem *gridPreviousLeftNavItem;
@property (nonatomic, strong) UIBarButtonItem *gridPreviousRightNavItem;

// Appearance
@property (nonatomic) BOOL previousNavBarHidden;
@property (nonatomic) BOOL previousNavBarTranslucent;
@property (nonatomic) UIBarStyle previousNavBarStyle;
@property (nonatomic) UIStatusBarStyle previousStatusBarStyle;
@property (nonatomic, strong) UIColor *previousNavBarTintColor;
@property (nonatomic, strong) UIColor *previousNavBarBarTintColor;
@property (nonatomic, strong) UIBarButtonItem *previousViewControllerBackButton;
@property (nonatomic, strong) UIImage *previousNavigationBarBackgroundImageDefault;
@property (nonatomic, strong) UIImage *previousNavigationBarBackgroundImageLandscapePhone;

// Video
@property (nonatomic, strong) MPMoviePlayerViewController *currentVideoPlayerViewController;
@property (nonatomic) NSUInteger currentVideoIndex;
@property (nonatomic, strong) UIActivityIndicatorView *currentVideoLoadingIndicator;

// Misc
@property (nonatomic) BOOL hasBelongedToViewController;
@property (nonatomic) BOOL isVCBasedStatusBarAppearance;
@property (nonatomic) BOOL statusBarShouldBeHidden;
@property (nonatomic) BOOL leaveStatusBarAlone;
@property (nonatomic) BOOL performingLayout;
@property (nonatomic) BOOL rotating;
@property (nonatomic) BOOL viewIsActive; // active as in it's in the view heirarchy
@property (nonatomic) BOOL didSavePreviousStateOfNavBar;
@property (nonatomic) BOOL skipNextPagingScrollViewPositioning;
@property (nonatomic) BOOL viewHasAppearedInitially;
@property (nonatomic) CGPoint currentGridContentOffset;

// Properties
@property (nonatomic) UIActivityViewController *activityViewController;

// Layout
- (void)layoutVisiblePages;
- (void)performLayout;
- (BOOL)presentingViewControllerPrefersStatusBarHidden;

// Nav Bar Appearance
- (void)setNavBarAppearance:(BOOL)animated;
- (void)storePreviousNavBarAppearance;
- (void)restorePreviousNavBarAppearance:(BOOL)animated;

// Paging
- (void)tilePages;
- (BOOL)isDisplayingPageForIndex:(NSUInteger)index;
- (MWZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index;
- (MWZoomingScrollView *)pageDisplayingPhoto:(id<MWPhoto>)photo;
- (MWZoomingScrollView *)dequeueRecycledPage;
- (void)configurePage:(MWZoomingScrollView *)page forIndex:(NSUInteger)index;
- (void)didStartViewingPageAtIndex:(NSUInteger)index;

// Frames
- (CGRect)frameForPagingScrollView;
- (CGRect)frameForPageAtIndex:(NSUInteger)index;
- (CGSize)contentSizeForPagingScrollView;
- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index;
- (CGRect)frameForToolbarAtOrientation:(UIInterfaceOrientation)orientation;
- (CGRect)frameForCaptionView:(MWCaptionView *)captionView atIndex:(NSUInteger)index;
- (CGRect)frameForSelectedButton:(UIButton *)selectedButton atIndex:(NSUInteger)index;

// Navigation
- (void)updateNavigation;
- (void)jumpToPageAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)gotoPreviousPage;
- (void)gotoNextPage;

// Grid
- (void)showGrid:(BOOL)animated;
- (void)hideGrid;

// Controls
- (void)cancelControlHiding;
- (void)hideControlsAfterDelay;
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent;
- (void)toggleControls;
- (BOOL)areControlsHidden;

// Data
- (NSUInteger)numberOfPhotos;
- (id<MWPhoto>)photoAtIndex:(NSUInteger)index;
- (id<MWPhoto>)thumbPhotoAtIndex:(NSUInteger)index;
- (UIImage *)imageForPhoto:(id<MWPhoto>)photo;
- (BOOL)photoIsSelectedAtIndex:(NSUInteger)index;
- (void)setPhotoSelected:(BOOL)selected atIndex:(NSUInteger)index;
- (void)loadAdjacentPhotosIfNecessary:(id<MWPhoto>)photo;
- (void)releaseAllUnderlyingPhotos:(BOOL)preserveCurrent;

@end

