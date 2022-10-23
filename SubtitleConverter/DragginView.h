//
//  DragginView.h
//  SubtitleConverter
//
//  Created by Hyunmin Kang on 2/22/14.
//  Copyright (c) 2014 Hyunmin Kang. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol DropViewDelegate <NSDraggingDestination>

@end


@interface DragginView : NSView

@property (weak, nonatomic) id <DropViewDelegate> delegate;

@end
