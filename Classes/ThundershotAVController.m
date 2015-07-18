#import "ThundershotAVController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "UIDeselectableSegmentedControl.h"
#import "UIImage+TextWithImage.h"
#import "Thundershot-Swift.h"
#import <AssetsLibrary/AssetsLibrary.h>
#include <math.h>


static double f(double x) {
	return cbrt(x);
}

static double inversef(double y) {
	return y * y * y;
}


@interface ThundershotAVController () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic, strong) IBOutlet UIView *rulesView;
@property (nonatomic, strong) IBOutlet UILabel *rulesLabel;
@property (nonatomic, strong) UIView* flashView;
@property (nonatomic) bool firstFrame;
@property (nonatomic) float prev_brightness;
@property (nonatomic) bool isDetecting;
@property (nonatomic) bool isFirst;
@property (nonatomic) CGColorSpaceRef colorSpace;
@property (nonatomic) CMTimeScale timescale;
@property (nonatomic) UIInterfaceOrientation orientation;
@property (nonatomic) NSInteger saveOperationsCount;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *layer;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;
@property (strong, nonatomic) IBOutlet PTSliderWithRotatableLabel *sensitivity;
@property (strong, nonatomic) IBOutlet UIView *imageView;
@property (strong, nonatomic) IBOutlet PTSliderWithValue *exposureSlider;
@property (strong, nonatomic) IBOutlet PTSliderWithValue *gainSlider;
@property (strong, nonatomic) AVCaptureVideoDataOutput *captureOutput;
@property (strong, nonatomic) AVCaptureStillImageOutput *photoOutput;
@property (strong, nonatomic) IBOutlet PTSliderWithValue *whiteSlider;
@property (strong, nonatomic) IBOutlet PTMultipleStateButton *flashLightSwitch;
@property (strong, nonatomic) IBOutlet UISwitchButton *exposureSwitch;
@property (strong, nonatomic) IBOutlet UISwitchButton *whiteSwitch;
@property (strong, nonatomic) IBOutlet UISwitchButton *lightningSwitch;
@property (strong, nonatomic) IBOutlet UIToolbar *bottomBar;
@property (strong, nonatomic) IBOutlet UIToolbar *topBar;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (strong, nonatomic) IBOutlet UIView *helpView;
@property (strong, nonatomic) IBOutlet UIImageView *exampleView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *sensitivityConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *focusConstraint;
@property (strong, nonatomic) IBOutlet UIButton *helpButton;
@property (strong, nonatomic) IBOutlet UIButton *cameraButton;
@property (strong, nonatomic) IBOutlet PTSliderWithValue *focusSlider;
@property (strong, nonatomic) IBOutlet UISwitchButton *focusSwitch;
@property (weak, nonatomic) IBOutlet UISwipeGestureRecognizer *swipeGestureRecognizer;
@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *singleTapGestureRecognizer;
@property (weak, nonatomic) IBOutlet UITapGestureRecognizer *doubleTapGestureRecognizer;
@property (strong, nonatomic) NSLayoutConstraint *helpViewConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *helpViewConstraintCenterY;
@property (strong, nonatomic) AVCaptureDevice *device;
@property (strong, nonatomic) IBOutlet PTFocusMarkView *focusMarkView;


// Help labels
@property (strong, nonatomic) IBOutlet UILabel *helpLabel;
@property (strong, nonatomic) IBOutlet UILabel *focusLabel;


- (void)setupCapture;

@end

enum FlashSwitchSection {
	kFlashSwitchSectionAuto = 0,
	kFlashSwitchSectionTorch = 1,
	kFlashSwitchSectionOn = 2,
	kFlashSwitchSectionOff = 3
};


@implementation ThundershotAVController

- (IBAction)showRules {
	[self.view addSubview:self.rulesView];
}

- (IBAction)acceptRules {
	NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
	[defaults setObject:[NSNumber numberWithBool:YES] forKey:@"hideRules"];
	[defaults synchronize];
	[self.rulesView removeFromSuperview];
}

- (BOOL)shouldAutorotate {
	return NO;
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskPortrait;
}

- (IBAction)closeHelp {
	self.helpButton.selected = NO;
	[UIView animateWithDuration:.3 animations:^{
		self.helpViewConstraint.active = YES;
		self.helpViewConstraintCenterY.active = NO;
		[self.view layoutIfNeeded];
	} completion:^(BOOL finished) {
	}];
}

- (IBAction)openHelp {
	[UIView animateWithDuration:.3 animations:^{
		self.helpViewConstraint.active = !self.helpButton.selected;
		self.helpViewConstraintCenterY.active = self.helpButton.selected;
		[self.view layoutIfNeeded];
	} completion:^(BOOL finished) {
	}];
}

- (IBAction)flashLightSwitchClick:(PTMultipleStateButton*)sender {
	[self.device lockForConfiguration:nil];
	[self.device setTorchMode:(sender.selectedState == kFlashSwitchSectionTorch) ? AVCaptureTorchModeOn : AVCaptureTorchModeOff];
	switch (sender.selectedState) {
		case kFlashSwitchSectionAuto: [self.device setFlashMode:AVCaptureFlashModeAuto]; break;
		case kFlashSwitchSectionTorch:
		case kFlashSwitchSectionOff: [self.device setFlashMode:AVCaptureFlashModeOff]; break;
		case kFlashSwitchSectionOn: [self.device setFlashMode:AVCaptureFlashModeOn]; break;
	}
	[self.device unlockForConfiguration];
}


- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	
	NSUserDefaults *defaults=[NSUserDefaults standardUserDefaults];
	BOOL hideRules = [(NSNumber*)[defaults objectForKey:@"hideRules"] boolValue];
	
	
	[[NSNotificationCenter defaultCenter] addObserver:self  selector:@selector(orientationChanged:)  name:UIDeviceOrientationDidChangeNotification  object:nil];
	
	self.firstFrame = YES;
	self.isDetecting = NO;
	self.isFirst = YES;
	self.saveOperationsCount = 0;
	
	self.focusConstraint.active = NO;
	self.sensitivityConstraint.active = NO;
	self.helpViewConstraint = [NSLayoutConstraint constraintWithItem:self.helpView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.topBar attribute:NSLayoutAttributeTop multiplier:1 constant:0];
	self.helpViewConstraintCenterY.active = NO;
	[self.view addConstraint:self.helpViewConstraint];
	self.helpViewConstraint.priority = 1000;
	self.helpViewConstraint.active = YES;
	
	self.flashLightSwitch.semicolonSeparatedStateLabels = NSLocalizedString(@"FlashlightStates", @"auto,torch,flash,off");
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"Rules" ofType:@"rtf"];
	NSData *data = [NSData dataWithContentsOfFile:filePath];
	self.rulesLabel.attributedText = [[NSAttributedString alloc] initWithData:data options:@{NSDocumentTypeDocumentAttribute:NSRTFTextDocumentType} documentAttributes:nil error:nil];

	
	[self setupCapture];
	
	[self.device lockForConfiguration:nil];
	
	self.flashLightSwitch.enabled = [self.device hasTorch] && [self.device hasFlash];
	
	if ([self.device isExposureModeSupported:AVCaptureExposureModeCustom]) {
		self.gainSlider.minimumValue = self.device.activeFormat.minISO;
		self.gainSlider.maximumValue = self.device.activeFormat.maxISO;
		
		self.gainSlider.toStringLambda = ^NSString*(float v) {
			return [NSString stringWithFormat:@"ISO\n%d", (int)v];
		};
		
		self.timescale = self.device.activeFormat.minExposureDuration.timescale;
		
		// 1 / minvalue = value / timescale
		
		//self.exposureSlider.minValue = (double)self.device.activeFormat.minExposureDuration.timescale / (double)self.device.activeFormat.minExposureDuration.value;
		
		self.exposureSlider.minValue = f(self.device.activeFormat.minExposureDuration.value);
		self.exposureSlider.maxValue = f(
										 MIN((long double)self.device.activeFormat.maxExposureDuration.value / (long double)self.device.activeFormat.maxExposureDuration.timescale, 0.2) * (long double)self.timescale
										 );
		
		self.exposureSlider.toStringLambda = ^NSString*(float v) {
			return [NSString stringWithFormat:NSLocalizedString(@"ExposureFormat", @"for slider lambda; 1/%d sec"), (int)((double)self.timescale / inversef(v))];
		};
		
		self.focusSlider.toStringLambda = ^NSString*(float v) {
			return [NSString stringWithFormat:NSLocalizedString(@"FocusFormat", @"for slider lambda; %.2f"), v];
		};
		
	}
	else
		self.exposureSwitch.enabled = NO;
	
	self.focusSwitch.enabled = [self.device isFocusModeSupported:AVCaptureFocusModeLocked];
	
	if ([self.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked]) {
		self.whiteSlider.minimumValue = 2500;
		self.whiteSlider.maximumValue = 20000;
		self.whiteSlider.toStringLambda = ^NSString*(float v) {
			return [NSString stringWithFormat:NSLocalizedString(@"TemperatureFormat", @"for slider lambda; %d K"), (int)roundf(v)];
		};
	}
	else
		self.whiteSwitch.enabled = NO;
	
	[self.device unlockForConfiguration];
	
	for (AVCaptureConnection *connection in self.photoOutput.connections)
	{
		for (AVCaptureInputPort *port in [connection inputPorts])
			if ([[port mediaType] isEqual:AVMediaTypeVideo] )
			{
				self.videoConnection = connection;
				break;
			}
		if (self.videoConnection)
			break;
	}
	
	if (self.videoConnection)
		self.exampleView.hidden = YES;
	
	if (!hideRules) {
		self.rulesView.frame = self.view.bounds;
		[self.view addSubview:self.rulesView];
	}
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self orientationChanged:nil];
	self.flashView = [[UIView alloc] initWithFrame:self.view.frame];
	self.flashView.backgroundColor = [UIColor whiteColor];
	self.flashView.hidden = YES;
	[self.view addSubview:self.flashView];
	[self.singleTapGestureRecognizer requireGestureRecognizerToFail:self.doubleTapGestureRecognizer];
}

- (IBAction)tap:(UITapGestureRecognizer*)sender {
	if ([self.device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus] &&
		[self.device isFocusPointOfInterestSupported])
	{
		[self.device lockForConfiguration:nil];
		[self.device setFocusPointOfInterest:[self.layer captureDevicePointOfInterestForPoint:[sender locationInView:self.view]]];
		[self.device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
		[self.device unlockForConfiguration];
		self.focusMarkView.point = [sender locationInView:self.view];
		self.focusMarkView.hidden = NO;
		self.focusMarkView.willHide = NO;
		// show until a change
	}
}
- (IBAction)doubleTap:(UITapGestureRecognizer *)sender {
	if ([self.device isFocusModeSupported:AVCaptureFocusModeAutoFocus] &&
		[self.device isFocusPointOfInterestSupported])
	{
		[self.device lockForConfiguration:nil];
		[self.device setFocusPointOfInterest:[self.layer captureDevicePointOfInterestForPoint:[sender locationInView:self.view]]];
		[self.device setFocusMode:AVCaptureFocusModeAutoFocus];
		[self.device unlockForConfiguration];
		self.focusMarkView.point = [sender locationInView:self.view];
		self.focusMarkView.hidden = NO;
		self.focusMarkView.willHide = YES;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			if (self.focusMarkView.willHide)
				self.focusMarkView.hidden = YES;
		});
	}
}

- (void)layoutWithContinueBlock:(void(^)(BOOL))block {
	[UIView animateWithDuration:.3 animations:^{
		self.sensitivityConstraint.active = self.exposureSwitch.selected; // 0 - auto, 1 - manual
		self.focusConstraint.active = self.whiteSwitch.selected;
		[self.view layoutIfNeeded];
	} completion:block];
}

- (IBAction)switchLightningDetection:(id)sender {
	UISwitchButton* sw = sender;
	self.isDetecting = sw.selected;
	self.sensitivity.hidden = !sw.selected;
	self.flashLightSwitch.enabled = !sw.selected && [self.device hasFlash] && [self.device hasTorch];
	if (self.isDetecting) {
		self.firstFrame = YES;
		self.flashLightSwitch.selectedState = kFlashSwitchSectionOff; // disable flashlight
	}
}

- (IBAction)exposureSwitchValueChanged:(UISwitchButton *)sender {
	if (sender.selected) {
		[self layoutWithContinueBlock:^(BOOL finished){
			self.exposureSlider.value = f((double)self.device.exposureDuration.value * (double)self.timescale / (double)self.device.exposureDuration.timescale);
			self.gainSlider.value = self.device.ISO;
			self.exposureSlider.hidden = self.gainSlider.hidden = NO;
			[self.exposureSlider sendActionsForControlEvents:UIControlEventValueChanged];
			[self.gainSlider sendActionsForControlEvents:UIControlEventValueChanged];
			[self exposureChange:sender];
		}];

	}
	else {
		self.exposureSlider.hidden = self.gainSlider.hidden = YES;
		[self.device lockForConfiguration:nil];
		[self.device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
		[self.device unlockForConfiguration];
		[self layoutWithContinueBlock:nil];
	}
}

- (IBAction)exposureChange:(id)sender {
	[self.device lockForConfiguration:nil];
	CMTime s = { ceil(inversef(self.exposureSlider.value)), self.timescale, 1, 0};
	
	
	if (s.value / s.timescale < self.device.activeFormat.minExposureDuration.value / self.device.activeFormat.minExposureDuration.timescale)
		s = self.device.activeFormat.minExposureDuration;
	
	if (s.value / s.timescale > self.device.activeFormat.maxExposureDuration.value / self.device.activeFormat.maxExposureDuration.timescale)
		s = self.device.activeFormat.maxExposureDuration;
	[self.device setExposureModeCustomWithDuration:s ISO:self.gainSlider.value completionHandler:^void(CMTime s){
		AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
		[device unlockForConfiguration];
	}];
}


- (IBAction)whiteSwitchValueChanged:(UISwitchButton *)sender {
	if (sender.selected) {
		[self layoutWithContinueBlock:^(BOOL finished) {
			self.whiteSlider.hidden = NO;
			[self whiteChange:sender];
		}];
	}
	else {
		self.whiteSlider.hidden = YES;
		[self.device lockForConfiguration:nil];
		[self.device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
		[self.device unlockForConfiguration];
		[self layoutWithContinueBlock:nil];
	}
	
	
	
}

#define clamp(m, value, M) (MIN((M), MAX((m), (value))))

- (IBAction)whiteChange:(id)sender {
	[self.device lockForConfiguration:nil];
	
	AVCaptureWhiteBalanceTemperatureAndTintValues tt;
	tt.tint = 0.0f;
	tt.temperature = self.whiteSlider.value;
	
	AVCaptureWhiteBalanceGains gains = [self.device deviceWhiteBalanceGainsForTemperatureAndTintValues:tt];
	
	gains.redGain = clamp(1, gains.redGain, self.device.maxWhiteBalanceGain);
	gains.blueGain = clamp(1, gains.blueGain, self.device.maxWhiteBalanceGain);
	gains.greenGain = clamp(1, gains.greenGain, self.device.maxWhiteBalanceGain);
	
	[self.device setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:gains completionHandler:^(CMTime syncTime) {
		AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
		[device unlockForConfiguration];
	}];
}

- (IBAction)focusSwitchChange: (UISwitchButton*)sender {
	[self.device lockForConfiguration:nil];
	if (sender.selected) {
		self.focusSlider.value = self.device.lensPosition;
		[self.device setFocusModeLockedWithLensPosition:AVCaptureLensPositionCurrent completionHandler:^(CMTime syncTime) {
			AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
			[device unlockForConfiguration];
		}];
		self.focusSlider.hidden = NO;
		self.focusMarkView.hidden = YES;
	}
	else {
		[self.device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
		[self.device setFocusPointOfInterest:CGPointMake(0.5f, 0.5f)];
		[self.device unlockForConfiguration];
		self.focusMarkView.point = self.view.center;
		self.focusMarkView.hidden = NO;
		self.focusMarkView.willHide = NO;
		self.focusSlider.hidden = YES;
	}
}

- (IBAction)focusChange:(PTSliderWithValue*)sender {
	[self.device lockForConfiguration:nil];
	[self.device setFocusModeLockedWithLensPosition:sender.value completionHandler:^(CMTime syncTime) {
		AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
		[device unlockForConfiguration];
	}];
}

- (void)flashScreen {
	self.flashView.alpha = 1.f;
	self.flashView.hidden = NO;
	
	[UIView animateWithDuration:1.f
					 animations:^{
						 self.flashView.alpha = 0.f;
					 }
					 completion:^(BOOL finished){
						 self.flashView.hidden = YES;
					 }
	 ];
}

- (UIImage*)orientedImageFromImage:(CGImageRef)image {
	UIImageOrientation imageOrientation = UIImageOrientationRight;
	switch (self.orientation) {
		case UIInterfaceOrientationPortraitUpsideDown:
			imageOrientation = UIImageOrientationLeft;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			imageOrientation = UIImageOrientationUp;
			break;
		case UIInterfaceOrientationLandscapeRight:
			imageOrientation = UIImageOrientationDown;
			break;
		case UIInterfaceOrientationPortrait:
		default:
			imageOrientation = UIImageOrientationRight;
			break;
	}
	return [UIImage imageWithCGImage:image scale:1.0f orientation:imageOrientation];
}


- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo: (void *) contextInfo {
	self.saveOperationsCount--;
	if (!self.saveOperationsCount)
		[self.activity stopAnimating];
}

- (IBAction)takePhoto:(id)sender {
	
	// Flash the screen white and fade it out
	if (sender == self.cameraButton) {
		[self flashScreen];
	}
	
	if (!self.videoConnection) return;
	
	[self.photoOutput captureStillImageAsynchronouslyFromConnection:self.videoConnection completionHandler: ^(CMSampleBufferRef imageSampleBuffer, NSError *error)
	 {
		 NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
		 
		 self.saveOperationsCount++;
		 [self.activity startAnimating];
		 UIImageWriteToSavedPhotosAlbum([self orientedImageFromImage:[[UIImage alloc] initWithData:imageData].CGImage], self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
	 }];
}

- (void)setupCapture {
	/*We setup the input*/
	self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	self.colorSpace = CGColorSpaceCreateDeviceRGB(); // FIXME: never released
	
	AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
	
	/*We setup the output*/
	self.captureOutput = [[AVCaptureVideoDataOutput alloc] init];
	self.captureOutput.alwaysDiscardsLateVideoFrames = YES;
	[self.captureOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
	// Set the video output to store frame in BGRA (It is supposed to be faster)
	NSDictionary* videoSettings = @{(__bridge NSString*)kCVPixelBufferPixelFormatTypeKey: [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]};
	self.captureOutput.videoSettings = videoSettings;
	
	self.photoOutput = [[AVCaptureStillImageOutput alloc] init];
	
	self.photoOutput.outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
	
	self.captureSession = [[AVCaptureSession alloc] init];
	if (captureInput) [self.captureSession addInput:captureInput];
	[self.captureSession setSessionPreset:AVCaptureSessionPresetPhoto];
	[self.captureSession addOutput:self.captureOutput];
	[self.captureSession addOutput:self.photoOutput];
	
	self.layer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
	self.layer.frame = self.view.bounds;
	self.layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
	
	
	[self.view.layer insertSublayer:self.layer atIndex:0];
	
	if ([self.layer.connection isVideoOrientationSupported]) {
		[self.layer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
	}
	[self.captureSession startRunning];
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
	   fromConnection:(AVCaptureConnection *)connection
{
	if (!self.isDetecting) return;
	/*if (saveNext) {
	 [self captureOutputHigh:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
	 saveNext = NO;
	 return;
	 }*/
	
	@autoreleasepool {
		//CFDictionaryRef metadata = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
		CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
		/*Lock the image buffer*/
		CVPixelBufferLockBaseAddress(imageBuffer,0);
		/*Get information about the image*/
		uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
		size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
		size_t width = CVPixelBufferGetWidth(imageBuffer);
		size_t height = CVPixelBufferGetHeight(imageBuffer);
		size_t n = width*height;
		uint64_t pixels_sum = 0;
		
#define SKIP 64
		for (int i = 0; i < 4*n; i += 4*SKIP)
			pixels_sum += (baseAddress[i]+baseAddress[i+1]+baseAddress[i+2]);
		float avg_brightness = (float)pixels_sum / ((256 * 3 * n) / SKIP);
		
		if (self.firstFrame) {
			self.prev_brightness = avg_brightness;
			self.firstFrame = NO;
		}
		// sensitivity = -threshold
		else if (avg_brightness - self.prev_brightness >= -self.sensitivity.value) {
			
			// create suitable color space
			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			
			//Create suitable context (suitable for camera output setting kCVPixelFormatType_32BGRA)
			CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
			
			// <<<<<<<<<< unlock buffer address
			CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
			
			// Do the image saving here...
			// release color space
			CGColorSpaceRelease(colorSpace);
			
			//Create a CGImageRef from the CVImageBufferRef
			CGImageRef newImage = CGBitmapContextCreateImage(newContext);
			
			// release context
			CGContextRelease(newContext);
			
			[self takePhoto:self];
			
			self.saveOperationsCount++;
			[self.activity startAnimating];
			UIImage *orientedImage = [self orientedImageFromImage:newImage];
			CGImageRelease(newImage);
			
			UIImageWriteToSavedPhotosAlbum(orientedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
		}
		else {
			//NSLog(@"frame processed");
			
			/*We unlock the  image buffer*/
			CVPixelBufferUnlockBaseAddress(imageBuffer,0);
		}
		self.prev_brightness = avg_brightness;
		self.isFirst = NO;
	}
}

- (void) orientationChanged:(NSNotification *)notif {
	// Calculate rotation angle
	CGFloat angle;
	switch ([[UIDevice currentDevice] orientation]) {
		case UIDeviceOrientationPortraitUpsideDown:
			angle = M_PI;
			self.orientation = UIInterfaceOrientationPortraitUpsideDown;
			break;
		case UIDeviceOrientationLandscapeLeft:
			angle = M_PI_2;
			self.orientation = UIInterfaceOrientationLandscapeLeft;
			break;
		case UIDeviceOrientationLandscapeRight:
			angle = - M_PI_2;
			self.orientation = UIInterfaceOrientationLandscapeRight;
			break;
		case UIDeviceOrientationPortrait:
			angle = 0;
			self.orientation = UIInterfaceOrientationPortrait;
			break;
		default:
			return;
	}
	
	CGAffineTransform t = CGAffineTransformMakeRotation(angle);
	[UIView animateWithDuration:.3 animations:^{
		// segmented control
		self.flashLightSwitch.orientation = self.orientation;
		
		// buttons
		self.whiteSwitch.transform = t;
		self.exposureSwitch.transform = t;
		self.lightningSwitch.transform = t;
		self.helpButton.transform = t;
		self.cameraButton.transform = t;
		self.focusSwitch.transform = t;
		
		// sliders
		self.exposureSlider.labelTransform = t;
		self.gainSlider.labelTransform = t;
		self.whiteSlider.labelTransform = t;
		self.sensitivity.labelTransform = t;
		self.focusSlider.labelTransform = t;
		
		// coordinates
		for (NSLayoutConstraint* c in self.focusLabel.constraints)
			if (c.firstAttribute == NSLayoutAttributeCenterX) {
				[self.focusLabel removeConstraint:c];
				break;
			}
		
		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.focusLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.focusSwitch attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
		
		for (NSLayoutConstraint* c in self.helpLabel.constraints)
			if (c.firstAttribute == NSLayoutAttributeCenterX) {
				[self.helpLabel removeConstraint:c];
				break;
			}
		
		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.helpLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.helpButton attribute:NSLayoutAttributeCenterX multiplier:1 constant:0]];
		
	} completion:^(BOOL finished) {
	}];
}

@end