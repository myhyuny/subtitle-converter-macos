//
//  DragginView.m
//  SubtitleConverter
//
//  Created by Hyunmin Kang on 2/22/14.
//  Copyright (c) 2014 Hyunmin Kang. All rights reserved.
//

#import "DragginView.h"


@implementation DragginView

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self registerForDraggedTypes:@[NSFilenamesPboardType]];
    }
    return self;
}

- (void)setDelegate:(id<DropViewDelegate>)delegate {
    _delegate = delegate;
    
    [self registerForDraggedTypes:delegate ? @[NSFilenamesPboardType] : nil];
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    if ([_delegate respondsToSelector:@selector(draggingEntered:)]) {
        return [_delegate draggingEntered:sender];
    }
    
    return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    if ([_delegate respondsToSelector:@selector(performDragOperation:)]) {
        return [_delegate performDragOperation:sender];
    }
    
    return NO;
}

@end
