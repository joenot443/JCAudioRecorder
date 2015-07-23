//
//  JCAudioViewController.m
//  JCAudioRecorder
//
//  Created by Joe Crozier on 2015-07-22.
//  Copyright (c) 2015 Joe Crozier. All rights reserved.
//

#import "JCAudioViewController.h"

//The maximum time we can record for

#define MAXTIME 10.0f;

@interface JCAudioViewController () {
    BOOL buttonFlashing;
}


@property (nonatomic, retain) NSTimer *recordLevelTimer;
@property (nonatomic, retain) IBOutlet UIButton *recordButton;
@property (nonatomic, retain) IBOutlet UILabel *leftTimeLabel;
@property (nonatomic, retain) IBOutlet UILabel *rightTimeLabel;
@property (nonatomic, retain) IBOutlet UISlider *timeSlider;
@property (nonatomic, retain) IBOutlet UILabel *timeRemainingLabel;


@end




@implementation JCAudioViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //Start us out in the Empty state
    self.state = JCEmpty;
}

- (void)initializeAudioRecorder {
    [self.timeSlider setValue:0.0f];
    [self.rightTimeLabel setText:@"0:00"];
    [self.leftTimeLabel setText:@"0:00"];
    
    //Sound will be saved to NSDocumentsDirectory/sound.caf
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = dirPaths[0];
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:@"sound.caf"];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    
    //Standard recording settings
    NSDictionary *recordSettings = [NSDictionary
                                    dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:AVAudioQualityMin],
                                    AVEncoderAudioQualityKey,
                                    [NSNumber numberWithInt:16],
                                    AVEncoderBitRateKey,
                                    [NSNumber numberWithInt: 2],
                                    AVNumberOfChannelsKey,
                                    [NSNumber numberWithFloat:44100.0],
                                    AVSampleRateKey,
                                    nil];
    
    NSError *error = nil;
    //Set the sharedInstance to play/record
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    //Init the audioRecorder with our URL and settings
    self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:soundFileURL settings:recordSettings error:&error];
    
    //Delegate ourselves the audioPlayer and audioRecorder methods
    self.audioPlayer.delegate = self;
    self.audioRecorder.delegate = self;
    
    //Set the maxTime as per our macro at the top
    self.maxTime = MAXTIME;
    
    //Log any errors which may occur
    if (error)
    {
        NSLog(@"error: %@", [error localizedDescription]);
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (IBAction)recordButtonPressed:(id)sender {
    
    //We have four different possible states - Empty, Recording, Stopped, and Playing
    //Each different possibility means a different result for pressing the recordButton
    switch (self.state) {
        case JCEmpty:{
            //We haven't started recording, so initialize our recorder
            [self initializeAudioRecorder];
            [self updateTimeRemainingLabel];
            //Set an NSTimer to go off every 1 second which will call updateAudioMeter
            self.recordLevelTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updateTimeRemainingLabel) userInfo:nil repeats:YES];
            //Record for the MAXTIME duration, or until the user presses stop
            [self.audioRecorder recordForDuration:self.maxTime];
            [self startFlashingbutton];
            //Show our timeRemainingLabel
            self.timeRemainingLabel.hidden = NO;
            //Switch to the recording state
            self.state = JCRecording;
            break;
        }
        case JCRecording: {
            //Simply stop the recorder, thus calling the delegate method audioRecorderDidStopRecording
            [self.audioRecorder stop];
            break;
        }
        case JCStopped: {
            //We're stopped now, so pressing play will start the audioPlayer playing the recorded file
            [self.audioPlayer play];
            //Animate switching to the stop icon (currently on the play icon)
            [self animateImageChange:@"stop-icon.png"];
            //Switch to the playing state
            self.state = JCPlaying;
            //Our timeSlider should have a maximum value of the duration, and a minimum value of 0
            [self.timeSlider setMaximumValue:self.audioPlayer.duration];
            [self.timeSlider setMinimumValue:0.0f];
            //Every 0.01 seconds (for smoothness!), call updateBar
            self.updateAudioTimer = [NSTimer scheduledTimerWithTimeInterval:0.01f target:self selector:@selector(updateBar) userInfo:nil repeats:YES];
            break;
        }
        case JCPlaying: {
            //We're currently playing, so pressing stop will stop the player
            [self.audioPlayer stop];
            //Get ready to play again
            [self.audioPlayer prepareToPlay];
            //Set our player's current time back to 0
            [self.audioPlayer setCurrentTime:0.0f];
            //Set our timeSlider back to 0
            self.timeSlider.value = 0.0f;
            //Set our timer to nil (stopping it!)
            self.updateAudioTimer = nil;
            //Animate switching to the play icon (currently on the stop icon)
            [self animateImageChange:@"play-icon.png"];
            //Switch to the stopped state
            self.state = JCStopped;
            break;
        }
        default:
            break;
    }
    
}

- (IBAction)cancelButtonPressed:(id)sender {
    //User pressed the cancel button, so set our state to Empty
    self.state = JCEmpty;
    //Switch to the mic icon
    [self animateImageChange:@"mic-icon.png"];
    //Reinitialize the audio recorder
    [self initializeAudioRecorder];
}

- (void)animateImageChange: (NSString *)imageTitle {

    UIImage *newImage = [UIImage imageNamed:imageTitle];
    //Simple UIView transition which will take 0.3 seconds to flip out a new image for our button
    [UIView transitionWithView:self.recordButton duration:0.3f options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
        [self.recordButton setImage:newImage forState:UIControlStateNormal];
    } completion:nil];
    
}

- (void)updateTimeRemainingLabel {
    //Set our time remaining label
    [self.timeRemainingLabel setText:[NSString stringWithFormat:@"Time remaining: %@", [self timeFormatted:self.maxTime - self.audioRecorder.currentTime]]];
}

- (void)updateBar {
    //Set the progress on our bar to be the current time in the player
    float progress = self.audioPlayer.currentTime;
    [self.timeSlider setValue:progress];
    [self.leftTimeLabel setText:[self timeFormatted:self.audioPlayer.currentTime]];
    
}

- (NSString *)timeFormatted:(int)totalSeconds
{
    int seconds = totalSeconds % 60;
    int minutes = (totalSeconds / 60) % 60;
    //Convert secoonds to a time formatted string
    return [NSString stringWithFormat:@"%01d:%02d", minutes, seconds];
}

-(void) startFlashingbutton
{
    //Simple UIView animation to flash the mic icon from 1.0f to 0.5f
    
    if (buttonFlashing) return;
    buttonFlashing = YES;
    self.recordButton.alpha = 1.0f;
    [UIView animateWithDuration:0.4
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut |
     UIViewAnimationOptionRepeat |
     UIViewAnimationOptionAutoreverse |
     UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                         self.recordButton.alpha = 0.5f;
                     }
                     completion:^(BOOL finished){
                         // Do nothing
                     }];
}

-(void) stopFlashingbutton
{
    //Stop the flashing animation.
    
    if (!buttonFlashing) return;
    buttonFlashing = NO;
    [UIView animateWithDuration:0.12
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut |
     UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                         self.recordButton.alpha = 1.0f;
                     }
                     completion:^(BOOL finished){
                         // Do nothing
                     }];
}
#pragma mark AudioPlayer / AudioRecorder

//These methods are called automatically by audioPlayer and audioRecorder

-(void) audioPlayerDidFinishPlaying:
(AVAudioPlayer *)player successfully:(BOOL)flag
{
    //Once the player is done, switch to the Stopped state and set the icon to Play
    self.state = JCStopped;
    [self animateImageChange:@"play-icon.png"];
}

-(void)audioPlayerDecodeErrorDidOccur:
(AVAudioPlayer *)player error:(NSError *)error
{
    NSLog(@"Decode Error occurred");
}

-(void)audioRecorderDidFinishRecording:
(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    //Stop our flashing button
    [self stopFlashingbutton];
    //Stop our timer
    [self.recordLevelTimer invalidate];
    //Hide the time remaining label
    self.timeRemainingLabel.hidden = YES;
    //Switch to the play icon
    [self animateImageChange:@"play-icon.png"];
    //Initialize the audioPlayer with our audioRecorder's url and delegate it
    self.audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:self.audioRecorder.url error:nil];
    self.audioPlayer.delegate = self;
    //Reset the right time label
    [self.rightTimeLabel setText:[self timeFormatted:self.audioPlayer.duration]];
    //Set the state to Stopped
    self.state = JCStopped;
    //Set our audioData to the contents of the audioPlayer's url
    self.audioData = [NSData dataWithContentsOfURL:self.audioPlayer.url];
    
}

-(void)audioRecorderEncodeErrorDidOccur:
(AVAudioRecorder *)recorder error:(NSError *)error
{
    NSLog(@"Encode Error occurred");
}

@end