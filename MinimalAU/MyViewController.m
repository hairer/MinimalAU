//
//  MyViewController.m
//  MinimalAU
//
//  Created by Martin on 22/06/2020.
//  Copyright © 2020 HairerSoft. All rights reserved.
//

#import "MyViewController.h"
#import <AVKit/AVKit.h>
#import <CoreAudioKit/CoreAudioKit.h>

@interface NSView (_private_)
-(void)pinToSuperview;
@end

@implementation NSView (_private_)
-(void)pinToSuperview
{
    if (!self.superview) return;
    
    NSLayoutConstraint* top = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.superview
                                                           attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    NSLayoutConstraint* bottom = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.superview
                                                              attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    NSLayoutConstraint* left = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.superview
                                                            attribute:NSLayoutAttributeLeft multiplier:1.0 constant:0];
    NSLayoutConstraint* right = [NSLayoutConstraint constraintWithItem:self attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.superview
                                                             attribute:NSLayoutAttributeRight multiplier:1.0 constant:0];
    [NSLayoutConstraint activateConstraints:@[top,bottom,left,right]];
}
@end

@interface MyViewController ()
{
    NSLayoutConstraint *widthConstraint, *heightConstraint;
}
@end

@implementation MyViewController

-(NSArray*)viewConfigurations
{return nil;}

-(void)setFormatForBus:(AUAudioUnitBus*)bus
{
    AudioStreamBasicDescription fmt = {44100, kAudioFormatLinearPCM, kAudioFormatFlagIsNonInterleaved | kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked, 4, 1, 4, 2, 32, 0};  // Stereo audio on each bus
    AVAudioFormat* format = [[AVAudioFormat alloc] initWithStreamDescription:&fmt];
    NSError* error = nil;
    if (![bus setFormat:format error:&error]) {
        NSLog(@"Couldn't set the format for bus... %@", error);
        return;
    }
    
    bus.enabled = YES;
}

-(void)doLoad:(AVAudioUnit*)node controller:(NSViewController*)viewController
{
    if (viewController == nil) {
        self.auView = [[AUGenericView alloc] initWithAudioUnit:node.audioUnit displayFlags:(AUViewPropertiesDisplayFlag | AUViewParametersDisplayFlag)];
    }
    else {
        NSLog(@"Preferred size: %@", NSStringFromSize(viewController.preferredContentSize));
        [self addChildViewController:viewController];
        self.auView = viewController.view;
    }
    self.auView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.auView];

    NSSize size = self.auView.frame.size;

    widthConstraint = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:size.width];
    heightConstraint = [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1 constant:size.height];

    [NSLayoutConstraint activateConstraints:@[widthConstraint, heightConstraint]];
    [self.auView pinToSuperview];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSArray* list = [[AVAudioUnitComponentManager sharedAudioUnitComponentManager] componentsPassingTest: ^BOOL(AVAudioUnitComponent *comp, BOOL *stop) {
        return [comp.typeName containsString:@"Effect"];
    }];
    
    AVAudioUnitComponent* component = nil;
    for (AVAudioUnitComponent* comp in list) {
        if ([comp.name containsString:@"FilterDemo"])  // That allows itself to be squashed. Also, it doesn't resize itself when "details" is toggled
//        if ([comp.name containsString:@"FilterDemo"]) // That one is squashed both vertically and horizontally... (Apple's sample AUv3 Audio Unit, needs to be installed first.)
//        if ([comp.name containsString:@"AUMultibandCompressor"])  // That one works fine, toggling "details" works as expected
//        if ([comp.name containsString:@"AUMatrixReverb"])  // That one works fine
            component = comp;
    }
    
    [AVAudioUnit instantiateWithComponentDescription:component.audioComponentDescription options:0
                                   completionHandler:^(__kindof AVAudioUnit *audioUnit, NSError *error) {
        if (error) {
            NSLog(@"Error instantiating AU: %@", error);
            return;
        }
        
        self.audioUnit = audioUnit;
        AUAudioUnitBusArray* inputBusses = audioUnit.AUAudioUnit.inputBusses;
        AUAudioUnitBusArray* outputBusses = audioUnit.AUAudioUnit.outputBusses;
        
        if (!inputBusses.count || !outputBusses.count) {
            NSLog(@"No busses...");
            return;
        }
        
        [self setFormatForBus:[inputBusses objectAtIndexedSubscript:0]];
        [self setFormatForBus:[outputBusses objectAtIndexedSubscript:0]];
        
        NSError* AUerror = nil;
        if (![audioUnit.AUAudioUnit allocateRenderResourcesAndReturnError:&AUerror]){
            NSLog(@"Error allocating resources: %@", AUerror);
            return;
        }
        [audioUnit.AUAudioUnit requestViewControllerWithCompletionHandler:^(NSViewController* viewController) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self doLoad:audioUnit controller:viewController];
            });
        }];
    }];
}

- (void)viewWillLayout
{
    [super viewWillLayout];
    if (self.auView != nil) {
        NSSize size = self.auView.frame.size;
        widthConstraint.constant = size.width;
        heightConstraint.constant = size.height;
    }
}

@end
