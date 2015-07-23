//
//  JCAudioViewController.h
//  JCAudioRecorder
//
//  Created by Joe Crozier on 2015-07-22.
//  Copyright (c) 2015 Joe Crozier. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface JCAudioViewController : UIViewController <AVAudioPlayerDelegate, AVAudioRecorderDelegate>

//enum for our different states
typedef enum {
    JCEmpty = 0,
    JCRecording = 1,
    JCStopped = 2,
    JCPlaying = 3
} JCRecordingState;

@property (nonatomic, retain) AVAudioRecorder *audioRecorder;
@property (nonatomic, retain) AVAudioPlayer *audioPlayer;
@property (nonatomic) JCRecordingState state;
@property (nonatomic, retain) NSTimer *updateAudioTimer;
@property (nonatomic) NSTimeInterval maxTime;
@property (nonatomic, retain) NSData *audioData;

- (IBAction)recordButtonPressed:(id)sender;
- (IBAction)cancelButtonPressed:(id)sender;

@end

