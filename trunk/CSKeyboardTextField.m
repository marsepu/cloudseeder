//
//  CSKeyboardTextField.m
//  CloudSeeder
//
//  Created by David Shu on 6/17/11.
//  Copyright 2011 Retronyms. All rights reserved.
//

#import "CSKeyboardTextField.h"

typedef struct {
    float duration;
    NSInteger curve;
    CGRect startFrame;
    CGRect endFrame;
} KeyboardInfo;

@interface CSKeyboardTextField(Private)
- (void)setup;
- (CGRect)fullScreenFrame;
- (BOOL)dismissKeyboard:(BOOL)aDidConfirmInput;
- (IBAction)dismissButtonPressed:(id)sender;
- (KeyboardInfo)keyboardInfoFromDict:(NSDictionary *)kbDict;
@end


@implementation CSKeyboardTextField
@synthesize parentView = mParentView;
@synthesize textField = mTextField;
@synthesize delegate = mDelegate;
@synthesize userInfo = mUserInfo;
@synthesize didConfirmInput = mDidConfirmInput;


- (id)initWithFrame:(CGRect)frame {
    
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code.
    }
    return self;
}

- (void)setup {
	mTextField.delegate = self;
    mDidConfirmInput = NO;
}

- (void)dealloc {
    NSLog(@"CSKeyboardTextField dealloc");

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [mDummyTextField removeFromSuperview];
    self.userInfo = nil;
    
	// IBOutlets
	[mTextField release]; mTextField = nil;
	
    [super dealloc];
}


#pragma mark - Public
- (UIView *)parentView {
	if (!mParentView) {
		// Only the first subview gets the rotation events:
		// http://stackoverflow.com/questions/2508630/orientation-in-a-uiview-added-to-a-uiwindow
		UIWindow* window = [UIApplication sharedApplication].keyWindow;
		if (!window) 
			window = [[UIApplication sharedApplication].windows objectAtIndex:0];
		mParentView = [[window subviews] objectAtIndex:0];
	}
	return mParentView;
}

- (CGRect)fullScreenFrame {
	UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
	return [keyWindow convertRect:keyWindow.frame toView:self.parentView];
}

+ (CSKeyboardTextField *)create {
	CSKeyboardTextField *v = nil;
	NSArray *top_level = [[NSBundle mainBundle] loadNibNamed:@"CSKeyboardTextField" owner:self options:nil];
	for(id obj in top_level)
	{
		if([obj isKindOfClass:[CSKeyboardTextField class]])
		{
			v = (CSKeyboardTextField *) obj;
			[v setup];
            [v retain];
			break;
		}
	}
	return v;
}

- (void)showWithKeyboard {
    // iOS5 check
    if (&UIKeyboardWillChangeFrameNotification != nil) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillChangeFrame:)
                                                     name:UIKeyboardWillChangeFrameNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardDidChangeFrame:)
                                                     name:UIKeyboardDidChangeFrameNotification
                                                   object:nil];
    }
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification
											   object:nil];

    // Make the dummy text field
	mDummyTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
    [self.parentView addSubview:mDummyTextField];
    [mDummyTextField release];
    mDummyTextField.hidden = YES;
    
	// Add dismiss button
	mDismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
	mDismissButton.frame = [self fullScreenFrame];
	mDismissButton.backgroundColor = [UIColor clearColor];
    [mDismissButton addTarget:self action:@selector(dismissButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
	[self.parentView addSubview:mDismissButton];

    // Keyboard setup
    mDummyTextField.returnKeyType = UIReturnKeyDone;
    mDummyTextField.enablesReturnKeyAutomatically = YES;
    mTextField.returnKeyType = UIReturnKeyDone;
    mTextField.enablesReturnKeyAutomatically = YES;

    // Show keyboard
	[mDummyTextField setInputAccessoryView:self];
    // Bring up the keyboard
	[mDummyTextField becomeFirstResponder];
    // Take first responder focus from dummy text field
    [mTextField becomeFirstResponder];    
}

- (BOOL)dismissKeyboard:(BOOL)aDidConfirmInput {
    mDidConfirmInput = aDidConfirmInput;
    
    BOOL isDismissing = NO;
    if ([mDelegate respondsToSelector:@selector(keyboardTextFieldShouldDismiss:)]) {
        if ([mDelegate keyboardTextFieldShouldDismiss:self]) {
            [mTextField resignFirstResponder];
            [mDummyTextField resignFirstResponder];
            isDismissing = YES;
        }
        // else isDismissing = NO
    }
    else {
        // Resign by default
        [mTextField resignFirstResponder];
        [mDummyTextField resignFirstResponder];
        isDismissing = YES;
    }
    
    return isDismissing;
}


#pragma mark - Private
- (KeyboardInfo)keyboardInfoFromDict:(NSDictionary *)kbDict {
    KeyboardInfo ki;

    ki.duration = [[kbDict objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    
    switch ([[kbDict objectForKey:UIKeyboardAnimationCurveUserInfoKey] intValue]) {
		case UIViewAnimationCurveEaseInOut: { ki.curve = UIViewAnimationOptionCurveEaseInOut; break; }
		case UIViewAnimationCurveEaseIn: { ki.curve = UIViewAnimationOptionCurveEaseIn; break; }
		case UIViewAnimationCurveEaseOut: { ki.curve = UIViewAnimationOptionCurveEaseOut; break; }
		case UIViewAnimationCurveLinear: { ki.curve = UIViewAnimationOptionCurveLinear; break; }
		default: { ki.curve = UIViewAnimationOptionCurveEaseInOut; break; }
	}

	ki.startFrame = [[kbDict objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
	ki.endFrame = [[kbDict objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];

    return ki;
}

// Does this frame result in a keyboard dismiss?
// Make sure endFrame is in self.parentView's coordinates (	kbEndFrame = [keyWindow convertRect:kbEndFrame toView:self.parentView]; )
- (BOOL)isEndFrameDismiss:(CGRect)endFrame {
    return (int)(endFrame.origin.y) >= (int)(self.parentView.frame.size.height);
}


#pragma mark - IBAction
- (IBAction)clearPressed {
	mTextField.text = @"";
}

- (IBAction)dismissButtonPressed:(id)sender {
    [self dismissKeyboard:NO];
}


#pragma mark - UITextFieldDelegate
- (BOOL)textFieldShouldReturn:(UITextField *)aTextField {
    return [self dismissKeyboard:YES];
}


#pragma mark - Keyboard Notifications
- (void)keyboardWillHide:(NSNotification *)notification {
    if ([mDelegate conformsToProtocol:@protocol(CSKeyboardTextFieldDelegate)]) {
        [mDelegate keyboardTextFieldWillDismiss:self];
    }
}

- (void)keyboardDidHide:(NSNotification *)notification {
    [mDismissButton removeFromSuperview];
    mDismissButton = nil;
    
    if ([mDelegate conformsToProtocol:@protocol(CSKeyboardTextFieldDelegate)]) {
        [mDelegate keyboardTextFieldDidFinishDismiss:self];
    }
}

#if (__IPHONE_OS_VERSION_MAX_ALLOWED >= 50000)
- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    KeyboardInfo ki = [self keyboardInfoFromDict:[notification userInfo]];
    
	CGRect kbEndFrame = [keyWindow convertRect:ki.endFrame toView:self.parentView];
    NSLog(@"keyboardWillChangeFrame kbEndFrame=%f %f", kbEndFrame.origin.x, kbEndFrame.origin.y);
    
    if ([self isEndFrameDismiss:kbEndFrame]) {
        if ([mDelegate conformsToProtocol:@protocol(CSKeyboardTextFieldDelegate)]) {
            [mDelegate keyboardTextFieldWillDismiss:self];
        }
    }
}

- (void)keyboardDidChangeFrame:(NSNotification *)notification {
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    KeyboardInfo ki = [self keyboardInfoFromDict:[notification userInfo]];
    
	CGRect kbEndFrame = [keyWindow convertRect:ki.endFrame toView:self.parentView];
    NSLog(@"keyboardDidChangeFrame kbEndFrame=%f %f", kbEndFrame.origin.x, kbEndFrame.origin.y);
    
    if ([self isEndFrameDismiss:kbEndFrame]) {
        if ([mDelegate conformsToProtocol:@protocol(CSKeyboardTextFieldDelegate)]) {
            [mDelegate keyboardTextFieldDidFinishDismiss:self];
        }
    }
}

#endif
@end
