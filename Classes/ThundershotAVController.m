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
static bool firstFrame = true;
static float prev_brightness;
static bool isDetecting = false;
static bool isFirst = true;
static CGColorSpaceRef colorSpace;
static CMTimeScale timescale = 1000000;


// TODO: show focus points
// TODO: manual focus (really?)
// TODO: show help on first launch
// TODO: rotate UI elements
// TODO: check image orientation
// TOOD: check UI on iPad

static double f(double x) {
	return cbrt(x);
}

static double inversef(double y) {
	return y * y * y;
}


@interface ThundershotAVController () <AVCaptureVideoDataOutputSampleBufferDelegate>
@property (nonatomic) NSInteger saveOperationsCount;
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *layer;
@property (nonatomic, strong) AVCaptureConnection *videoConnection;
@property (strong, nonatomic) IBOutlet UISlider *sensitivity;
@property (strong, nonatomic) IBOutlet UIView *imageView;
@property (strong, nonatomic) IBOutlet PTSliderWithValue *exposureSlider;
@property (strong, nonatomic) IBOutlet PTSliderWithValue *gainSlider;
@property (strong, nonatomic) AVCaptureVideoDataOutput *captureOutput;
@property (strong, nonatomic) AVCaptureStillImageOutput *photoOutput;
@property (strong, nonatomic) IBOutlet UISlider *whiteSlider;
@property (strong, nonatomic) IBOutlet UIDeselectableSegmentedControl *flashLightSwitch;
@property (strong, nonatomic) IBOutlet UIDeselectableSegmentedControl *exposureSwitch;
@property (strong, nonatomic) IBOutlet UIDeselectableSegmentedControl *whiteSwitch;
@property (strong, nonatomic) IBOutlet UISwitch *lightningSwitch;
@property (strong, nonatomic) IBOutlet UIToolbar *bottomBar;
@property (strong, nonatomic) IBOutlet UIToolbar *topBar;
@property (strong, nonatomic) IBOutlet UIActivityIndicatorView *activity;
@property (strong, nonatomic) IBOutlet UIView *helpView;
@property (strong, nonatomic) IBOutlet UIImageView *exampleView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *constraintToDisable;

- (void)setupCapture;

@end

enum FlashSwitchSection {
	kFlashSwitchSectionAuto = 0,
	kFlashSwitchSectionTorch = 1,
	kFlashSwitchSectionOn = 2,
	kFlashSwitchSectionOff = 3
};

enum AutoManualSwitchSection {
	kSwitchSectionAuto = 0,
	kSwitchSectionManual = 1
};

@implementation ThundershotAVController


- (BOOL)shouldAutorotate {
	return YES;
}

- (UIInterfaceOrientationMask) supportedInterfaceOrientations {
	return UIInterfaceOrientationMaskAll;
}

- (IBAction)closeHelp {
	self.helpView.hidden = true;
}

- (IBAction)openHelp {
	self.helpView.hidden = !self.helpView.hidden;
}

- (IBAction)flashLightSwitchClick:(UIDeselectableSegmentedControl*)sender {
	AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	[device lockForConfiguration:nil];
	[device setTorchMode:(sender.selectedSegmentIndex == kFlashSwitchSectionTorch) ? AVCaptureTorchModeOn : AVCaptureTorchModeOff];
	switch (sender.selectedSegmentIndex) {
		case kFlashSwitchSectionAuto: [device setFlashMode:AVCaptureFlashModeAuto]; break;
		case kFlashSwitchSectionTorch:
		case kFlashSwitchSectionOff: [device setFlashMode:AVCaptureFlashModeOff]; break;
		case kFlashSwitchSectionOn: [device setFlashMode:AVCaptureFlashModeOn]; break;
	}
	[device unlockForConfiguration];
}


- (void)viewDidAppear:(BOOL)animated {
	self.saveOperationsCount = 0;
	[self setupCapture];
	
	AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	if (device == nil) {
		//return;
	}
	[device lockForConfiguration:nil];
	
	if ([device hasTorch] && [device hasFlash]) { // FIXME: бывают ли устройства без вспышки, но с фонариком?
		self.flashLightSwitch.right = NO;
		self.flashLightSwitch.image = [UIImage imageNamed:@"Light Bulb"];
		[self.flashLightSwitch setTitles:@"Auto", @"Torch", @"Flash", @"Off", nil];
		self.flashLightSwitch.selectedSegmentIndex = kFlashSwitchSectionOff;
	}
	else
		[self.flashLightSwitch removeFromSuperview];
	
	if ([device isExposureModeSupported:AVCaptureExposureModeCustom]) {
		self.gainSlider.minimumValue = device.activeFormat.minISO;
		self.gainSlider.maximumValue = device.activeFormat.maxISO;
		
		self.gainSlider.toStringLambda = ^NSString*(float v) {
			return [NSString stringWithFormat:@"ISO %d", (int)v];
		};
		
		timescale = device.activeFormat.minExposureDuration.timescale;
		
		// 1 / minvalue = value / timescale
		
		//self.exposureSlider.minValue = (double)device.activeFormat.minExposureDuration.timescale / (double)device.activeFormat.minExposureDuration.value;
		
		self.exposureSlider.minValue = f(device.activeFormat.minExposureDuration.value);
		self.exposureSlider.maxValue = f(
										 MIN((long double)device.activeFormat.maxExposureDuration.value / (long double)device.activeFormat.maxExposureDuration.timescale, 0.2) * (long double)timescale
										 );
		
		self.exposureSlider.toStringLambda = ^NSString*(float v) {
			return [NSString stringWithFormat:@"Exposure 1/%d", (int)((double)timescale / inversef(v))];
		};
		
		self.exposureSwitch.right = NO;
		self.exposureSwitch.image = [UIImage imageNamed:@"Brightness"];
		[self.exposureSwitch setTitles:@"Auto", @"Manual", nil];
		
	}
	else {
		[self.exposureSwitch removeFromSuperview];
		[self.exposureSlider removeFromSuperview];
		[self.gainSlider removeFromSuperview];
	}
	
	self.whiteSlider.minimumValue = 2000;
	self.whiteSlider.maximumValue = 20000;
	
	self.whiteSwitch.right = YES;
	self.whiteSwitch.image = [UIImage imageNamed:@"WB"];
	[self.whiteSwitch setTitles:@"Auto", @"Manual", nil];
	
	[device unlockForConfiguration];
	
	self.topBar.hidden = NO;
	self.bottomBar.hidden = NO;
	
	self.sensitivity.minimumValueImage = [UIImage imageFromText:@"Low"];
	self.sensitivity.maximumValueImage = [UIImage imageFromText:@"High"];
	self.whiteSlider.minimumValueImage = [UIImage imageFromText:@"Cold"];
	self.whiteSlider.maximumValueImage = [UIImage imageFromText:@"Warm"];
	
	
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
	
	[super viewDidAppear:animated];
}

- (IBAction)tap:(UITapGestureRecognizer*)sender {
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	if ([device isFocusModeSupported:AVCaptureFocusModeAutoFocus] &&
		[device isFocusPointOfInterestSupported])
	{
		[device lockForConfiguration:nil];
		[device setFocusPointOfInterest:[self.layer captureDevicePointOfInterestForPoint:[sender locationInView:self.view]]];
		[device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
		[device unlockForConfiguration];
	}
}
- (IBAction)doubleTap:(UITapGestureRecognizer *)sender {
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	if ([device isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus] &&
		[device isFocusPointOfInterestSupported])
	{
		[device lockForConfiguration:nil];
		[device setFocusPointOfInterest:[self.layer captureDevicePointOfInterestForPoint:[sender locationInView:self.view]]];
		[device setFocusMode:AVCaptureFocusModeAutoFocus];
		[device unlockForConfiguration];
	}
	
}

- (IBAction)layout {
	self.constraintToDisable.active = self.exposureSwitch.selectedSegmentIndex; // 0 - auto, 1 - manual
}

- (IBAction)switchLightningDetection:(id)sender {
	UISwitch* sw = sender;
	isDetecting = sw.on;
	self.sensitivity.hidden = !sw.on;
	self.flashLightSwitch.hidden = sw.on;
	if (isDetecting) {
		firstFrame = true;
		self.flashLightSwitch.selectedSegmentIndex = 3; // disable flashlight
	}
}

- (IBAction)brightnessSwitchValueChanged:(UIDeselectableSegmentedControl *)sender {
	AVCaptureDevice* device;
	switch (sender.selectedSegmentIndex) {
		case 0:
			self.exposureSlider.hidden = self.gainSlider.hidden = YES;
			device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
			[device lockForConfiguration:nil];
			[device setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
			[device unlockForConfiguration];
			break;
			
		case 1:
			device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
			self.exposureSlider.hidden = self.gainSlider.hidden = NO;
			[self brightnessChange:sender];
			break;
	}
}

- (IBAction)brightnessChange:(id)sender {
	AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	[device lockForConfiguration:nil];
	CMTime s = { ceil(inversef(self.exposureSlider.value)), timescale, 1, 0};
	
	
	if (s.value / s.timescale < device.activeFormat.minExposureDuration.value / device.activeFormat.minExposureDuration.timescale)
		s = device.activeFormat.minExposureDuration;
	
	if (s.value / s.timescale > device.activeFormat.maxExposureDuration.value / device.activeFormat.maxExposureDuration.timescale)
		s = device.activeFormat.maxExposureDuration;
	[device setExposureModeCustomWithDuration:s ISO:self.gainSlider.value completionHandler:^void(CMTime s){
		AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
		[device unlockForConfiguration];
	}];
}


- (IBAction)whiteSwitchValueChanged:(UIDeselectableSegmentedControl *)sender {
	AVCaptureDevice* device;
	switch (sender.selectedSegmentIndex) {
		case 0:
			device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
			[device lockForConfiguration:nil];
			self.whiteSlider.hidden = YES;
			
			[device setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
			[device unlockForConfiguration];
			break;
			
		case 1:
			self.whiteSlider.hidden = NO;
			[self whiteChange:sender];
			break;
	}
}

#define clamp(m, value, M) (MIN((M), MAX((m), (value))))

- (IBAction)whiteChange:(id)sender {
	AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	[device lockForConfiguration:nil];
	
	AVCaptureWhiteBalanceTemperatureAndTintValues tt;
	tt.tint = 0.0f;
	tt.temperature = self.whiteSlider.value;
	
	AVCaptureWhiteBalanceGains gains = [device deviceWhiteBalanceGainsForTemperatureAndTintValues:tt];
	
	gains.redGain = clamp(1, gains.redGain, device.maxWhiteBalanceGain);
	gains.blueGain = clamp(1, gains.blueGain, device.maxWhiteBalanceGain);
	gains.greenGain = clamp(1, gains.greenGain, device.maxWhiteBalanceGain);
	
	[device setWhiteBalanceModeLockedWithDeviceWhiteBalanceGains:gains completionHandler:^(CMTime syncTime) {
		AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
		[device unlockForConfiguration];
	}];
}

//- (void)flashScreen {
//	UIView *flashView = [[UIView alloc] initWithFrame:self.layer.frame];
//	[flashView setBackgroundColor:[UIColor whiteColor]];
//	[[[self view] window] addSubview:flashView];
//	
//	[UIView animateWithDuration:1.f
//					 animations:^{
//						 [flashView setAlpha:0.f];
//					 }
//					 completion:^(BOOL finished){
//						 [flashView removeFromSuperview];
//					 }
//	 ];
//}

- (UIImage*)orientedImageFromImage:(CGImageRef)image {
	UIImageOrientation imageOrientation;
	switch ([self interfaceOrientation]) {
		case UIInterfaceOrientationPortraitUpsideDown:
			imageOrientation = UIImageOrientationUp;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			imageOrientation = UIImageOrientationDown;
			break;
		case UIInterfaceOrientationLandscapeRight:
			imageOrientation = UIImageOrientationLeft;
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
	//if (sender == self.cameraButton) {
	
	///}
	
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
	AVCaptureDevice* device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	colorSpace = CGColorSpaceCreateDeviceRGB(); // FIXME: never released
	
	AVCaptureDeviceInput *captureInput = [AVCaptureDeviceInput
										  deviceInputWithDevice:device
										  error:nil];
	
	
	/*We setup the output*/
	self.captureOutput = [[AVCaptureVideoDataOutput alloc] init];
	self.captureOutput.alwaysDiscardsLateVideoFrames = YES;
	//captureOutput.minFrameDuration = CMTimeMake(1, 10);
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
		[self.layer.connection setVideoOrientation:[ThundershotAVController videoOrientationFromInterfaceOrientation:[self interfaceOrientation]]];
	}
	[self.captureSession startRunning];
}

+ (AVCaptureVideoOrientation) videoOrientationFromInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation {
	switch (interfaceOrientation) {
		case UIInterfaceOrientationLandscapeLeft:
			return AVCaptureVideoOrientationLandscapeLeft;
		case UIInterfaceOrientationLandscapeRight:
			return AVCaptureVideoOrientationLandscapeRight;
		case UIInterfaceOrientationPortraitUpsideDown:
			return AVCaptureVideoOrientationPortraitUpsideDown;
		default:
			return AVCaptureVideoOrientationPortrait;
	}
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	[super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
	if (!self.layer) return;
	self.layer.connection.videoOrientation = [ThundershotAVController videoOrientationFromInterfaceOrientation:toInterfaceOrientation];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(nonnull id<UIViewControllerTransitionCoordinator>)coordinator {
	[super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
	if (self.layer)
		self.layer.frame = CGRectMake(0, 0, size.width, size.height);
}

#pragma mark -
#pragma mark AVCaptureSession delegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
	   fromConnection:(AVCaptureConnection *)connection
{
	if (!isDetecting) return;
	/*if (saveNext) {
	 [self captureOutputHigh:captureOutput didOutputSampleBuffer:sampleBuffer fromConnection:connection];
	 saveNext = false;
	 return;
	 }*/
	/*uint32_t histogram[256];
	 
	 uint8_t histogram_image[256*256];*/
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
		/*  bzero(histogram, 256*sizeof(uint32_t));
		 //bzero(histogram_image, 256*256);
		 
		 for (int i = 0; i < 4*n; i+=32) {
		 histogram[(baseAddress[i]+baseAddress[i+1]+baseAddress[i+2])/3]++;
		 }
		 n /= 8;
		 
		 for (int i = 0; i < 256; i++) {
		 //int j = (histogram[i] <= 256) ? histogram[i] : 256;
		 int j = histogram[i] ? (log(histogram[i])/log(n)) * 256 : 0;
		 memset(histogram_image + i*256, 255, j);
		 bzero(histogram_image + i*256 + j, 256-j);
		 }
		 */
		
		uint64_t pixels_sum = 0;
		
#define SKIP 64
		for (int i = 0; i < 4*n; i += 4*SKIP)
			pixels_sum += (baseAddress[i]+baseAddress[i+1]+baseAddress[i+2]);
		float avg_brightness = (float)pixels_sum / ((256 * 3 * n) / SKIP);
		
		/*  for (int i = 0; i < 256; i++) {
		 //int j = (histogram[i] <= 256) ? histogram[i] : 256;
		 int j = avg_brightness * 256.0f;
		 memset(histogram_image + i*256, 255, j);
		 bzero(histogram_image + i*256 + j, 256-j);
		 }
		 
		 
		 
		 for (int i = 0; i < 50*bytesPerRow; i+=4) {
		 baseAddress[i] = 128;
		 baseAddress[i+1] = 128;
		 baseAddress[i+2] = 0;
		 }
		 
		 CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
		 CGContextRef newContext = CGBitmapContextCreate(histogram_image, 256, 256, 8, 256, colorSpace, kCGBitmapByteOrderDefault);
		 CGImageRef histImage = CGBitmapContextCreateImage(newContext);
		 
		 CGContextRelease(newContext);
		 CGColorSpaceRelease(colorSpace);*/
		if (firstFrame) {
			prev_brightness = avg_brightness;
			firstFrame = false;
		}
		// sensitivity = -threshold
		else if (avg_brightness - prev_brightness >= -self.sensitivity.value) {
			
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
			
			UIImage *orientedImage = [self orientedImageFromImage:newImage];
			CGImageRelease(newImage);
			self.saveOperationsCount++;
			[self.activity startAnimating];
			
			UIImageWriteToSavedPhotosAlbum(orientedImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
		}
		else {
			//NSLog(@"frame processed");
			
			/*We unlock the  image buffer*/
			CVPixelBufferUnlockBaseAddress(imageBuffer,0);
		}
		prev_brightness = avg_brightness;
		isFirst = false;
	}
}


// -(void)orientationChanged:(NSNotification *)notif {
//	UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
//	
//	// Calculate rotation angle
//	CGFloat angle;
//	switch (deviceOrientation) {
// case UIDeviceOrientationPortraitUpsideDown:
// angle = M_PI;
// break;
// case UIDeviceOrientationLandscapeLeft:
// angle = M_PI_2;
// break;
// case UIDeviceOrientationLandscapeRight:
// angle = - M_PI_2;
// break;
// default:
// angle = 0;
// break;
//	}
//	[UIView animateWithDuration:.3 animations:^{
// self.closeButton.transform = CGAffineTransformMakeRotation(angle);
// self.gridButton.transform = CGAffineTransformMakeRotation(angle);
// self.flashButton.transform = CGAffineTransformMakeRotation(angle);
//	} completion:^(BOOL finished) {
// 
//	}];
//	
// }

@end