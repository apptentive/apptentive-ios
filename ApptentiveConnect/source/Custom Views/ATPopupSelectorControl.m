//
//  ATPopupSelectorControl.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 4/4/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATPopupSelectorControl.h"
#import "ATBackend.h"
#import <QuartzCore/QuartzCore.h>

#define kSelectionBackgroundImageTag 32
#define kSelectionImageTag 33

#define kPopupBackgroundImageTag 34

#define kSelectionChangedNotification @"ATPopupSelectionChanged"
#define kSelectionPopupDisappearedNotification @"ATPopupDisappeared"

@interface ATPopupSelectorControl ()
- (void)touchUpInside:(id)sender;
- (void)setup;
- (void)teardown;
@end

@interface ATPopupSelection ()
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) UIImage *popupImage;
@property (nonatomic, retain) UIImage *selectedImage;
@end

@interface ATPopupSelectorPopup : UIView <UIGestureRecognizerDelegate> {
@private
    NSArray *selections;
    UIView *targetView;
    UIGestureRecognizer *tapRecognizer;
}
- (id)initWithSelections:(NSArray *)selections pointingAtView:(UIView *)viewTarget;
- (void)setup;
- (void)show;
- (void)hide;
@end

@interface ATPopupSelectionControl : UIControl {
@private
}
@property (nonatomic, assign) ATPopupSelection *selection;
- (id)initWithFrame:(CGRect)frame selection:(ATPopupSelection *)newSelection;
@end

@implementation ATPopupSelectionControl
@synthesize selection;
- (id)initWithFrame:(CGRect)frame selection:(ATPopupSelection *)newSelection {
    if ((self = [super initWithFrame:frame])) {
        self.selection = newSelection;
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];
        [self setNeedsLayout];
    }
    return self;
}

- (void)dealloc {
    self.selection = nil;
    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIImageView *imageView = (UIImageView *)[self viewWithTag:1];
    if (!imageView) {
        imageView = [[UIImageView alloc] initWithImage:self.selection.popupImage];
        imageView.tag = 1;
        [self addSubview:imageView];
        [imageView release];
        imageView = nil;
    }
    
    UIImageView *bgView = (UIImageView *)[self viewWithTag:2];
    if (self.selection.isSelected) {
        if (!bgView) {
            UIImage *bg = [ATBackend imageNamed:@"at_bubble_selection_bg"];
            bgView = [[UIImageView alloc] initWithImage:bg];
            bgView.tag = 2;
            [self addSubview:bgView];
            [self sendSubviewToBack:bgView];
            [bgView release];
            bgView = nil;
        }
    } else if (bgView) {
        [bgView removeFromSuperview];
    }
}
@end

@implementation ATPopupSelectorControl
@synthesize selections;
- (id)initWithSelections:(NSArray *)someSelections {
    if ((self = [super initWithFrame:CGRectMake(0.0, 0.0, 32.0, 36.0)])) {
        self.selections = someSelections;
        [self setup];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setup];
}

- (void)dealloc {
    [self teardown];
    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
    ATPopupSelection *current = [self currentSelection];
    UIImageView *backgroundView = (UIImageView *)[self viewWithTag:kSelectionBackgroundImageTag];
    UIImageView *imageView = (UIImageView *)[self viewWithTag:kSelectionImageTag];
    if (!current) return;
    
    if (!backgroundView) {
        backgroundView = [[UIImageView alloc] initWithImage:[ATBackend imageNamed:@"at_selection_bg"]];
        backgroundView.tag = kSelectionBackgroundImageTag;
        [self addSubview:backgroundView];
        [backgroundView release];
    }
    
    if (!imageView) {
        imageView = [[UIImageView alloc] initWithImage:current.selectedImage];
        imageView.tag = kSelectionImageTag;
        [self addSubview:imageView];
        CGRect f = imageView.frame;
        f.origin.x = 1.0;
        imageView.frame = f;
        [imageView release];
    } else {
        imageView.image = current.selectedImage;
    }
}

- (ATPopupSelection *)currentSelection {
    ATPopupSelection *result = nil;
    for (ATPopupSelection *selection in selections) {
        if (selection.isSelected) {
            result = selection;
            break;
        }
    }
    return result;
}

- (void)touchUpInside:(id)sender {
    if (!popup) {
        popup = [[ATPopupSelectorPopup alloc] initWithSelections:selections pointingAtView:self];
        [popup show];
    } else {
        [popup hide];
        [popup release];
        popup = nil;
    }
    NSLog(@"Ayoooo, I'm Galileo!");
}

- (void)selectionChangedNotification:(NSNotification *)notification {
    [self setNeedsLayout];
}

- (void)selectionDisappearedNotification:(NSNotification *)notification {
    if (popup) {
        [popup release];
        popup = nil;
    }
    [self setNeedsLayout];
}

- (void)setup {
    [self addTarget:self action:@selector(touchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectionChangedNotification:) name:kSelectionChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectionDisappearedNotification:) name:kSelectionPopupDisappearedNotification object:nil];
    
}

- (void)teardown {
    self.selections = nil;
    if (popup) {
        [popup hide];
        [popup release];
        popup = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setSelections:(NSArray *)newSelections {
    if (selections != newSelections) {
        [selections release];
        selections = nil;
        selections = [newSelections retain];
        [self setNeedsLayout];
    }
}
@end


@implementation ATPopupSelection
@synthesize name, popupImage, selectedImage, isSelected=selected;
- (id)initWithName:(NSString *)aName popupImage:(UIImage *)aPopupImage selectedImage:(UIImage *)aSelectedImage {
    if ((self = [super init])) {
        self.name = aName;
        self.popupImage = aPopupImage;
        self.selectedImage = aSelectedImage;
    }
    return self;
}

- (void)dealloc {
    self.name = nil;
    self.popupImage = nil;
    self.selectedImage = nil;
    [super dealloc];
}
@end


@implementation ATPopupSelectorPopup
- (id)initWithSelections:(NSArray *)someSelections pointingAtView:(UIView *)viewTarget {
    if ((self = [super initWithFrame:CGRectZero])) {
        selections = [someSelections retain];
        targetView = [viewTarget retain];
        [self setup];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeGestureRecognizer:tapRecognizer];
    [tapRecognizer release];
    tapRecognizer = nil;
    [selections release];
    selections = nil;
    [targetView release];
    targetView = nil;
    [super dealloc];
}

- (void)show {
    UIWindow *w = [targetView window];
    [w addSubview:self];
    [w bringSubviewToFront:self];
}

- (void)hide {
    self.alpha = 1.0;
    [UIView beginAnimations:@"hide" context:NULL];
    [UIView setAnimationDelegate:self];
    self.alpha = 0.0;
    [UIView commitAnimations];
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if (animationID) {
        if ([animationID isEqualToString:@"hide"]) {
            [self removeFromSuperview];
            [[NSNotificationCenter defaultCenter] postNotificationName:kSelectionPopupDisappearedNotification object:self];
        }
    }
}

- (void)setup {
    NSArray *notificationNames = [NSArray arrayWithObjects:UITextFieldTextDidChangeNotification, UITextViewTextDidChangeNotification, UIKeyboardWillHideNotification, UIKeyboardWillShowNotification, nil];
    
    for (NSString *notificationName in notificationNames) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outsideEventNotification:) name:notificationName object:nil];
    }
    
    tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    [tapRecognizer setDelegate:self];
    [self addGestureRecognizer:tapRecognizer];
    tapRecognizer.cancelsTouchesInView = NO;
    
    [self layoutSubviews];
    [self show];
}

- (void)layoutSubviews {
    static CGFloat viewHeight;
    [super layoutSubviews];
    
    // Basic idea: view covers entire window, placard points at target view
    // from right hand side.
    
    // Cover window with view.
    CGRect viewFrame = targetView.window.bounds;
    self.frame = viewFrame;
    self.bounds = viewFrame;
    
    // Create the placard.
    CGFloat iconWidth = 30.0;
    CGFloat padding = 2.0;
    CGFloat leftOffsetX = 8.0;
    CGFloat rightOffsetX = 4.0;
    CGFloat topOffsetY = 0.0;
    
    CGFloat selectionBoxCenterAdjustmentY = 2.0;
    
    CGFloat width = leftOffsetX + rightOffsetX + iconWidth * [selections count] + padding * ([selections count] - 1);
    
    UIImageView *popupBackground = (UIImageView *)[self viewWithTag:kPopupBackgroundImageTag];
    if (!popupBackground) {
        UIImage *bg = [ATBackend imageNamed:@"at_placard_bg"];
        bg = [bg stretchableImageWithLeftCapWidth:10.0 topCapHeight:4.0];
        popupBackground = [[UIImageView alloc] initWithImage:bg];
        popupBackground.tag = kPopupBackgroundImageTag;
        viewHeight = bg.size.height;
        [self addSubview:popupBackground];
        [popupBackground setUserInteractionEnabled:YES];
        
        
        
        CABasicAnimation *wiggleAnimation = [[CABasicAnimation animationWithKeyPath:@"transform"] retain];
		wiggleAnimation.duration = 0.1;
		wiggleAnimation.repeatCount = 1.0;//1e100f;
		wiggleAnimation.autoreverses = YES;
		wiggleAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DConcat(CATransform3DIdentity, CATransform3DScale(self.layer.transform, 1.1, 1.1, 1.0))];
        
        NSUInteger i = 0;
        for (ATPopupSelection *sel in selections) {
            CGFloat offsetX = leftOffsetX + i*iconWidth + i*padding;
            ATPopupSelectionControl *c = [[ATPopupSelectionControl alloc] initWithFrame:CGRectMake(offsetX, topOffsetY, iconWidth, 32.0) selection:sel];
            UIImageView *v = [[UIImageView alloc] initWithImage:sel.popupImage];
            [c addSubview:v];
            [c addTarget:self action:@selector(didTapSelection:) forControlEvents:UIControlEventTouchUpInside];
            [popupBackground addSubview:c];
            
            c.layer.transform = CATransform3DScale(CATransform3DIdentity, 0.2, 0.2, 1.0);
            c.alpha = 0.0;
            
            [c.layer removeAnimationForKey:@"wiggle"];
            [c.layer addAnimation:wiggleAnimation forKey:@"wiggle"];
            
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDelay:i * 0.05];
            [UIView setAnimationDuration:0.05];
            c.alpha = 1.0;
            c.layer.transform = CATransform3DIdentity;
            [UIView commitAnimations];
            
            [c release];
            [v release];
            i++;
        }
        
        [wiggleAnimation release];
        wiggleAnimation = nil;
    } else {
        for (UIView *v in [popupBackground subviews]) {
            [v layoutSubviews];
        }
    }
    
    // Get the place we should point the placard at.
    CGPoint targetCenter = targetView.center;
    CGPoint targetRightCenter = CGPointMake(targetView.frame.origin.x + targetView.frame.size.width, targetCenter.y);
    CGPoint targetRightCenterInSelf = [targetView.superview convertPoint:targetRightCenter toView:self];
    CGPoint popupOffsetInSelf = CGPointMake(targetRightCenterInSelf.x, targetRightCenterInSelf.y - floorf(viewHeight/2.0) + selectionBoxCenterAdjustmentY);
    
    CGRect popupFrame = CGRectMake(popupOffsetInSelf.x, popupOffsetInSelf.y, width, viewHeight);
    popupBackground.frame = popupFrame;
    popupBackground.bounds = CGRectMake(0.0, 0.0, width, viewHeight);
    
    
    self.backgroundColor = [UIColor clearColor];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"hayooo");
}

- (void)didTap:(id)sender {
    // Ensure we didn't hit one of the subviews.
    CGPoint location = [tapRecognizer locationInView:self];
    UIView *subview = [self hitTest:location withEvent:nil];
    if ([subview isEqual:self]) {
        NSLog(@"in subview %@", subview);
        [self hide];
    }
}

- (void)didTapSelection:(id)sender {
    ATPopupSelectionControl *control = (ATPopupSelectionControl *)sender;
    for (ATPopupSelection *sel in selections) {
        if (![sel.name isEqualToString:control.selection.name]) {
            sel.isSelected = NO;
        } else {
            sel.isSelected = YES;
        }
    }
    [self layoutSubviews];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSelectionChangedNotification object:self];
    [self hide];
}

- (void)outsideEventNotification:(NSNotification *)notification {
    [self hide];
}
@end
