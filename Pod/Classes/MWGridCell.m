//
//  MWGridCell.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 08/10/2013.
//
//

#import <DACircularProgress/DACircularProgressView.h>
#import "MWGridCell.h"
#import "MWCommon.h"
#import "MWPhotoBrowserPrivate.h"
#import "UIImage+MWPhotoBrowser.h"

#define VIDEO_INDICATOR_PADDING 10

@interface MWGridCell ()
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *videoIndicator;
@property (nonatomic, strong) UIImageView *loadingError;
@property (nonatomic, strong) DACircularProgressView *loadingIndicator;
@property (nonatomic, strong) UIButton *selectedButton;
@end

@implementation MWGridCell

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {

        // Grey background
        self.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1];
        
        // Image
        self.imageView = [UIImageView new];
        self.imageView.frame = self.bounds;
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.clipsToBounds = YES;
        self.imageView.autoresizesSubviews = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [self addSubview:self.imageView];
        
        // Video Image
        self.videoIndicator = [UIImageView new];
        self.videoIndicator.hidden = NO;
        UIImage *videoIndicatorImage = [UIImage imageForResourcePath:@"MWPhotoBrowser.bundle/VideoOverlay" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
        self.videoIndicator.frame = CGRectMake(self.bounds.size.width - videoIndicatorImage.size.width - VIDEO_INDICATOR_PADDING, self.bounds.size.height - videoIndicatorImage.size.height - VIDEO_INDICATOR_PADDING, videoIndicatorImage.size.width, videoIndicatorImage.size.height);
        self.videoIndicator.image = videoIndicatorImage;
        self.videoIndicator.autoresizesSubviews = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [self addSubview:self.videoIndicator];
        
        // Selection button
        self.selectedButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.selectedButton.contentMode = UIViewContentModeTopRight;
        self.selectedButton.adjustsImageWhenHighlighted = NO;
        [self.selectedButton setImage:[UIImage imageForResourcePath:@"MWPhotoBrowser.bundle/ImageSelectedSmallOff" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]] forState:UIControlStateNormal];
        [self.selectedButton setImage:[UIImage imageForResourcePath:@"MWPhotoBrowser.bundle/ImageSelectedSmallOn" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]] forState:UIControlStateSelected];
        [self.selectedButton addTarget:self action:@selector(selectionButtonPressed) forControlEvents:UIControlEventTouchDown];
        self.selectedButton.hidden = YES;
        self.selectedButton.frame = CGRectMake(0, 0, 44, 44);
        [self addSubview:self.selectedButton];
    
		// Loading indicator
		self.loadingIndicator = [[DACircularProgressView alloc] initWithFrame:CGRectMake(0, 0, 40.0f, 40.0f)];
        self.loadingIndicator.userInteractionEnabled = NO;
        self.loadingIndicator.thicknessRatio = 0.1;
        self.loadingIndicator.roundedCorners = NO;
		[self addSubview:self.loadingIndicator];
        
        // Listen for photo loading notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setProgressFromNotification:)
                                                     name:MWPHOTO_PROGRESS_NOTIFICATION
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleMWPhotoLoadingDidEndNotification:)
                                                     name:MWPHOTO_LOADING_DID_END_NOTIFICATION
                                                   object:nil];
        
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setGridController:(MWGridViewController *)gridController {
    _gridController = gridController;
    // Set custom selection image if required
    if (self.gridController.browser.customImageSelectedSmallIconName) {
        [self.selectedButton setImage:[UIImage imageNamed:self.gridController.browser.customImageSelectedSmallIconName] forState:UIControlStateSelected];
    }
}

#pragma mark - View

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = self.bounds;
    self.loadingIndicator.frame = CGRectMake(floorf((self.bounds.size.width - self.loadingIndicator.frame.size.width) / 2.),
                                         floorf((self.bounds.size.height - self.loadingIndicator.frame.size.height) / 2),
                                         self.loadingIndicator.frame.size.width,
                                         self.loadingIndicator.frame.size.height);
    self.selectedButton.frame = CGRectMake(self.bounds.size.width - self.selectedButton.frame.size.width - 0,
                                       0, self.selectedButton.frame.size.width, self.selectedButton.frame.size.height);
}

#pragma mark - Cell

- (void)prepareForReuse {
    self.photo = nil;
    self.gridController = nil;
    self.imageView.image = nil;
    self.loadingIndicator.progress = 0;
    self.selectedButton.hidden = YES;
    [self hideImageFailure];
    [super prepareForReuse];
}

#pragma mark - Image Handling

- (void)setPhoto:(id <MWPhoto>)photo {
    _photo = photo;
    if ([photo respondsToSelector:@selector(isVideo)]) {
        self.videoIndicator.hidden = !photo.isVideo;
    } else {
        self.videoIndicator.hidden = YES;
    }
    if (self.photo) {
        if (![self.photo underlyingImage]) {
            [self showLoadingIndicator];
        } else {
            [self hideLoadingIndicator];
        }
    } else {
        [self showImageFailure];
    }
}

- (void)displayImage {
    self.imageView.image = [self.photo underlyingImage];
    self.selectedButton.hidden = !self.selectionMode;
    [self hideImageFailure];
}

#pragma mark - Selection

- (void)setSelectionMode:(BOOL)selectionMode {
    _selectionMode = selectionMode;
}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    self.selectedButton.selected = isSelected;
}

- (void)selectionButtonPressed {
    self.selectedButton.selected = !self.selectedButton.selected;
    [self.gridController.browser setPhotoSelected:self.selectedButton.selected atIndex:self.index];
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.imageView.alpha = 0.6;
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    self.imageView.alpha = 1;
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    self.imageView.alpha = 1;
    [super touchesCancelled:touches withEvent:event];
}

#pragma mark Indicators

- (void)hideLoadingIndicator {
    self.loadingIndicator.hidden = YES;
}

- (void)showLoadingIndicator {
    self.loadingIndicator.progress = 0;
    self.loadingIndicator.hidden = NO;
    [self hideImageFailure];
}

- (void)showImageFailure {
    // Only show if image is not empty
    if (![self.photo respondsToSelector:@selector(emptyImage)] || !self.photo.emptyImage) {
        if (!self.loadingError) {
            self.loadingError = [UIImageView new];
            self.loadingError.image = [UIImage imageForResourcePath:@"MWPhotoBrowser.bundle/ImageError" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
            self.loadingError.userInteractionEnabled = NO;
            [self.loadingError sizeToFit];
            [self addSubview:self.loadingError];
        }
        self.loadingError.frame = CGRectMake(floorf((self.bounds.size.width - self.loadingError.frame.size.width) / 2.),
                                         floorf((self.bounds.size.height - self.loadingError.frame.size.height) / 2),
                                         self.loadingError.frame.size.width,
                                         self.loadingError.frame.size.height);
    }
    [self hideLoadingIndicator];
    self.imageView.image = nil;
}

- (void)hideImageFailure {
    if (self.loadingError) {
        [self.loadingError removeFromSuperview];
        self.loadingError = nil;
    }
}

#pragma mark - Notifications

- (void)setProgressFromNotification:(NSNotification *)notification {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        typeof(self) strongSelf = weakSelf;
        NSDictionary *dict = [notification object];
        id <MWPhoto> photoWithProgress = [dict objectForKey:@"photo"];
        if (photoWithProgress == strongSelf.photo) {
//            NSLog(@"%f", [[dict valueForKey:@"progress"] floatValue]);
            float progress = [[dict valueForKey:@"progress"] floatValue];
            strongSelf.loadingIndicator.progress = MAX(MIN(1, progress), 0);
        }
    });
}

- (void)handleMWPhotoLoadingDidEndNotification:(NSNotification *)notification {
    id <MWPhoto> photo = [notification object];
    if (photo == self.photo) {
        if ([photo underlyingImage]) {
            // Successful load
            [self displayImage];
        } else {
            // Failed to load
            [self showImageFailure];
        }
        [self hideLoadingIndicator];
    }
}

@end
