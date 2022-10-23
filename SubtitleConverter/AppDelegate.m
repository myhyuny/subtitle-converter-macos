//
//  AppDelegate.m
//  SubtitleConverter
//
//  Created by Hyunmin Kang on 2/22/14.
//  Copyright (c) 2014 Hyunmin Kang. All rights reserved.
//

#import "AppDelegate.h"
#import "DragginView.h"
#import "SubtitleConverter.h"
#import "NSRegularExpression+MFExtended.h"


NSString *const OutputType = @"OutputType";
NSString *const InputEncoding = @"InputEncoding";
NSString *const OutputEncoding = @"OutputEncoding";
NSString *const LineDelimiter = @"LineDelimiter";


@interface AppDelegate () <NSApplicationDelegate, NSTextFieldDelegate, DropViewDelegate> {
@private
    NSDictionary *_encodings;
    NSRegularExpression *_syncRegularExpression;
    NSRegularExpression *_fileCheckRegularExpression;
    BOOL _run;
    BOOL _hide;
}

@property (weak) IBOutlet NSWindow *window;

@property (weak) IBOutlet DragginView *dragginView;

@property (weak) IBOutlet NSTextField *outputTypeLabelTextField;
@property (weak) IBOutlet NSTextField *inputCharsetLabelTextField;
@property (weak) IBOutlet NSTextField *outputCharsetLabelTypeTextField;
@property (weak) IBOutlet NSTextField *lineDelimiterLabelTextField;
@property (weak) IBOutlet NSTextField *syncLabelTextField;

@property (weak) IBOutlet NSPopUpButton *outputTypePopUpButton;
@property (weak) IBOutlet NSPopUpButton *inputCharsetPopUpButton;
@property (weak) IBOutlet NSPopUpButton *outputCharsetPopUpButton;
@property (weak) IBOutlet NSPopUpButton *lineDelimiterPopUpButton;
@property (weak) IBOutlet NSTextField *syncTextField;

@property (weak) IBOutlet NSProgressIndicator *progressIndicator;
@property (weak) IBOutlet NSTextField *messageLabelTextField;

@end


@implementation AppDelegate

#pragma mark - Application delegate

- (BOOL)application:(NSApplication *)sender openFile:(NSString *)filename {
    return YES;
}

- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self convertFiles:filenames];
    });
}

- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag {
    if (!flag) {
        [_window makeKeyAndOrderFront:self];
    }
    
    return !flag;
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {
    NSMutableDictionary *encodings = [[NSMutableDictionary alloc] init];
    for (const NSStringEncoding *encoding = [NSString availableStringEncodings]; *encoding != 0; encoding++) {
        encodings[[NSString localizedNameOfStringEncoding:*encoding]] = @(*encoding);
    }
    _encodings = [encodings copy];
    
    _fileCheckRegularExpression =[[NSRegularExpression alloc] initWithPattern:@"^(sa?mi|srt)$" options:NSRegularExpressionCaseInsensitive error:nil];
    _syncRegularExpression = [[NSRegularExpression alloc] initWithPattern:@"-?\\d+\\.?\\d*" options:0 error:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [_outputTypeLabelTextField setStringValue:NSLocalizedString(@"Output Type", nil)];
    [_inputCharsetLabelTextField setStringValue:NSLocalizedString(@"Input Encoding", nil)];
    [_outputCharsetLabelTypeTextField setStringValue:NSLocalizedString(@"Output Encoding", nil)];
    [_lineDelimiterLabelTextField setStringValue:NSLocalizedString(@"Line Delimiter", nil)];
    [_syncLabelTextField setStringValue:NSLocalizedString(@"Sync", nil)];
    
    [_outputTypePopUpButton addItemsWithTitles:@[NSLocalizedString(@"SAMI (smi)", nil), NSLocalizedString(@"SubRip (srt)", nil)]];
    
    NSArray *itemTitles = [_encodings.allKeys sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray *inputEncodingItemTitles = [[NSMutableArray alloc] initWithCapacity:itemTitles.count + 1];
    [inputEncodingItemTitles addObject:NSLocalizedString(@"Auto (UTF-8 Or System Default)", nil)];
    [inputEncodingItemTitles addObjectsFromArray:itemTitles];
    
    [_inputCharsetPopUpButton addItemsWithTitles:inputEncodingItemTitles];
    [_outputCharsetPopUpButton addItemsWithTitles:itemTitles];
    [_outputCharsetPopUpButton selectItemWithTitle:[NSString localizedNameOfStringEncoding:NSUTF8StringEncoding]];
    
    [_lineDelimiterPopUpButton addItemsWithTitles:@[NSLocalizedString(@"Default", nil), NSLocalizedString(@"Unix", nil), NSLocalizedString(@"Windows", nil)]];
    
    _messageLabelTextField.stringValue = @"";
    [_messageLabelTextField resignFirstResponder];
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *outputType = [defaults stringForKey:OutputType];
    NSString *inputEncoding = [defaults stringForKey:InputEncoding];
    NSString *outputEncoding = [defaults stringForKey:OutputEncoding];
    NSString *lineDelimiter = [defaults stringForKey:LineDelimiter];
    [_outputTypePopUpButton selectItemWithTitle:outputType.length > 0 ? outputType : NSLocalizedString(@"SubRip (srt)", nil)];
    [_inputCharsetPopUpButton selectItemWithTitle:inputEncoding.length > 0 ? inputEncoding : NSLocalizedString(@"Auto (UTF-8 Or System Default)", nil)];
    [_outputCharsetPopUpButton selectItemWithTitle:outputEncoding.length > 0 ? outputEncoding : [NSString localizedNameOfStringEncoding:NSUTF8StringEncoding]];
    [_lineDelimiterPopUpButton selectItemWithTitle:lineDelimiter.length > 0 ? lineDelimiter : NSLocalizedString(@"Default", nil)];
    
    _dragginView.delegate = self;
}

- (void)applicationDidHide:(NSNotification *)notification {
    _hide = YES;
}

- (void)applicationWillUnhide:(NSNotification *)notification {
    _hide = NO;
}

- (void)applicationDidResignActive:(NSNotification *)notification {
    if (!_hide && !_window.visible) {
        [[NSApplication  sharedApplication] terminate:self];
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setValue:_outputTypePopUpButton.selectedItem.title forKey:OutputType];
    [defaults setValue:_inputCharsetPopUpButton.selectedItem.title forKey:InputEncoding];
    [defaults setValue:_outputCharsetPopUpButton.selectedItem.title forKey:OutputEncoding];
    [defaults setValue:_lineDelimiterPopUpButton.selectedItem.title forKey:LineDelimiter];
    
    [defaults synchronize];
}


#pragma mark - Custom methods

- (void)setEnabled:(BOOL)enabled {
    _outputCharsetLabelTypeTextField.enabled = enabled;
    _inputCharsetLabelTextField.enabled = enabled;
    _outputCharsetLabelTypeTextField.enabled = enabled;
    _lineDelimiterLabelTextField.enabled = enabled;
    _syncLabelTextField.enabled = enabled;
    _outputTypePopUpButton.enabled = enabled;
    _inputCharsetPopUpButton.enabled = enabled;
    _outputCharsetPopUpButton.enabled = enabled;
    _lineDelimiterPopUpButton.enabled = enabled;
    _syncTextField.enabled = enabled;
}

- (BOOL)checkFiles:(NSArray *)files {
    for (NSString *file in files) {
        NSString *extension = file.pathExtension;
        if ([_fileCheckRegularExpression numberOfMatchesInString:extension options:0 range:NSMakeRange(0, extension.length)] < 1) {
            return NO;
        }
    }
    
    return YES;
}

- (NSTimeInterval)timeFromString:(NSString *)string {
    return [_syncRegularExpression stringByFirstMatchInString:string options:0 range:NSMakeRange(0, string.length)].doubleValue;
}

- (void)updateSyncTextField:(NSTimeInterval)time {
    _syncTextField.stringValue = [(@(time)).stringValue stringByAppendingString:@" sec"];
}

- (void)convertFiles:(NSArray *)files {
    _progressIndicator.maxValue = files.count;
    _progressIndicator.doubleValue = 0.0;
    [_progressIndicator startAnimation:self];
    _messageLabelTextField.stringValue = @"Converting";
    
    [self setEnabled:NO];
    
    SubtitleType outputType = (SubtitleType)0;
    NSString *value = _outputTypePopUpButton.selectedItem.title;
    if ([value isEqualToString:NSLocalizedString(@"SAMI (smi)", nil)]) {
        outputType = SubtitleTypeSAMI;
    } else if ([value isEqualToString:NSLocalizedString(@"SubRip (srt)", nil)]) {
        outputType = SubtitleTypeSubRip;
    }
    
    NSStringEncoding inputEncoding = [[_encodings valueForKey:_inputCharsetPopUpButton.selectedItem.title] unsignedIntegerValue];
    NSStringEncoding outputEncoding = [[_encodings valueForKey:_outputCharsetPopUpButton.selectedItem.title] unsignedIntegerValue];
    
    LineDelimiterType type = LineDelimiterTypeUnix;
    value = _lineDelimiterPopUpButton.selectedItem.title;
    if ([value isEqualToString:NSLocalizedString(@"Windows", nil)]) {
        type = LineDelimiterTypeWindows;
    }
    
    NSTimeInterval sync = [self timeFromString:_syncTextField.stringValue];
    [self updateSyncTextField:sync];
    
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
    dispatch_async(queue, ^{
        dispatch_apply(files.count, queue, ^(size_t i) {@autoreleasepool {
            SubtitleConverter *converter = [[SubtitleConverter alloc] initWithFile:files[i] outputType:outputType inputEncoding:inputEncoding outputEncoding:outputEncoding lineDelimiterType:type sync:sync];
            [converter save];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self->_progressIndicator.doubleValue = self->_progressIndicator.doubleValue + 1.0;
                
                if (self->_progressIndicator.doubleValue == self->_progressIndicator.maxValue) {
                    [self->_progressIndicator stopAnimation:self];
                    
                    [self->_messageLabelTextField setStringValue:NSLocalizedString(@"Complete", nil)];
                    
                    [self setEnabled:YES];
                    
                    self->_run = NO;
                }
            });
        }});
    });
}


#pragma mark - Action methods

- (IBAction)openDocument:(id)sender {
    NSOpenPanel *openPanel = [[NSOpenPanel alloc] init];
    openPanel.allowsMultipleSelection = YES;
    openPanel.allowedFileTypes = @[@"smi", @"sami", @"srt"];
    [openPanel beginWithCompletionHandler:^(NSInteger result) {
        if (result != NSModalResponseOK) {
            return;
        }
        
        [self convertFiles:[openPanel.URLs valueForKeyPath:@"path"]];
    }];
}


#pragma mark - Text field delegate

- (void)controlTextDidChange:(NSNotification *)obj {
    [obj.object stringValue];
}

- (void)controlTextDidEndEditing:(NSNotification *)obj {
    [self updateSyncTextField:[self timeFromString:_syncTextField.stringValue]];
}


#pragma mark - Dragging view delegate

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    if (_run) {
        return NSDragOperationNone;
    }
    
    NSPasteboard *pasteboard = sender.draggingPasteboard;
    
    if (![pasteboard.types containsObject:NSFilenamesPboardType]) {
        return NSDragOperationNone;
    }
    
    NSDragOperation dragOperation = sender.draggingSourceOperationMask;
    
    if (!(dragOperation & NSDragOperationCopy)) {
        return NSDragOperationNone;
    }
    
    return [self checkFiles:[pasteboard propertyListForType:NSFilenamesPboardType]] ? NSDragOperationCopy : NSDragOperationNone;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    _run = YES;
    
    [self convertFiles:[sender.draggingPasteboard propertyListForType:NSFilenamesPboardType]];
    
    return YES;
}

@end
