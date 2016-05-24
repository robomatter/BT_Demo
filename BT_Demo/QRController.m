/*-----------------------------------------------------------------------------*/
/*    QRController.m                                                           */
/*                                                                             */
/*    Created by James Pearman on  5/24/16.                                    */
/*    Copyright (c) 2016 robomatter. All rights reserved.                      */
/*-----------------------------------------------------------------------------*/
/*    This file is part of the robomatter BT_Demo code for the VexIQ           */
/*                                                                             */
/*    BT_Demo is free software: you can redistribute it and/or modify          */
/*    it under the terms of the GNU General Public License as published by     */
/*    the Free Software Foundation, either version 3 of the License, or        */
/*    (at your option) any later version.                                      */
/*                                                                             */
/*    BT_Demo is distributed in the hope that it will be useful,               */
/*    but WITHOUT ANY WARRANTY; without even the implied warranty of           */
/*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the            */
/*    GNU General Public License for more details.                             */
/*                                                                             */
/*    You should have received a copy of the GNU General Public License        */
/*    along with this program.  If not, see <http://www.gnu.org/licenses/>.    */
/*-----------------------------------------------------------------------------*/

#import "QRController.h"

@interface QRController ()
@property (nonatomic, strong) AVCaptureSession           *captureSession;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;

-(BOOL)startReading;
-(void)stopReading;

@end

@implementation QRController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Start camera
    [self startReading];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

// Calcel button
- (IBAction)doneButtonAction:(id)sender {
  // Set qrcode to 0 and exit
  self.qrcode = 0;
  [self performSegueWithIdentifier:@"unwindToViewController1" sender:self];
}

// Start camera
- (BOOL)startReading {
  NSError *error;
  
  // Get an instance of the AVCaptureDevice class to initialize a device object and provide the video
  // as the media type parameter.
  AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
  
  // Get an instance of the AVCaptureDeviceInput class using the previous device object.
  AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
  
  if (!input) {
    // If any error occurs, simply log the description of it and don't continue any more.
    NSLog(@"%@", [error localizedDescription]);
    return NO;
  }
  
  // Initialize the captureSession object.
  _captureSession = [[AVCaptureSession alloc] init];
  // Set the input device on the capture session.
  [_captureSession addInput:input];
  
  
  // Initialize a AVCaptureMetadataOutput object and set it as the output device to the capture session.
  AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
  [_captureSession addOutput:captureMetadataOutput];
  
  // Create a new serial dispatch queue.
  dispatch_queue_t dispatchQueue;
  dispatchQueue = dispatch_queue_create("myQueue", NULL);
  [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
  [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
  
  // Initialize the video preview layer and add it as a sublayer to the viewPreview view's layer.
  _videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
  [_videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
  [_videoPreviewLayer setFrame:_viewPreview.layer.bounds];
  [_viewPreview.layer addSublayer:_videoPreviewLayer];
  
  
  // Start video capture.
  [_captureSession startRunning];
  
  return YES;
}


-(void)stopReading{
  // Stop video capture and make the capture session object nil.
  [_captureSession stopRunning];
  _captureSession = nil;
  
  // Remove the video preview layer from the viewPreview view's layer.
  [_videoPreviewLayer removeFromSuperlayer];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate method implementation

-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
  
  // Check if the metadataObjects array is not nil and it contains at least one object.
  if (metadataObjects != nil && [metadataObjects count] > 0) {
    // Get the metadata object.
    AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
    if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
      // If the found metadata is equal to the QR code metadata then update the status label's text,
      // stop reading and change the bar button item's title and the flag's value.
      // Everything is done on the main thread.
      //[_lblStatus performSelectorOnMainThread:@selector(setText:) withObject:[metadataObj stringValue] waitUntilDone:NO];
      
      [self performSelectorOnMainThread:@selector(stopReading) withObject:nil waitUntilDone:NO];
      
      self.qrcode = [[metadataObj stringValue] intValue];
      [self performSegueWithIdentifier:@"unwindToViewController1" sender:self];
    }
  }  
}

@end
