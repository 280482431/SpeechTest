//
//  ViewController.m
//  SpeechTest
//
//  Created by lvfj on 26/08/2017.
//  Copyright © 2017 lvfj All rights reserved.
//

#import "ViewController.h"
#import <Speech/Speech.h>

@interface ViewController ()<AVSpeechSynthesizerDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *recordButton;

@property (nonatomic, strong) AVAudioEngine *audioEngine;
@property (nonatomic, strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic, strong) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;
@property (nonatomic, strong) AVSpeechSynthesizer *speechSynthesizer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 请求权限
    [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        NSLog(@"status %@", status == SFSpeechRecognizerAuthorizationStatusAuthorized ? @"授权成功" : @"授权失败");
    }];
    
    [self.recordButton addTarget:self action:@selector(startRecording:) forControlEvents:UIControlEventTouchDown];
    [self.recordButton addTarget:self action:@selector(stopRecording:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
}

- (void)initEngine {
    if (!self.speechRecognizer) {
        // 设置语言
        NSLocale *locale = [NSLocale localeWithLocaleIdentifier:@"zh-CN"];
        self.speechRecognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
    }
    if (!self.audioEngine) {
        self.audioEngine = [[AVAudioEngine alloc] init];
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryRecord mode:AVAudioSessionModeMeasurement options:AVAudioSessionCategoryOptionDuckOthers error:nil];
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
    
    if (self.recognitionRequest) {
        [self.recognitionRequest endAudio];
        self.recognitionRequest = nil;
    }
    self.recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    self.recognitionRequest.shouldReportPartialResults = YES; // 实时翻译
    
    [self.speechRecognizer recognitionTaskWithRequest:self.recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        NSLog(@"is final: %d  result: %@", result.isFinal, result.bestTranscription.formattedString);
        if (result.isFinal) {
            self.textView.text = [NSString stringWithFormat:@"%@%@", self.textView.text, result.bestTranscription.formattedString];
        }
    }];
}
- (IBAction)chinese:(id)sender {
    [self doTextChangeVoice:@"我是谁?" Language:@"zh-CN"];
}
- (IBAction)english:(id)sender {
    [self doTextChangeVoice:@"what the fuck?" Language:@"en-US"];
}
-(void)doTextChangeVoice:(NSString *)text Language:(NSString *)Language{
    AVSpeechUtterance *speechUtterance = [[AVSpeechUtterance alloc] initWithString:text];
   /// 播放语音速率(AVSpeechUtteranceMinimumSpeechRate - AVSpeechUtteranceMaximumSpeechRate)
   speechUtterance.rate = AVSpeechUtteranceDefaultSpeechRate;
   /// 基线音高(0.5 - 2. default 1.0)
   speechUtterance.pitchMultiplier = 1.0;
   /// 音量(0 - 1. default 1.0)
   speechUtterance.volume = 1.0;
   /// 下面两个属性是在一个`AVSpeechSynthesizer`实例的情况下,如果有多个`AVSpeechUtterance`实例在播放.每个`AVSpeechUtterance`实例播放间隔是`pre`+`post`之和.default 0
   speechUtterance.preUtteranceDelay = 1.0;
   speechUtterance.postUtteranceDelay = 1.0;
   AVSpeechSynthesisVoice *voice = [AVSpeechSynthesisVoice voiceWithLanguage:Language];
   /// 设置发音
   speechUtterance.voice = voice;
   [self.speechSynthesizer speakUtterance:speechUtterance];
//    speechSynthesizer.delegate = self;
}

- (AVSpeechSynthesizer *)speechSynthesizer{
    if (!_speechSynthesizer) {
        _speechSynthesizer = [[AVSpeechSynthesizer alloc] init];
    }
    return _speechSynthesizer;
}
- (void)releaseEngine {
    [[self.audioEngine inputNode] removeTapOnBus:0];
    [self.audioEngine stop];
    
    [self.recognitionRequest endAudio];
    self.recognitionRequest = nil;
}

- (void)startRecording:(UIButton *)recordButton {
    [self initEngine];
    
    AVAudioFormat *recordingFormat = [[self.audioEngine inputNode] outputFormatForBus:0];
    [[self.audioEngine inputNode] installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        [self.recognitionRequest appendAudioPCMBuffer:buffer];
    }];
    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:nil];
    
    [recordButton setTitle:@"录音ing" forState:UIControlStateNormal];
}
/**
 typedef NS_ENUM(NSInteger, AVSpeechBoundary) {
     /// 立即停止
     AVSpeechBoundaryImmediate,
     /// 说完一整个单词再停止
     AVSpeechBoundaryWord
 } NS_ENUM_AVAILABLE(10_14, 7_0);

 /// 停止
 - (BOOL)stopSpeakingAtBoundary:(AVSpeechBoundary)boundary;
 /// 暂停
 - (BOOL)pauseSpeakingAtBoundary:(AVSpeechBoundary)boundary;
 /// 继续
 - (BOOL)continueSpeaking;
 */
/// 开始语音
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14)){
    
}

/// 语音结束
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14)){
    
}

/// 语音暂停
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didPauseSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14)){
    
}

/// 语音继续
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didContinueSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14)){
    
}

/// 语音取消
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didCancelSpeechUtterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14)){
    
}

/// 语音将要播放范围
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer willSpeakRangeOfSpeechString:(NSRange)characterRange utterance:(AVSpeechUtterance *)utterance API_AVAILABLE(ios(7.0), watchos(1.0), tvos(7.0), macos(10.14)){
    
}


- (void)stopRecording:(UIButton *)recordButton {
    [self releaseEngine];
    
    [recordButton setTitle:@"录音" forState:UIControlStateNormal];
}

@end
