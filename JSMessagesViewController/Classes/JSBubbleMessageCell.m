//
//  Created by Jesse Squires
//  http://www.hexedbits.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSMessagesViewController
//
//
//  The MIT License
//  Copyright (c) 2013 Jesse Squires
//  http://opensource.org/licenses/MIT
//

#import "JSBubbleMessageCell.h"

#import "JSAvatarImageFactory.h"
#import "UIColor+JSMessagesView.h"

static const CGFloat kJSLabelPadding = 5.0f;
static const CGFloat kJSSubtitleLabelHeight = 15.0f;


@interface JSBubbleMessageCell()

- (void)setup;
- (void)configureTimestampLabel;
- (void)configureAvatarImageView:(UIImageView *)imageView forMessageType:(JSBubbleMessageType)type;
- (void)configureSubtitleLabelForMessageType:(JSBubbleMessageType)type;

- (void)configureWithType:(JSBubbleMessageType)type
          bubbleImageView:(UIImageView *)bubbleImageView
                  message:(id<JSMessageData>)message
        displaysTimestamp:(BOOL)displaysTimestamp
                   avatar:(BOOL)hasAvatar;

- (void)setText:(NSString *)text;
- (void)setTimestamp:(NSDate *)date;
- (void)setSubtitle:(NSString *)subtitle;

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)longPress;

- (void)handleMenuWillHideNotification:(NSNotification *)notification;
- (void)handleMenuWillShowNotification:(NSNotification *)notification;

@property (nonatomic, assign) BOOL mustForceLayout;
@property (nonatomic, assign) CGSize calculatedSize;

@end



@implementation JSBubbleMessageCell

@synthesize message = _message;
@synthesize timeStampFont = _timeStampFont;

#pragma mark - Setup

- (void)setup
{
    self.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.accessoryType = UITableViewCellAccessoryNone;
    self.accessoryView = nil;
    
    self.imageView.image = nil;
    self.imageView.hidden = YES;
    self.textLabel.text = nil;
    self.textLabel.hidden = YES;
    self.detailTextLabel.text = nil;
    self.detailTextLabel.hidden = YES;
    
    UILongPressGestureRecognizer *recognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                             action:@selector(handleLongPressGesture:)];
    [recognizer setMinimumPressDuration:0.4f];
    [self addGestureRecognizer:recognizer];
}

- (void)configureTimestampLabel
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(kJSLabelPadding,
                                                               kJSLabelPadding,
                                                               self.contentView.frame.size.width - (kJSLabelPadding * 2.0f),
                                                               40.0f)];
    label.autoresizingMask =  UIViewAutoresizingFlexibleWidth;
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = [UIColor js_messagesTimestampColorClassic];
    label.shadowColor = [UIColor whiteColor];
    label.shadowOffset = CGSizeMake(0.0f, 1.0f);
    label.font = self.timeStampFont;
    
    [self.contentView addSubview:label];
    [self.contentView bringSubviewToFront:label];
    _timestampLabel = label;
}

- (void)configureAvatarImageView:(UIImageView *)imageView forMessageType:(JSBubbleMessageType)type
{
    imageView.frame = CGRectMake(0.0f, 0.0f, kJSAvatarImageSize, kJSAvatarImageSize);
    imageView.autoresizingMask = (UIViewAutoresizingFlexibleTopMargin
                                         | UIViewAutoresizingFlexibleLeftMargin
                                         | UIViewAutoresizingFlexibleRightMargin);
    
    [self.contentView addSubview:imageView];
    _avatarImageView = imageView;
}

- (void)configureSubtitleLabelForMessageType:(JSBubbleMessageType)type
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    label.backgroundColor = [UIColor clearColor];
    label.textAlignment = (type == JSBubbleMessageTypeOutgoing) ? NSTextAlignmentRight : NSTextAlignmentLeft;
    label.textColor = [UIColor js_messagesTimestampColorClassic];
    label.font = [UIFont systemFontOfSize:12.5f];
    
    [self.contentView addSubview:label];
    _subtitleLabel = label;
}

- (void)configureWithType:(JSBubbleMessageType)type
          bubbleImageView:(UIImageView *)bubbleImageView
                  message:(id<JSMessageData>)message
         displaysTimestamp:(BOOL)displaysTimestamp
                   avatar:(BOOL)hasAvatar
{
    self.displaysTimestamp = displaysTimestamp;
    self.hasAvatar = hasAvatar;
    
    JSBubbleView *bubbleView = [[JSBubbleView alloc] initWithFrame:self.contentView.bounds
                                                        bubbleType:type
                                                   bubbleImageView:bubbleImageView];
    [self.contentView addSubview:bubbleView];
    [self.contentView sendSubviewToBack:bubbleView];
    _bubbleView = bubbleView;
}

#pragma mark - Initialization

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithBubbleType:(JSBubbleMessageType)type
                   bubbleImageView:(UIImageView *)bubbleImageView
                           message:(id<JSMessageData>)message
                 displaysTimestamp:(BOOL)displaysTimestamp
                         hasAvatar:(BOOL)hasAvatar
                   reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    if (self) {
        [self configureWithType:type
                bubbleImageView:bubbleImageView
                        message:message
              displaysTimestamp:displaysTimestamp
                         avatar:hasAvatar];
    }
    return self;
}

- (void)dealloc
{
    _bubbleView = nil;
    _timestampLabel = nil;
    _avatarImageView = nil;
    _subtitleLabel = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - TableViewCell

- (void)prepareForReuse
{
    [super prepareForReuse];
}

- (void)setBackgroundColor:(UIColor *)color
{
    [super setBackgroundColor:color];
    [self.contentView setBackgroundColor:color];
    [self.bubbleView setBackgroundColor:color];
}

#pragma mark - Setters

- (id<JSMessageData>)message;
{
    return _message;
}

- (void)setMessage:(id<JSMessageData>)message
{
    if (_message!=message) {
        _message = message;
        
        // Message
        self.bubbleView.textView.text = [message text];
        
        // Timestamp
        if (self.displaysTimestamp) {
            if (!self.timestampLabel) {
                [self configureTimestampLabel];
            }
            self.timestampLabel.text = [NSDateFormatter localizedStringFromDate:[message date]
                                                                      dateStyle:NSDateFormatterMediumStyle
                                                                      timeStyle:NSDateFormatterShortStyle];
        } else {
            if (self.timestampLabel) {
                [self.timestampLabel removeFromSuperview];
                _timestampLabel = nil;
            }
        }
        
        // Subtitle
        NSString *subtitle = [message sender];
        if (subtitle.length>0) {
            if (!self.subtitleLabel) {
                [self configureSubtitleLabelForMessageType:self.messageType];
            }
            self.subtitleLabel.text = subtitle;
        } else {
            [self.subtitleLabel removeFromSuperview];
            _subtitleLabel = nil;
        }
        
        // Layout
        [self setNeedsLayout];
        self.mustForceLayout = YES;
    }
}

- (void)setAvatarImageView:(UIImageView *)imageView
{
    [_avatarImageView removeFromSuperview];
    _avatarImageView = nil;
    
    [self configureAvatarImageView:imageView forMessageType:[self messageType]];
}

- (void)setTimeStampFont:(UIFont *)timeStampFont;
{
    _timeStampFont = timeStampFont;
}

#pragma mark - Getters

- (JSBubbleMessageType)messageType
{
    return _bubbleView.type;
}

- (UIFont *)timeStampFont;
{
    if (!_timeStampFont) {
        _timeStampFont = [[[self class] appearance] timeStampFont];
    }
    if (_timeStampFont) {
        return _timeStampFont;
    } else {
        return  [UIFont boldSystemFontOfSize:12.0f];
    }
}

#pragma mark - Measurement

+ (CGFloat)maxWidth;
{
    CGFloat maxWidth = [UIScreen mainScreen].applicationFrame.size.width * 0.70f; // TODO: use constant?
    return maxWidth;
}

- (CGSize)sizeThatFits:(CGSize)size;
{
    size.width = [[self class] maxWidth];
    if (self.mustForceLayout) {
        [self layoutSubviews];
    } else {
        [self layoutIfNeeded];
    }
    
    return self.calculatedSize;
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGRect rect = CGRectZero;
    
    CGFloat subtitleY = 0.0f;
    CGFloat bubbleY = 0.0f;
    CGFloat bubbleX = 0.0f;
    CGSize avatarSize = CGSizeMake(kJSAvatarImageSize, kJSAvatarImageSize);
    CGFloat maxWidth = [[self class] maxWidth];
    CGFloat maxBubbleWidth = maxWidth - avatarSize.width;
    CGSize bubbleSize = [self.bubbleView sizeThatFits:CGSizeMake(maxBubbleWidth, MAXFLOAT)];;
    
    // Margins
    CGFloat marginAboveTimestamp = CC_IDIOM_IPHONE ? 6.0f : 8.0f;
    CGFloat marginBetweenTimestampAndBubble = CC_IDIOM_IPHONE ? 4.0f : 12.0f;
    CGFloat bottomMargin = CC_IDIOM_IPHONE ? 4.0f : 12.0f;
    
    // Timestamp
    if (self.displaysTimestamp) {
        rect = self.timestampLabel.frame;
        rect.origin.y = marginAboveTimestamp;
        rect.origin.x = 0.0f;
        rect.size.width = self.contentView.bounds.size.width;
        rect.size.height = [self.timestampLabel sizeThatFits:CGSizeMake(rect.size.width, 200.0f)].height;
        self.timestampLabel.frame = rect;
        bubbleY = CGRectGetMaxY(rect) + marginBetweenTimestampAndBubble;
    }

    // Avatar view
    CGRect avatarFrame = CGRectZero;
    if (self.hasAvatar || self.avatarImageView.image!=nil) {
        rect = self.avatarImageView.frame;
        rect.size = avatarSize;
        if (bubbleY+bubbleSize.height<avatarSize.height+bubbleY) {
            bubbleY += avatarSize.height - bubbleSize.height;
            rect.origin.y = bubbleY;
        } else {
            rect.origin.y = bubbleY + bubbleSize.height - rect.size.height;
        }
        if (self.messageType==JSBubbleMessageTypeOutgoing) {
            rect.origin.x = self.bounds.size.width - rect.size.width;
            bubbleX = rect.origin.x - bubbleSize.width;
        } else {
            rect.origin.x = 0.0f;
            bubbleX = CGRectGetMaxX(rect);
        }
        self.avatarImageView.frame = rect;
        avatarFrame = rect;
        subtitleY = CGRectGetMaxY(rect);
    } else {
        subtitleY = bubbleY + bubbleSize.height;
        if (self.messageType==JSBubbleMessageTypeOutgoing) {
            bubbleX = self.bounds.size.width - bubbleSize.width;
        } else {
            bubbleX = 0.0f;
        }
    }
    
    // Bubble
    rect = self.bubbleView.frame;
    rect.size = bubbleSize;
    rect.origin.x = bubbleX;
    rect.origin.y = bubbleY;
    self.bubbleView.frame = rect;

    // Subtitle
    if (self.subtitleLabel) {
        rect = self.subtitleLabel.frame;
        rect.origin.y = subtitleY;
        rect.origin.x = 0.0f;
        rect.size.width = self.bounds.size.width;
        rect.size.height = [self.subtitleLabel sizeThatFits:CGSizeMake(rect.size.width, 200.0f)].height;
        self.subtitleLabel.frame = rect;
    }

    self.mustForceLayout = NO;

    // Calculate total size
    CGFloat height = CGRectGetMaxY(rect); // Subtitle or Bubble
    if (self.hasAvatar) {
        height = MAX(CGRectGetMaxY(avatarFrame), height);
    }
    height += bottomMargin;
    CGFloat width = avatarSize.width + self.bubbleView.frame.size.width;
    
    self.calculatedSize = CGSizeMake(width, height);
}

#pragma mark - Copying

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    return [super becomeFirstResponder];
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    return (action == @selector(copy:));
}

- (void)copy:(id)sender
{
    [[UIPasteboard generalPasteboard] setString:self.bubbleView.textView.text];
    [self resignFirstResponder];
}

#pragma mark - Gestures

- (void)handleLongPressGesture:(UILongPressGestureRecognizer *)longPress
{
    if (longPress.state != UIGestureRecognizerStateBegan || ![self becomeFirstResponder])
        return;
    
    UIMenuController *menu = [UIMenuController sharedMenuController];
    CGRect targetRect = [self convertRect:[self.bubbleView bubbleFrame]
                                 fromView:self.bubbleView];
    
    [menu setTargetRect:CGRectInset(targetRect, 0.0f, 4.0f) inView:self];
    
    self.bubbleView.bubbleImageView.highlighted = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMenuWillShowNotification:)
                                                 name:UIMenuControllerWillShowMenuNotification
                                               object:nil];
    [menu setMenuVisible:YES animated:YES];
}

#pragma mark - Notifications

- (void)handleMenuWillHideNotification:(NSNotification *)notification
{
    self.bubbleView.bubbleImageView.highlighted = NO;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIMenuControllerWillHideMenuNotification
                                                  object:nil];
}

- (void)handleMenuWillShowNotification:(NSNotification *)notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIMenuControllerWillShowMenuNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleMenuWillHideNotification:)
                                                 name:UIMenuControllerWillHideMenuNotification
                                               object:nil];
}

@end