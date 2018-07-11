//
//  ZoomingScrollView.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

#import <DACircularProgress/DACircularProgressView.h>
#import "MWCommon.h"
#import "MWZoomingScrollView.h"
#import "MWPhotoBrowser.h"
#import "MWPhoto.h"
#import "MWPhotoBrowserPrivate.h"
#import "UIImage+MWPhotoBrowser.h"

// Private methods and properties
@interface MWZoomingScrollView ()
@property (nonatomic, assign) MWPhotoBrowser *photoBrowser;
@property (nonatomic, strong) MWTapDetectingView *tapView; // for background taps
@property (nonatomic, strong) MWTapDetectingImageView *photoImageView;
@property (nonatomic, strong) DACircularProgressView *loadingIndicator;
@property (nonatomic, strong) UIImageView *loadingError;
@end

@implementation MWZoomingScrollView

- (id)initWithPhotoBrowser:(MWPhotoBrowser *)browser {
    if ((self = [super init])) {
        
        // Setup
        self.index = NSUIntegerMax;
        self.photoBrowser = browser;
        
		// Tap view for background
	    self.tapView = [[MWTapDetectingView alloc] initWithFrame:self.bounds];
	    self.tapView.tapDelegate = self;
	    self.tapView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	    self.tapView.backgroundColor = [UIColor blackColor];
		[self addSubview:self.tapView];
		
		// Image view
	    self.photoImageView = [[MWTapDetectingImageView alloc] initWithFrame:CGRectZero];
	    self.photoImageView.tapDelegate = self;
	    self.photoImageView.contentMode = UIViewContentModeCenter;
	    self.photoImageView.backgroundColor = [UIColor blackColor];
		[self addSubview:self.photoImageView];
		
		// Loading indicator
	    self.loadingIndicator = [[DACircularProgressView alloc] initWithFrame:CGRectMake(140.0f, 30.0f, 40.0f, 40.0f)];
        self.loadingIndicator.userInteractionEnabled = NO;
        self.loadingIndicator.thicknessRatio = 0.1;
        self.loadingIndicator.roundedCorners = NO;
	    self.loadingIndicator.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
        UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
		[self addSubview:self.loadingIndicator];

        // Listen progress notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(setProgressFromNotification:)
                                                     name:MWPHOTO_PROGRESS_NOTIFICATION
                                                   object:nil];
        
		// Setup
		self.backgroundColor = [UIColor blackColor];
		self.delegate = self;
		self.showsHorizontalScrollIndicator = NO;
		self.showsVerticalScrollIndicator = NO;
		self.decelerationRate = UIScrollViewDecelerationRateFast;
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
    }
    return self;
}

- (void)dealloc {
    if ([self.photo respondsToSelector:@selector(cancelAnyLoading)]) {
        [self.photo cancelAnyLoading];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)prepareForReuse {
    [self hideImageFailure];
    self.photo = nil;
    self.captionView = nil;
    self.selectedButton = nil;
    self.playButton = nil;
    self.photoImageView.hidden = NO;
    self.photoImageView.image = nil;
    self.index = NSUIntegerMax;
}

- (BOOL)displayingVideo {
    return [self.photo respondsToSelector:@selector(isVideo)] && self.photo.isVideo;
}

- (void)setImageHidden:(BOOL)hidden {
    self.photoImageView.hidden = hidden;
}

#pragma mark - Image

- (void)setPhoto:(id<MWPhoto>)photo {
    // Cancel any loading on old photo
    if (self.photo && photo == nil) {
        if ([self.photo respondsToSelector:@selector(cancelAnyLoading)]) {
            [self.photo cancelAnyLoading];
        }
    }
    _photo = photo;
    UIImage *img = [self.photoBrowser imageForPhoto:self.photo];
    if (img) {
        [self displayImage];
    } else {
        // Will be loading so show loading
        [self showLoadingIndicator];
    }
}

// Get and display image
- (void)displayImage {
	if (self.photo && self.photoImageView.image == nil) {
		
		// Reset
		self.maximumZoomScale = 1;
		self.minimumZoomScale = 1;
		self.zoomScale = 1;
		self.contentSize = CGSizeMake(0, 0);
		
		// Get image from browser as it handles ordering of fetching
		UIImage *img = [self.photoBrowser imageForPhoto:self.photo];
		if (img) {
			
			// Hide indicator
			[self hideLoadingIndicator];
			
			// Set image
		    self.photoImageView.image = img;
		    self.photoImageView.hidden = NO;
			
			// Setup photo frame
			CGRect photoImageViewFrame;
			photoImageViewFrame.origin = CGPointZero;
			photoImageViewFrame.size = img.size;
		    self.photoImageView.frame = photoImageViewFrame;
			self.contentSize = photoImageViewFrame.size;

			// Set zoom to minimum zoom
			[self setMaxMinZoomScalesForCurrentBounds];
			
		} else  {

            // Show image failure
            [self displayImageFailure];
			
		}
		[self setNeedsLayout];
	}
}

// Image failed so just show black!
- (void)displayImageFailure {
    [self hideLoadingIndicator];
    self.photoImageView.image = nil;
    
    // Show if image is not empty
    if (![self.photo respondsToSelector:@selector(emptyImage)] || !self.photo.emptyImage) {
        if (!self.loadingError) {
            self.loadingError = [UIImageView new];
            self.loadingError.image = [UIImage imageForResourcePath:@"MWPhotoBrowser.bundle/ImageError" ofType:@"png" inBundle:[NSBundle bundleForClass:[self class]]];
            self.loadingError.userInteractionEnabled = NO;
            self.loadingError.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin |
            UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
            [self.loadingError sizeToFit];
            [self addSubview:self.loadingError];
        }
        self.loadingError.frame = CGRectMake(floorf((self.bounds.size.width - self.loadingError.frame.size.width) / 2.),
                                         floorf((self.bounds.size.height - self.loadingError.frame.size.height) / 2),
                                         self.loadingError.frame.size.width,
                                         self.loadingError.frame.size.height);
    }
}

- (void)hideImageFailure {
    if (self.loadingError) {
        [self.loadingError removeFromSuperview];
        self.loadingError = nil;
    }
}

#pragma mark - Loading Progress

- (void)setProgressFromNotification:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *dict = [notification object];
        id <MWPhoto> photoWithProgress = [dict objectForKey:@"photo"];
        if (photoWithProgress == self.photo) {
            float progress = [[dict valueForKey:@"progress"] floatValue];
            self.loadingIndicator.progress = MAX(MIN(1, progress), 0);
        }
    });
}

- (void)hideLoadingIndicator {
    self.loadingIndicator.hidden = YES;
}

- (void)showLoadingIndicator {
    self.zoomScale = 0;
    self.minimumZoomScale = 0;
    self.maximumZoomScale = 0;
    self.loadingIndicator.progress = 0;
    self.loadingIndicator.hidden = NO;
    [self hideImageFailure];
}

#pragma mark - Setup

- (CGFloat)initialZoomScaleWithMinScale {
    CGFloat zoomScale = self.minimumZoomScale;
    if (self.photoImageView && self.photoBrowser.zoomPhotosToFill) {
        // Zoom image to fill if the aspect ratios are fairly similar
        CGSize boundsSize = self.bounds.size;
        CGSize imageSize = self.photoImageView.image.size;
        CGFloat boundsAR = boundsSize.width / boundsSize.height;
        CGFloat imageAR = imageSize.width / imageSize.height;
        CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
        CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
        // Zooms standard portrait images on a 3.5in screen but not on a 4in screen.
        if (ABS(boundsAR - imageAR) < 0.17) {
            zoomScale = MAX(xScale, yScale);
            // Ensure we don't zoom in or out too far, just in case
            zoomScale = MIN(MAX(self.minimumZoomScale, zoomScale), self.maximumZoomScale);
        }
    }
    return zoomScale;
}

- (void)setMaxMinZoomScalesForCurrentBounds {
    
    // Reset
    self.maximumZoomScale = 1;
    self.minimumZoomScale = 1;
    self.zoomScale = 1;
    
    // Bail if no image
    if (self.photoImageView.image == nil) return;
    
    // Reset position
    self.photoImageView.frame = CGRectMake(0, 0, self.photoImageView.frame.size.width, self.photoImageView.frame.size.height);
	
    // Sizes
    CGSize boundsSize = self.bounds.size;
    CGSize imageSize = self.photoImageView.image.size;
    
    // Calculate Min
    CGFloat xScale = boundsSize.width / imageSize.width;    // the scale needed to perfectly fit the image width-wise
    CGFloat yScale = boundsSize.height / imageSize.height;  // the scale needed to perfectly fit the image height-wise
    CGFloat minScale = MIN(xScale, yScale);                 // use minimum of these to allow the image to become fully visible
    
    // Calculate Max
    CGFloat maxScale = 3;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        // Let them go a bit bigger on a bigger screen!
        maxScale = 4;
    }
    
    // Set min/max zoom
    self.maximumZoomScale = maxScale;
    self.minimumZoomScale = minScale;
    
    // Initial zoom
    self.zoomScale = [self initialZoomScaleWithMinScale];
    
    // Disable scrolling initially until the first pinch to fix issues with swiping on an initally zoomed in photo
    self.scrollEnabled = NO;
    
    // If it's a video then disable zooming
    if ([self displayingVideo]) {
        self.maximumZoomScale = self.zoomScale;
        self.minimumZoomScale = self.zoomScale;
    }

    // Layout
	[self setNeedsLayout];

}

#pragma mark - Layout

- (void)layoutSubviews {
	
	// Update tap view frame
	self.tapView.frame = self.bounds;
	
	// Position indicators (centre does not seem to work!)
	if (!self.loadingIndicator.hidden)
        self.loadingIndicator.frame = CGRectMake(floorf((self.bounds.size.width - self.loadingIndicator.frame.size.width) / 2.),
                                         floorf((self.bounds.size.height - self.loadingIndicator.frame.size.height) / 2),
                                         self.loadingIndicator.frame.size.width,
                                         self.loadingIndicator.frame.size.height);
	if (self.loadingError)
        self.loadingError.frame = CGRectMake(floorf((self.bounds.size.width - self.loadingError.frame.size.width) / 2.),
                                         floorf((self.bounds.size.height - self.loadingError.frame.size.height) / 2),
                                         self.loadingError.frame.size.width,
                                         self.loadingError.frame.size.height);

	// Super
	[super layoutSubviews];
	
    // Center the image as it becomes smaller than the size of the screen
    CGSize boundsSize = self.bounds.size;
    CGRect frameToCenter = self.photoImageView.frame;
    
    // Horizontally
    if (frameToCenter.size.width < boundsSize.width) {
        frameToCenter.origin.x = floorf((boundsSize.width - frameToCenter.size.width) / 2.0);
	} else {
        frameToCenter.origin.x = 0;
	}
    
    // Vertically
    if (frameToCenter.size.height < boundsSize.height) {
        frameToCenter.origin.y = floorf((boundsSize.height - frameToCenter.size.height) / 2.0);
	} else {
        frameToCenter.origin.y = 0;
	}
    
	// Center
	if (!CGRectEqualToRect(self.photoImageView.frame, frameToCenter))
		self.photoImageView.frame = frameToCenter;
	
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
	return self.photoImageView;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[self.photoBrowser cancelControlHiding];
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view {
    self.scrollEnabled = YES; // reset
	[self.photoBrowser cancelControlHiding];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	[self.photoBrowser hideControlsAfterDelay];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - Tap Detection

- (void)handleDoubleTap:(CGPoint)touchPoint {
    
    // Dont double tap to zoom if showing a video
    if ([self displayingVideo]) {
        return;
    }
	
	// Cancel any single tap handling
	[NSObject cancelPreviousPerformRequestsWithTarget:self.photoBrowser];
	
	// Zoom
	if (self.zoomScale != self.minimumZoomScale && self.zoomScale != [self initialZoomScaleWithMinScale]) {
		
		// Zoom out
		[self setZoomScale:self.minimumZoomScale animated:YES];
		
	} else {
		
		// Zoom in to twice the size
        CGFloat newZoomScale = ((self.maximumZoomScale + self.minimumZoomScale) / 2);
        CGFloat xsize = self.bounds.size.width / newZoomScale;
        CGFloat ysize = self.bounds.size.height / newZoomScale;
        [self zoomToRect:CGRectMake(touchPoint.x - xsize/2, touchPoint.y - ysize/2, xsize, ysize) animated:YES];

	}
	
	// Delay controls
	[self.photoBrowser hideControlsAfterDelay];
	
}

// Image View
- (void)imageView:(UIImageView *)imageView singleTapDetected:(UITouch *)touch {
    [self view:imageView.window singleTapDetected:touch];
}
- (void)imageView:(UIImageView *)imageView doubleTapDetected:(UITouch *)touch {
    [self handleDoubleTap:[touch locationInView:imageView]];
}

// Background View
- (void)view:(UIView *)view singleTapDetected:(UITouch *)touch {
    CGFloat touchX = [touch locationInView:view].x;
    CGFloat width = view.frame.size.width;
    if (touchX < width * 0.25 && touch.tapCount == 1) {
        [self.photoBrowser showPreviousPhotoAnimated:NO];
    }
    else if (touchX > width * 0.75 && touch.tapCount == 1)  {
        [self.photoBrowser showNextPhotoAnimated:NO];
    }
    else if (touch.tapCount == 1) {
        [self.photoBrowser performSelector:@selector(toggleControls) withObject:nil afterDelay:0.2];
    }
}

- (CGPoint)translateLocationOfTouch:(UITouch *)touch inView:(UIView *)view {
    CGFloat touchX = [touch locationInView:view].x;
    CGFloat touchY = [touch locationInView:view].y;
    touchX *= 1/self.zoomScale;
    touchY *= 1/self.zoomScale;
    touchX += self.contentOffset.x;
    touchY += self.contentOffset.y;
    return CGPointMake(touchX, touchY);
}
- (void)view:(UIView *)view doubleTapDetected:(UITouch *)touch {
    // Translate touch location to image view location
    CGPoint location = [self translateLocationOfTouch:touch inView:view];
    [self handleDoubleTap:location];
}

@end
