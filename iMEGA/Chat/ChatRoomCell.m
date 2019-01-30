#import "ChatRoomCell.h"

#import "DateTools.h"
#import "UIImage+GKContact.h"

#import "MEGAChatListItem.h"
#import "MEGASdkManager.h"
#import "MEGAStore.h"
#import "NSString+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "MEGAReachabilityManager.h"

@interface ChatRoomCell ()

@property (strong, nonatomic) NSTimer *timer;
@property (strong, nonatomic) NSDate *baseDate;
@property (assign, nonatomic) NSInteger initDuration;
@property (strong, nonatomic) NSDate *twoDaysAgo;

@end

@implementation ChatRoomCell

- (void)awakeFromNib {
    [super awakeFromNib];
    
    if (@available(iOS 10.0, *)) {
        self.chatTitle.adjustsFontForContentSizeCategory = YES;
        self.chatLastMessage.adjustsFontForContentSizeCategory = YES;
        self.chatLastTime.adjustsFontForContentSizeCategory = YES;
        self.unreadCount.adjustsFontForContentSizeCategory = YES;
    }
    self.twoDaysAgo = [NSCalendar.currentCalendar dateByAddingUnit:NSCalendarUnitDay value:-2 toDate:NSDate.date options:0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    UIColor *color = self.onlineStatusView.backgroundColor;
    [super setSelected:selected animated:animated];
    
    if (selected){
        self.onlineStatusView.backgroundColor = color;
    }
}

-(void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated{
    UIColor *color = self.onlineStatusView.backgroundColor;
    [super setHighlighted:highlighted animated:animated];
    
    if (highlighted){
        self.onlineStatusView.backgroundColor = color;
    }
}

#pragma mark - Public

- (void)configureCellForArchivedChat {
    self.unreadView.hidden = NO;
    self.unreadView.backgroundColor = UIColor.mnz_gray777777;
    self.unreadView.layer.cornerRadius = 4;
    self.unreadCount.text = AMLocalizedString(@"archived", @"Title of flag of archived chats.").uppercaseString;
    self.unreadCountLabelHorizontalMarginConstraint.constant = 7;
    self.activeCallImageView.hidden = YES;
}

- (void)configureCellForChatListItem:(MEGAChatListItem *)chatListItem {
    
    [self.timer invalidate];

    self.chatTitle.text = chatListItem.title;
    [self updateLastMessageForChatListItem:chatListItem];
    
    if (chatListItem.isGroup) {
        self.onlineStatusView.hidden = YES;
        self.avatarImageView.image = [UIImage imageForName:chatListItem.title.uppercaseString size:self.avatarImageView.frame.size backgroundColor:UIColor.mnz_gray999999 textColor:UIColor.whiteColor font:[UIFont mnz_SFUIRegularWithSize:(self.avatarImageView.frame.size.width/2.0f)]];
    } else {
        [self.avatarImageView mnz_setImageForUserHandle:chatListItem.peerHandle name:chatListItem.title];
        self.onlineStatusView.backgroundColor = [UIColor mnz_colorForStatusChange:[[MEGASdkManager sharedMEGAChatSdk] userOnlineStatus:chatListItem.peerHandle]];
        self.onlineStatusView.hidden = NO;
    }
    
    if (@available(iOS 11.0, *)) {
        self.avatarImageView.accessibilityIgnoresInvertColors = YES;
    }
    
    self.activeCallImageView.hidden = ![[MEGASdkManager sharedMEGAChatSdk] hasCallInChatRoom:chatListItem.chatId] && MEGAReachabilityManager.isReachable;
    
    if ([[MEGASdkManager sharedMEGAChatSdk] hasCallInChatRoom:chatListItem.chatId] && MEGAReachabilityManager.isReachable) {
        MEGAChatCall *call = [[MEGASdkManager sharedMEGAChatSdk] chatCallForChatId:chatListItem.chatId];
        if (call.status == MEGAChatCallStatusUserNoPresent) {
            self.activeCallImageView.hidden = NO;
            self.chatLastTime.hidden = YES;
            self.onCallInfoView.hidden = YES;
            self.chatLastMessage.text = AMLocalizedString(@"Ongoing Call", @"Text to inform the user there is an active call and is not participating");
            self.chatLastTime.font = [[UIFont preferredFontForTextStyle:UIFontTextStyleCaption2] fontWithWeight:UIFontWeightMedium];
        } else {
            self.activeCallImageView.hidden = YES;
            self.chatLastMessage.text = AMLocalizedString(@"Call Started", @"Text to inform the user there is an active call and is participating");
            self.chatLastTime.font = [[UIFont preferredFontForTextStyle:UIFontTextStyleCaption2] fontWithWeight:UIFontWeightMedium];
            self.chatLastTime.textColor = UIColor.mnz_green00BFA5;
            self.chatLastTime.hidden = YES;
            self.onCallInfoView.hidden = NO;
            if (chatListItem.isGroup) {
                self.onCallMicImageView.hidden = [NSUserDefaults.standardUserDefaults boolForKey:@"groupCallLocalAudio"];
                self.onCallVideoImageView.hidden = ![NSUserDefaults.standardUserDefaults boolForKey:@"groupCallLocalVideo"];
            } else {
                self.onCallMicImageView.hidden = ![NSUserDefaults.standardUserDefaults boolForKey:@"oneOnOneCallLocalAudio"];
                self.onCallVideoImageView.hidden = ![NSUserDefaults.standardUserDefaults boolForKey:@"oneOnOneCallLocalVideo"];
            }
            if (!self.timer.valid && call.status == MEGAChatCallStatusInProgress) {
                self.initDuration = call.duration;
                self.baseDate = [NSDate date];
                [self updateDuration];
                self.timer = [NSTimer timerWithTimeInterval:1.0f target:self selector:@selector(updateDuration) userInfo:nil repeats:YES];
                [[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
            }
        }
        self.chatLastMessage.font = [[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1] fontWithWeight:UIFontWeightMedium];
        self.chatLastMessage.textColor = UIColor.mnz_green00BFA5;
    } else {
        self.activeCallImageView.hidden = YES;
        self.onCallInfoView.hidden = YES;
        self.chatLastTime.hidden = NO;
        [self updateUnreadCountChange:chatListItem.unreadCount];
    }
}

- (void)updateDuration {
    //    NSTimeInterval interval = self.initDuration;
    NSTimeInterval interval = ([NSDate date].timeIntervalSince1970 - self.baseDate.timeIntervalSince1970 + self.initDuration);
    self.onCallDuration.text = [NSString mnz_stringFromTimeInterval:interval];
}

- (void)updateUnreadCountChange:(NSInteger)unreadCount {
    self.chatTitle.font = [[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline] fontWithWeight:UIFontWeightMedium];
    self.chatTitle.textColor = UIColor.mnz_black333333;
    
    if (unreadCount != 0) {
        self.chatLastMessage.font = [[UIFont preferredFontForTextStyle:UIFontTextStyleCaption1] fontWithWeight:UIFontWeightMedium];
        self.chatLastMessage.textColor = UIColor.mnz_black333333;
        
        self.chatLastTime.font = [[UIFont preferredFontForTextStyle:UIFontTextStyleCaption2] fontWithWeight:UIFontWeightMedium];
        self.chatLastTime.textColor = UIColor.mnz_green00BFA5;
        
        self.unreadView.hidden = NO;
        self.unreadView.clipsToBounds = YES;
        
        if (unreadCount > 0) {
            self.unreadCount.text = [NSString stringWithFormat:@"%td", unreadCount];
        } else {
            self.unreadCount.text = [NSString stringWithFormat:@"%td+", -unreadCount];
        }
    } else {
        self.chatLastMessage.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption1];
        self.chatLastMessage.textColor = UIColor.mnz_gray666666;
        self.chatLastTime.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
        self.chatLastTime.textColor = UIColor.mnz_gray666666;
        
        self.unreadView.hidden = YES;
        self.unreadCount.text = nil;
    }
}

- (void)updateLastMessageForChatListItem:(MEGAChatListItem *)item {
    switch (item.lastMessageType) {
            
        case 255: {
            self.chatLastMessage.text = AMLocalizedString(@"loading", @"state previous to import a file");
            self.chatLastTime.hidden = YES;
            break;
        }
            
        case MEGAChatMessageTypeInvalid: {
            self.chatLastMessage.text = AMLocalizedString(@"noConversationHistory", @"Information if there are no history messages in current chat conversation");
            self.chatLastTime.hidden = YES;
            break;
        }
            
        case MEGAChatMessageTypeAttachment: {
            NSString *senderString;
            if (item.group) {
                senderString = [self actionAuthorNameInChatListItem:item];
            }
            NSString *lastMessageString = item.lastMessage;
            NSArray *componentsArray = [lastMessageString componentsSeparatedByString:@"\x01"];
            if (componentsArray.count == 1) {
                NSString *attachedFileString = AMLocalizedString(@"attachedFile", @"A message appearing in the chat summary window when the most recent action performed by a user was attaching a file. Please keep %s as it will be replaced at runtime with the name of the attached file.");
                lastMessageString = [attachedFileString stringByReplacingOccurrencesOfString:@"%s" withString:lastMessageString];
            } else {
                lastMessageString = AMLocalizedString(@"attachedXFiles", @"A summary message when a user has attached many files at once into the chat. Please keep %s as it will be replaced at runtime with the number of files.");
                lastMessageString = [lastMessageString stringByReplacingOccurrencesOfString:@"%s" withString:[NSString stringWithFormat:@"%tu", componentsArray.count]];
            }
            self.chatLastMessage.text = senderString ? [NSString stringWithFormat:@"%@: %@",senderString, lastMessageString] : lastMessageString;
            break;
        }
            
        case MEGAChatMessageTypeContact: {
            NSString *senderString;
            if (item.group) {
                senderString = [self actionAuthorNameInChatListItem:item];
            }
            NSString *lastMessageString = item.lastMessage;
            NSArray *componentsArray = [lastMessageString componentsSeparatedByString:@"\x01"];
            if (componentsArray.count == 1) {
                NSString *sentContactString = AMLocalizedString(@"sentContact", @"A summary message when a user sent the information of %s number of contacts at once. Please keep %s as it will be replaced at runtime with the number of contacts sent.");
                lastMessageString = [sentContactString stringByReplacingOccurrencesOfString:@"%s" withString:lastMessageString];
            } else {
                lastMessageString = AMLocalizedString(@"sentXContacts", @"A summary message when a user sent the information of %s number of contacts at once. Please keep %s as it will be replaced at runtime with the number of contacts sent.");
                lastMessageString = [lastMessageString stringByReplacingOccurrencesOfString:@"%s" withString:[NSString stringWithFormat:@"%tu", componentsArray.count]];
            }
            self.chatLastMessage.text = senderString ? [NSString stringWithFormat:@"%@: %@",senderString, lastMessageString] : lastMessageString;
            break;
        }
            
        case MEGAChatMessageTypeTruncate: {
            NSString *senderString = [self actionAuthorNameInChatListItem:item];
            NSString *lastMessageString = AMLocalizedString(@"clearedTheChatHistory", @"A log message in the chat conversation to tell the reader that a participant [A] cleared the history of the chat. For example, Alice cleared the chat history.");
            lastMessageString = [lastMessageString stringByReplacingOccurrencesOfString:@"[A]" withString:senderString];
            self.chatLastMessage.text = lastMessageString;
            break;
        }
            
        case MEGAChatMessageTypePrivilegeChange: {
            NSString *fullNameDidAction = [self actionAuthorNameInChatListItem:item];
            MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:item.chatId];
            NSString *fullNameReceiveAction = [chatRoom peerFullnameByHandle:item.lastMessageHandle];
            
            if (fullNameReceiveAction.length == 0) {
                MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:item.lastMessageHandle];
                if (moUser) {
                    fullNameReceiveAction = moUser.fullName;
                } else {
                    fullNameReceiveAction = @"";
                }
            }
            
            NSString *wasChangedToBy = AMLocalizedString(@"wasChangedToBy", @"A log message in a chat to display that a participant's permission was changed and by whom. This message begins with the user's name who receive the permission change [A]. [B] will be replaced with the permission name (such as Moderator or Read-only) and [C] will be replaced with the person who did it. Please keep the [A], [B] and [C] placeholders, they will be replaced at runtime. For example: Alice Jones was changed to Moderator by John Smith.");
            wasChangedToBy = [wasChangedToBy stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameReceiveAction];
            NSString *privilige;
            switch (item.lastMessagePriv) {
                case 0:
                    privilige = AMLocalizedString(@"readOnly", @"Permissions given to the user you share your folder with");
                    break;
                    
                case 2:
                    privilige = AMLocalizedString(@"standard", @"The Standard permission level in chat. With the standard permissions a participant can read and type messages in a chat.");
                    break;
                    
                case 3:
                    privilige = AMLocalizedString(@"moderator", @"The Moderator permission level in chat. With moderator permissions a participant can manage the chat");
                    break;
                    
                default:
                    break;
            }
            wasChangedToBy = [wasChangedToBy stringByReplacingOccurrencesOfString:@"[B]" withString:privilige];
            wasChangedToBy = [wasChangedToBy stringByReplacingOccurrencesOfString:@"[C]" withString:fullNameDidAction];
            self.chatLastMessage.text = wasChangedToBy;
            break;
        }
            
        case MEGAChatMessageTypeAlterParticipants: {
            NSString *fullNameDidAction = [self actionAuthorNameInChatListItem:item];
            MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:item.chatId];
            NSString *fullNameReceiveAction = [chatRoom peerFullnameByHandle:item.lastMessageHandle];
            
            if (fullNameReceiveAction.length == 0) {
                MOUser *moUser = [[MEGAStore shareInstance] fetchUserWithUserHandle:item.lastMessageHandle];
                if (moUser) {
                    fullNameReceiveAction = moUser.fullName;
                } else {
                    fullNameReceiveAction = @"";
                }
            }
            
            switch (item.lastMessagePriv) {
                case -1: {
                    if (fullNameDidAction && ![fullNameReceiveAction isEqualToString:fullNameDidAction]) {
                        NSString *wasRemovedFromTheGroupChatBy = AMLocalizedString(@"wasRemovedFromTheGroupChatBy", @"A log message in a chat conversation to tell the reader that a participant [A] was removed from the group chat by the moderator [B]. Please keep [A] and [B], they will be replaced by the participant and the moderator names at runtime. For example: Alice was removed from the group chat by Frank.");
                        wasRemovedFromTheGroupChatBy = [wasRemovedFromTheGroupChatBy stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameReceiveAction];
                        wasRemovedFromTheGroupChatBy = [wasRemovedFromTheGroupChatBy stringByReplacingOccurrencesOfString:@"[B]" withString:fullNameDidAction];
                        self.chatLastMessage.text = wasRemovedFromTheGroupChatBy;
                    } else {
                        NSString *leftTheGroupChat = AMLocalizedString(@"leftTheGroupChat", @"A log message in the chat conversation to tell the reader that a participant [A] left the group chat. For example: Alice left the group chat.");
                        leftTheGroupChat = [leftTheGroupChat stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameReceiveAction];
                        self.chatLastMessage.text = leftTheGroupChat;
                    }
                    break;
                }
                    
                case -2: {
                    NSString *joinedTheGroupChatByInvitationFrom = AMLocalizedString(@"joinedTheGroupChatByInvitationFrom", @"A log message in a chat conversation to tell the reader that a participant [A] was added to the chat by a moderator [B]. Please keep the [A] and [B] placeholders, they will be replaced by the participant and the moderator names at runtime. For example: Alice joined the group chat by invitation from Frank.");
                    joinedTheGroupChatByInvitationFrom = [joinedTheGroupChatByInvitationFrom stringByReplacingOccurrencesOfString:@"[A]" withString:fullNameReceiveAction];
                    joinedTheGroupChatByInvitationFrom = [joinedTheGroupChatByInvitationFrom stringByReplacingOccurrencesOfString:@"[B]" withString:fullNameDidAction];
                    self.chatLastMessage.text = joinedTheGroupChatByInvitationFrom;
                    break;
                }
                    
                default:
                    break;
            }
            self.chatLastTime.hidden = NO;
            self.chatLastTime.text = [item.lastMessageDate compare:self.twoDaysAgo] == NSOrderedDescending ? item.lastMessageDate.timeAgoSinceNow : item.lastMessageDate.shortTimeAgoSinceNow;
            break;
        }
            
        case MEGAChatMessageTypeChatTitle: {
            NSString *senderString = [self actionAuthorNameInChatListItem:item];
            NSString *changedGroupChatNameTo = AMLocalizedString(@"changedGroupChatNameTo", @"A hint message in a group chat to indicate the group chat name is changed to a new one. Please keep %s when translating this string which will be replaced with the name at runtime.");
            changedGroupChatNameTo = [changedGroupChatNameTo stringByReplacingOccurrencesOfString:@"[A]" withString:senderString];
            changedGroupChatNameTo = [changedGroupChatNameTo stringByReplacingOccurrencesOfString:@"[B]" withString:(item.lastMessage ? item.lastMessage : @" ")];
            self.chatLastMessage.text = changedGroupChatNameTo;
            break;
        }
            
        case MEGAChatMessageTypeCallEnded: {
            char SOH = 0x01;
            NSString *separator = [NSString stringWithFormat:@"%c", SOH];
            NSArray *array = [item.lastMessage componentsSeparatedByString:separator];
            NSInteger duration = [[array objectAtIndex:0] integerValue];
            MEGAChatMessageEndCallReason endCallReason = [[array objectAtIndex:1] integerValue];
            NSString *lastMessage = [NSString mnz_stringByEndCallReason:endCallReason userHandle:item.lastMessageSender duration:duration];
            self.chatLastMessage.text = lastMessage;
            break;
        }
            
        default: {
            NSString *senderString;
            if (item.group && item.lastMessageSender != [[MEGASdkManager sharedMEGAChatSdk] myUserHandle]) {
                senderString = [self actionAuthorNameInChatListItem:item];
            }
            self.chatLastMessage.text = senderString ? [NSString stringWithFormat:@"%@: %@",senderString, item.lastMessage] : item.lastMessage;
            break;
        }
    }
    self.chatLastTime.hidden = NO;
    self.chatLastTime.text = [item.lastMessageDate compare:self.twoDaysAgo] == NSOrderedDescending ? item.lastMessageDate.timeAgoSinceNow : item.lastMessageDate.shortTimeAgoSinceNow;
}

- (NSString *)actionAuthorNameInChatListItem:(MEGAChatListItem *)item {
    NSString *actionAuthor;
    if (item.lastMessageSender == [[MEGASdkManager sharedMEGAChatSdk] myUserHandle]) {
        actionAuthor = [[MEGASdkManager sharedMEGAChatSdk] myFullname];
    } else {
        MEGAChatRoom *chatRoom = [[MEGASdkManager sharedMEGAChatSdk] chatRoomForChatId:item.chatId];
        actionAuthor = [chatRoom peerFullnameByHandle:item.lastMessageSender];
    }
    
    if (!actionAuthor) {
        actionAuthor = [[[MEGAStore shareInstance] fetchUserWithUserHandle:item.lastMessageSender] fullName];
    }
    
    return actionAuthor ? actionAuthor : @"?";
}

@end
