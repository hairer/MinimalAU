//
//  MyViewController.h
//  MinimalAU
//
//  Created by Martin on 22/06/2020.
//  Copyright © 2020 HairerSoft. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <AVKit/AVKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MyViewController : NSViewController

@property (readwrite,strong) NSView* auView;
@property (readwrite,strong) AVAudioUnit* audioUnit;

@end

NS_ASSUME_NONNULL_END
