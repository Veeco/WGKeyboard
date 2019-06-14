//
//  WGTextView.m
//  Keyboard
//
//  Created by Veeco on 2019/6/6.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "WGTextView.h"

@implementation WGTextView

- (void)deleteBackward {
    
    if ([self.wgDelegate respondsToSelector:@selector(didDeleteBackwardWithTextView:)]) {
        [self.wgDelegate didDeleteBackwardWithTextView:self];
    }
    [super deleteBackward];
}

@end
