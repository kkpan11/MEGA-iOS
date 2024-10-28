#import "FolderLinkViewController.h"

#import "SVProgressHUD.h"
#import "SAMKeychain.h"
#import "UIScrollView+EmptyDataSet.h"

#import "DisplayMode.h"
#import "Helper.h"
#import "MEGANavigationController.h"
#import "MEGANode+MNZCategory.h"
#import "MEGANodeList+MNZCategory.h"
#import "MEGAPhotoBrowserViewController.h"
#import "MEGAReachabilityManager.h"
#import "MEGA-Swift.h"

#import "NSString+MNZCategory.h"
#import "MEGALinkManager.h"
#import "UIApplication+MNZCategory.h"
#import "UIImageView+MNZCategory.h"
#import "UITextField+MNZCategory.h"

#import "BrowserViewController.h"
#import "EmptyStateView.h"
#import "NodeTableViewCell.h"
#import "MainTabBarController.h"
#import "OnboardingViewController.h"
#import "LoginViewController.h"
#import "LinkOption.h"
#import "SendToViewController.h"
#import "UnavailableLinkView.h"
@import MEGADomain;
@import MEGAL10nObjc;
@import MEGAUIKit;
@import MEGASDKRepo;

@interface FolderLinkViewController () <UISearchBarDelegate, UISearchResultsUpdating, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, MEGAGlobalDelegate, MEGARequestDelegate, UISearchControllerDelegate, AudioPlayerPresenterProtocol>

@property (nonatomic, getter=isLoginDone) BOOL loginDone;
@property (nonatomic, getter=isFetchNodesDone) BOOL fetchNodesDone;
@property (nonatomic, getter=isValidatingDecryptionKey) BOOL validatingDecryptionKey;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *closeBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *selectAllBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *importBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *downloadBarButtonItem;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareLinkBarButtonItem;
@property (weak, nonatomic) IBOutlet UIToolbar *toolbar;

@property (nonatomic, strong, nullable) MEGANode *parentNode;
@property (nonatomic, strong) MEGANodeList *nodeList;

@property (nonatomic, strong) NSMutableArray *cloudImages;

@property (weak, nonatomic) IBOutlet UIView *containerView;

@property (nonatomic, assign) ViewModePreferenceEntity viewModePreference;

@property (nonatomic, strong) RequestDelegate* requestDelegate;
@property (nonatomic, strong) GlobalDelegate* globalDelegate;

@end

@implementation FolderLinkViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.searchController = [UISearchController customSearchControllerWithSearchResultsUpdaterDelegate:self searchBarDelegate:self];
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.delegate = self;

    self.definesPresentationContext = YES;
    
    self.loginDone = NO;
    self.fetchNodesDone = NO;
    
    NSString *thumbsDirectory = [Helper pathForSharedSandboxCacheDirectory:@"thumbnailsV3"];
    NSError *error;
    if (![[NSFileManager defaultManager] fileExistsAtPath:thumbsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:thumbsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path failed with error: %@", error);
        }
    }
    
    NSString *previewsDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:@"previewsV3"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:previewsDirectory]) {
        if (![[NSFileManager defaultManager] createDirectoryAtPath:previewsDirectory withIntermediateDirectories:NO attributes:nil error:&error]) {
            MEGALogError(@"Create directory at path failed with error: %@", error);
        }
    }
    
    [self setEdgesForExtendedLayout:UIRectEdgeNone];
    
    self.navigationItem.title = LocalizedString(@"folderLink", @"");
    
    self.moreBarButtonItem.title = nil;
    self.moreBarButtonItem.image = [UIImage imageNamed:@"moreNavigationBar"];

    self.editBarButtonItem.title = LocalizedString(@"cancel", @"Button title to cancel something");

    self.navigationItem.rightBarButtonItems = @[self.moreBarButtonItem];

    self.navigationController.topViewController.toolbarItems = self.toolbar.items;
    [self.navigationController setToolbarHidden:NO animated:YES];
    
    self.closeBarButtonItem.title = LocalizedString(@"close", @"A button label.");

    if (self.isFolderRootNode) {
        self.navigationItem.leftBarButtonItem = self.closeBarButtonItem;
        [self setActionButtonsEnabled:NO];
    } else {
        [self reloadUI];
    }

    [self determineViewMode];
    [self configureContextMenuManager];
    
    self.moreBarButtonItem.accessibilityLabel = LocalizedString(@"more", @"Top menu option which opens more menu options in a context menu.");

    [self updateAppearance];

    [MEGASdk.shared addMEGATransferDelegate:self];
    
    [AppearanceManager forceSearchBarUpdate:self.searchController.searchBar 
       backgroundColorWhenDesignTokenEnable:[UIColor surface1Background]
                            traitCollection:self.traitCollection];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    MEGASdk *sdkFolder = MEGASdk.sharedFolderLink;
    [sdkFolder addMEGAGlobalDelegate:self.globalDelegate];
    [sdkFolder addMEGARequestDelegate:self.requestDelegate];
    
    if (!self.loginDone && self.isFolderRootNode) {
        [sdkFolder loginToFolderLink:self.publicLinkString];
    }
    
    self.navigationController.toolbarHidden = NO;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetConnectionChanged) name:kReachabilityChangedNotification object:nil];
    [sdkFolder retryPendingConnections];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    MEGASdk *sdkFolder = MEGASdk.sharedFolderLink;
    [sdkFolder removeMEGAGlobalDelegate:self.globalDelegate];
    [sdkFolder removeMEGARequestDelegate:self.requestDelegate];
    
    [AudioPlayerManager.shared removeDelegate:self];
    [AudioPlayerManager.shared removeMiniPlayerHandler:self];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
    
    [MEGASdk.shared removeMEGATransferDelegate:self];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [AudioPlayerManager.shared addDelegate:self];
    [AudioPlayerManager.shared addMiniPlayerHandler:self];
    [self shouldShowMiniPlayer];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        if (self.isFetchNodesDone) {
            [self setNavigationBarTitleLabel];
            [self.flTableView.tableView reloadEmptyDataSet];
        }
    } completion:nil];
}

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion {
    [super dismissViewControllerAnimated:flag completion:^{
        MEGALinkManager.secondaryLinkURL = nil;
        
        if (completion) {
            completion();
        }
    }];
}

#pragma mark - Private

- (void)reloadUI {
    if (!self.parentNode) {
        self.parentNode = [MEGASdk.sharedFolderLink rootNode];
    }
    
    [self setNavigationBarTitleLabel];
    
    self.nodeList = [MEGASdk.sharedFolderLink childrenForParent:self.parentNode order:[Helper sortTypeFor:self.parentNode]];
    if (_nodeList.size == 0) {
        [self setActionButtonsEnabled:NO];
    } else {
        [self setActionButtonsEnabled:YES];
    }
    
    NSMutableArray *tempArray = [[NSMutableArray alloc] initWithCapacity:self.nodeList.size];
    for (NSUInteger i = 0; i < self.nodeList.size ; i++) {
        [tempArray addObject:[self.nodeList nodeAtIndex:i]];
    }
    
    self.nodesArray = tempArray;

    [self reloadData];

    if (self.nodeList.size == 0) {
        [self.flTableView.tableView setTableHeaderView:nil];
    } else {
        [self addSearchBar];
    }
}

- (void)setNavigationBarTitleLabel {
    self.titleViewSubtitle = nil;
    
    if (self.flTableView.tableView.isEditing || self.flCollectionView.collectionView.allowsMultipleSelection) {
        self.navigationItem.titleView = nil;
        self.navigationItem.title = [self selectedCountTitle];
    } else {
        if (self.parentNode.name && !self.isFolderLinkNotValid) {
            self.titleViewSubtitle = LocalizedString(@"folderLink", @"");
            [self setNavigationTitleViewWithSubTitle:self.titleViewSubtitle];
        } else {
            self.navigationItem.title = LocalizedString(@"folderLink", @"");
        }
    }
}

- (void)showUnavailableLinkViewWithError:(UnavailableLinkError)error {
    [SVProgressHUD dismiss];
    
    self.titleViewSubtitle = LocalizedString(@"Unavailable", @"Text used to show the user that some resource is not available");
    [self setNavigationTitleViewWithSubTitle:self.titleViewSubtitle];
    
    [self disableUIItems];
    
    UnavailableLinkView *unavailableLinkView = [[[NSBundle mainBundle] loadNibNamed:@"UnavailableLinkView" owner:self options: nil] firstObject];
    switch (error) {
        case UnavailableLinkErrorGeneric:
            [unavailableLinkView configureInvalidFolderLink];
            break;
            
        case UnavailableLinkErrorETDDown:
            [unavailableLinkView configureInvalidFolderLinkByETD];
            break;
            
        case UnavailableLinkErrorUserETDSuspension:
            [unavailableLinkView configureInvalidFolderLinkByUserETDSuspension];
            break;
            
        case UnavailableLinkErrorUserCopyrightSuspension:
            [unavailableLinkView configureInvalidFolderLinkByUserCopyrightSuspension];
            break;
    }
    if (self.viewModePreference == ViewModePreferenceEntityList && self.flTableView.tableView != nil) {
        [self.flTableView.tableView setBackgroundView:unavailableLinkView];
    } else if (self.flCollectionView.collectionView != nil){
        [self.flCollectionView.collectionView setBackgroundView:unavailableLinkView];
    } else {
        unavailableLinkView.frame = self.view.bounds;
        [self.view addSubview:unavailableLinkView];
    }
}

- (void)disableUIItems {
    self.flTableView.tableView.emptyDataSetSource = nil;
    self.flTableView.tableView.emptyDataSetDelegate = nil;
    [self.flTableView.tableView setSeparatorColor:[UIColor clearColor]];
    [self.flTableView.tableView setBounces:NO];
    [self.flTableView.tableView setScrollEnabled:NO];
    
    [self setActionButtonsEnabled:NO];
}

- (void)setActionButtonsEnabled:(BOOL)boolValue {
    [_moreBarButtonItem setEnabled:boolValue];
    [self setToolbarButtonsEnabled:boolValue];
}

- (void)internetConnectionChanged {
    BOOL boolValue = [MEGAReachabilityManager isReachable];
    [self setActionButtonsEnabled:boolValue];
    
    boolValue ? [self addSearchBar] : [self hideSearchBarIfNotActive];
    
    [self reloadData];
}

- (void)setToolbarButtonsEnabled:(BOOL)boolValue {
    [self.shareLinkBarButtonItem setEnabled:boolValue];
    [self.importBarButtonItem setEnabled:boolValue];
    self.downloadBarButtonItem.enabled = boolValue;
}

- (void)addSearchBar {
    self.navigationItem.searchController = self.searchController;
}

- (void)hideSearchBarIfNotActive {
    self.searchController.active = false;
    self.navigationItem.searchController = nil;
}
    
- (void)showDecryptionAlert {
    UIAlertController *decryptionAlertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"decryptionKeyAlertTitle", @"") message:LocalizedString(@"decryptionKeyAlertMessage", @"") preferredStyle:UIAlertControllerStyleAlert];
    
    [decryptionAlertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = LocalizedString(@"decryptionKey", @"");
        [textField addTarget:self action:@selector(decryptionTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        textField.shouldReturnCompletion = ^BOOL(UITextField *textField) {
            return !textField.text.mnz_isEmpty;
        };
    }];
    
    [decryptionAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"cancel", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [MEGASdk.sharedFolderLink logout];
        [decryptionAlertController.textFields.firstObject resignFirstResponder];
        [self dismissViewControllerAnimated:YES completion:nil];
    }]];
    
    [decryptionAlertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"decrypt", @"") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *linkString = [MEGALinkManager buildPublicLink:self.publicLinkString withKey:decryptionAlertController.textFields.firstObject.text isFolder:YES];
        
        self.validatingDecryptionKey = YES;
        
        [MEGASdk.sharedFolderLink loginToFolderLink:linkString];
    }]];
    
    decryptionAlertController.actions.lastObject.enabled = NO;
    
    [self presentViewController:decryptionAlertController animated:YES completion:nil];
}

- (void)showDecryptionKeyNotValidAlert {
    self.validatingDecryptionKey = NO;
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:LocalizedString(@"decryptionKeyNotValid", @"") message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:LocalizedString(@"ok", @"") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self showDecryptionAlert];
    }]];
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)navigateToNodeWithBase64Handle:(NSString *)base64Handle {
    if (self.isFolderRootNode) {
        // Push folders to go to the selected subfolder:
        MEGANode *targetNode = [MEGASdk.sharedFolderLink nodeForHandle:[MEGASdk handleForBase64Handle:base64Handle]];
        if (targetNode) {
            MEGANode *tempNode = targetNode;
            NSMutableArray *nodesToPush = [NSMutableArray new];
            while (tempNode.handle != self.parentNode.handle) {
                [nodesToPush insertObject:tempNode atIndex:0];
                tempNode = [MEGASdk.sharedFolderLink nodeForHandle:tempNode.parentHandle];
            }
            
            for (MEGANode *node in nodesToPush) {
                if (node.type == MEGANodeTypeFolder) {
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Links" bundle:nil];
                    FolderLinkViewController *folderLinkVC = [storyboard instantiateViewControllerWithIdentifier:@"FolderLinkViewControllerID"];
                    [folderLinkVC setParentNode:node];
                    [folderLinkVC setIsFolderRootNode:NO];
                    folderLinkVC.publicLinkString = self.publicLinkString;
                    [self.navigationController pushViewController:folderLinkVC animated:NO];

                } else {
                    if ([FileExtensionGroupOCWrapper verifyIsVisualMedia:node.name]) {
                        [self presentMediaNode:node];
                    } else {
                        [node mnz_openNodeInNavigationController:self.navigationController folderLink:YES fileLink:nil messageId:nil chatId:nil isFromSharedItem:NO allNodes:nil];
                    }
                }
            }
        }
    }
}

- (void)decryptionTextFieldDidChange:(UITextField *)textField {
    UIAlertController *decryptionAlertController = (UIAlertController *)self.presentedViewController;
    if ([decryptionAlertController isKindOfClass:UIAlertController.class]) {
        UIAlertAction *okAction = decryptionAlertController.actions.lastObject;
        okAction.enabled = !textField.text.mnz_isEmpty;
    }
}

- (void)presentMediaNode:(MEGANode *)node {
    MEGANode *parentNode = [MEGASdk.sharedFolderLink nodeForHandle:node.parentHandle];
    MEGANodeList *nodeList = [MEGASdk.sharedFolderLink childrenForParent:parentNode];
    NSMutableArray<MEGANode *> *mediaNodesArray = [nodeList mnz_mediaAuthorizeNodesMutableArrayFromNodeListWithSdk:MEGASdk.sharedFolderLink];
    
    MEGAPhotoBrowserViewController *photoBrowserVC = [MEGAPhotoBrowserViewController photoBrowserWithMediaNodes:mediaNodesArray api:MEGASdk.sharedFolderLink displayMode:DisplayModeNodeInsideFolderLink isFromSharedItem:NO presentingNode:node];
    
    [self.navigationController presentViewController:photoBrowserVC animated:YES completion:nil];
}

- (void)reloadData {
    if (self.viewModePreference == ViewModePreferenceEntityList) {
        [self.flTableView.tableView reloadData];
    } else {
        [self.flCollectionView reloadData];
    }
}

- (GlobalDelegate *)globalDelegate {
    if (_globalDelegate == nil) {
        __weak __typeof__(self) weakSelf = self;
        _globalDelegate = [GlobalDelegate.alloc initOnNodesUpdateCompletion:^(MEGANodeList * _Nullable nodeList) {
            [weakSelf onNodesUpdate:MEGASdk.sharedFolderLink nodeList:nodeList];
        }];
    }
    return _globalDelegate;
}

- (RequestDelegate *)requestDelegate {
    if (_requestDelegate == nil) {
        __weak __typeof__(self) weakSelf = self;
        MEGASdk *sdkFolder = MEGASdk.sharedFolderLink;
        _requestDelegate = [RequestDelegate.alloc initOnRequestStartHandler:^(MEGARequest * _Nonnull request) {
            [weakSelf onRequestStart:sdkFolder request:request];
        } completion:^(MEGARequest * _Nonnull request, MEGAError * _Nonnull error) {
            [weakSelf onRequestFinish:sdkFolder request:request error:error];
        }];
    }
    return _requestDelegate;
}

#pragma mark - Layout

- (void)determineViewMode {
    NSInteger nodesWithThumbnail = 0;
    NSInteger nodesWithoutThumbnail = 0;

    for (MEGANode *node in self.nodesArray) {
        if (node.hasThumbnail) {
            nodesWithThumbnail = nodesWithThumbnail + 1;
        } else {
            nodesWithoutThumbnail = nodesWithoutThumbnail + 1;
        }
    }
    
    if (nodesWithThumbnail > nodesWithoutThumbnail) {
        [self initCollection];
    } else {
        [self initTable];
    }
}
    
- (void)initTable {
    [self.flCollectionView willMoveToParentViewController:nil];
    [self.flCollectionView.view removeFromSuperview];
    [self.flCollectionView removeFromParentViewController];
    self.flCollectionView = nil;
    
    self.viewModePreference = ViewModePreferenceEntityList;
    
    self.flTableView = [FolderLinkTableViewController instantiateWithFolderLink:self];
    [self addChildViewController:self.flTableView];
    self.flTableView.view.frame = self.containerView.bounds;
    [self.containerView addSubview:self.flTableView.view];
    [self. flTableView didMoveToParentViewController:self];
    
    self.flTableView.tableView.emptyDataSetSource = self;
    self.flTableView.tableView.emptyDataSetDelegate = self;
}
    
- (void)initCollection {
    [self.flTableView willMoveToParentViewController:nil];
    [self.flTableView.view removeFromSuperview];
    [self.flTableView removeFromParentViewController];
    self.flTableView = nil;

    self.viewModePreference = ViewModePreferenceEntityThumbnail;

    self.flCollectionView = [FolderLinkCollectionViewController instantiateWithFolderLink:self];
    [self addChildViewController:self.flCollectionView];
    self.flCollectionView.view.frame = self.containerView.bounds;
    [self.containerView addSubview:self.flCollectionView.view];
    [self.flCollectionView didMoveToParentViewController:self];

    self.flCollectionView.collectionView.emptyDataSetDelegate = self;
    self.flCollectionView.collectionView.emptyDataSetSource = self;
}
    
- (void)changeViewModePreference {
    self.viewModePreference = (self.viewModePreference == ViewModePreferenceEntityList) ? ViewModePreferenceEntityThumbnail : ViewModePreferenceEntityList;
    
    if (self.viewModePreference == ViewModePreferenceEntityThumbnail) {
        [self initCollection];
    } else {
        [self initTable];
    }
}
- (void)didDownloadTransferFinish:(MEGANode *)node {
    if (self.viewModePreference == ViewModePreferenceEntityList) {
        [self.flTableView reloadWithNode:node];
    } else {
        [self.flCollectionView reloadWithNode:node];
    }
}
    
#pragma mark - IBActions

- (IBAction)cancelAction:(UIBarButtonItem *)sender {
    [MEGALinkManager resetUtilsForLinksWithoutSession];

    if (!AudioPlayerManager.shared.isPlayerAlive) {
        [MEGASdk.sharedFolderLink logout];
    }

    [SVProgressHUD dismiss];

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)editAction:(UIBarButtonItem *)sender {
    BOOL enableEditing = self.viewModePreference == ViewModePreferenceEntityList ? !self.flTableView.tableView.isEditing : !self.flCollectionView.collectionView.allowsMultipleSelection;
    [self setEditMode:enableEditing];
}

- (void)setViewEditing:(BOOL)editing {    
    [self setNavigationBarTitleLabel];

    [self setToolbarButtonsEnabled:!editing];
    
    if (editing) {
        self.moreBarButtonItem.title = LocalizedString(@"cancel", @"Button title to cancel something");
        self.moreBarButtonItem.image = nil;
        self.moreBarButtonItem.menu = nil;
        self.moreBarButtonItem.action = @selector(editAction:);
        self.moreBarButtonItem.target = self;

        [self.navigationItem setLeftBarButtonItem:self.selectAllBarButtonItem];
    } else {
        self.moreBarButtonItem.title = nil;
        self.moreBarButtonItem.action = nil;
        self.moreBarButtonItem.target = nil;
        self.moreBarButtonItem.image = [UIImage imageNamed:@"moreNavigationBar"];
        [self setMoreButton];

        [self setAllNodesSelected:NO];
        self.selectedNodesArray = nil;

        if (self.isFolderRootNode) {
            [self.navigationItem setLeftBarButtonItem:self.closeBarButtonItem];
        } else {
            [self.navigationItem setLeftBarButtonItem:nil];
        }
    }
    
    if (!self.selectedNodesArray) {
        self.selectedNodesArray = [NSMutableArray new];
    }
    
    if ([AudioPlayerManager.shared isPlayerAlive]) {
        [AudioPlayerManager.shared playerHidden:editing presenter:self];
    }
    
    [self reloadData];
}

- (IBAction)selectAllAction:(UIBarButtonItem *)sender {
    [_selectedNodesArray removeAllObjects];
    
    if (![self areAllNodesSelected]) {
        BOOL isSearchActive = self.searchController.isActive && !self.searchController.searchBar.text.mnz_isEmpty;
        NSArray *nodesArray = isSearchActive ? self.searchNodesArray : [self.nodeList mnz_nodesArrayFromNodeList];
        self.selectedNodesArray = nodesArray.mutableCopy;
        [self setAllNodesSelected:YES];
    } else {
        [self setAllNodesSelected:NO];
    }
    
    (self.selectedNodesArray.count == 0) ? [self setToolbarButtonsEnabled:NO] : [self setToolbarButtonsEnabled:YES];
    
    [self setNavigationBarTitleLabel];
    
    [self reloadData];
}

- (IBAction)shareLinkAction:(UIBarButtonItem *)sender {
    NSString *link = self.linkEncryptedString ? self.linkEncryptedString : self.publicLinkString;
    if (link != nil) {
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[link] applicationActivities:nil];
        activityVC.popoverPresentationController.barButtonItem = sender;
        [self presentViewController:activityVC animated:YES completion:nil];
    }
}
    
- (IBAction)downloadAction:(UIBarButtonItem *)sender {
    if (self.selectedNodesArray.count != 0) {
        [self download:self.selectedNodesArray];
    } else {
        if (self.parentNode == nil) {
            return;
        }
        [self download:@[self.parentNode]];
    }
    [self setEditMode:NO];
}

- (IBAction)importAction:(UIBarButtonItem *)sender {
    [self importFilesFromFolderLink];
}

- (void)openNode:(MEGANode *)node {
    if ([MEGAReachabilityManager isReachableHUDIfNot]) {
        if ([FileExtensionGroupOCWrapper verifyIsVisualMedia:node.name]) {
            [self presentMediaNode:node];
        } else {
            [node mnz_openNodeInNavigationController:self.navigationController folderLink:YES fileLink:nil messageId:nil chatId:nil isFromSharedItem:NO allNodes:nil];
        }
    }
}

#pragma mark - Public

- (BOOL)isListViewModeSelected {
    return self.viewModePreference == ViewModePreferenceEntityList;
}
    
- (void)didSelectNode:(MEGANode *)node {
    switch (node.type) {
        case MEGANodeTypeFolder: {
            FolderLinkViewController *folderLinkVC = [self folderLinkViewControllerFromNode:node];
            [self.navigationController pushViewController:folderLinkVC animated:YES];
            break;
        }

        case MEGANodeTypeFile: {
            if ([FileExtensionGroupOCWrapper verifyIsVisualMedia:node.name]) {
                [self presentMediaNode:node];
            } else {
                [node mnz_openNodeInNavigationController:self.navigationController folderLink:YES fileLink:nil messageId:nil chatId:nil isFromSharedItem:NO allNodes:self.nodesArray];
            }
            break;
        }
        
        default:
            break;
    }
}

- (void)setEditMode:(BOOL)editMode {
    if (self.viewModePreference == ViewModePreferenceEntityList) {
        [self.flTableView setTableViewEditing:editMode animated:YES];
    } else {
        [self.flCollectionView setCollectionViewEditing:editMode animated:YES];
    }

    [self setNavigationBarButton:editMode];
}

- (FolderLinkViewController *)folderLinkViewControllerFromNode:(MEGANode *)node {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Links" bundle:[NSBundle bundleForClass:self.class]];
    FolderLinkViewController *folderLinkVC = [storyboard instantiateViewControllerWithIdentifier:@"FolderLinkViewControllerID"];
    [folderLinkVC setParentNode:node];
    [folderLinkVC setIsFolderRootNode:NO];
    folderLinkVC.publicLinkString = self.publicLinkString;
    return folderLinkVC;
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    self.searchNodesArray = nil;
    
    if (!MEGAReachabilityManager.isReachable) {
        self.flTableView.tableView.tableHeaderView = nil;
    }
}

#pragma mark - UISearchResultsUpdating

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchString = searchController.searchBar.text;
    if ([searchString isEqualToString:@""]) {
        self.searchNodesArray = self.nodesArray;
    } else {
        NSPredicate *resultPredicate = [NSPredicate predicateWithFormat:@"SELF.name contains[c] %@", searchString];
        self.searchNodesArray = [self.nodesArray filteredArrayUsingPredicate:resultPredicate];
    }
    [self reloadData];
}

#pragma mark - DZNEmptyDataSetSource

- (nullable UIView *)customViewForEmptyDataSet:(UIScrollView *)scrollView {
    EmptyStateView *emptyStateView = [EmptyStateView.alloc initWithImage:[self imageForEmptyState] title:[self titleForEmptyState] description:[self descriptionForEmptyState] buttonTitle:[self buttonTitleForEmptyState]];
    [emptyStateView.button addTarget:self action:@selector(buttonTouchUpInsideEmptyState) forControlEvents:UIControlEventTouchUpInside];
    
    return emptyStateView;
}

#pragma mark - Empty State

- (NSString *)titleForEmptyState {
    NSString *text;
    if ([MEGAReachabilityManager isReachable]) {
        if (!self.isFetchNodesDone && self.isFolderRootNode) {
            if (self.isFolderLinkNotValid) {
                text = LocalizedString(@"linkNotValid", @"");
            } else {
                text = @"";
            }
        } else {
            if (self.searchController.isActive) {
                text = LocalizedString(@"noResults", @"");
            } else {
                text = LocalizedString(@"emptyFolder", @"Title shown when a folder doesn't have any files");
            }
        }
    } else {
        text = LocalizedString(@"noInternetConnection",  @"No Internet Connection");
    }
    
    return text;
}

- (NSString *)descriptionForEmptyState {
    NSString *text = @"";
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = LocalizedString(@"Mobile Data is turned off", @"Information shown when the user has disabled the 'Mobile Data' setting for MEGA in the iOS Settings.");
    }
    
    return text;
}

- (UIImage *)imageForEmptyState {
    if ([MEGAReachabilityManager isReachable]) {
        if (!self.isFetchNodesDone && self.isFolderRootNode) {
            if (self.isFolderLinkNotValid) {
                return [UIImage imageNamed:@"invalidFolderLink"];
            }
            return nil;
        }
        
         if (self.searchController.isActive) {
             return [UIImage imageNamed:@"searchEmptyState"];
         }
        
        return [UIImage imageNamed:@"folderEmptyState"];
    } else {
        return [UIImage imageNamed:@"noInternetEmptyState"];
    }
}

- (NSString *)buttonTitleForEmptyState {
    NSString *text = @"";
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        text = LocalizedString(@"Turn Mobile Data on", @"Button title to go to the iOS Settings to enable 'Mobile Data' for the MEGA app.");
    }
    
    return text;
}

- (void)buttonTouchUpInsideEmptyState {
    if (!MEGAReachabilityManager.isReachable && !MEGAReachabilityManager.sharedManager.isMobileDataEnabled) {
        [UIApplication.sharedApplication openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
    }
}

#pragma mark - MEGAGlobalDelegate

- (void)onNodesUpdate:(MEGASdk *)api nodeList:(MEGANodeList *)nodeList {
    if ([self shouldProcessOnNodesUpdateWith:nodeList childNodes:self.nodesArray parentNode:self.parentNode]) {
        [self reloadUI];
    }
}

#pragma mark - MEGARequestDelegate

- (void)onRequestStart:(MEGASdk *)api request:(MEGARequest *)request {
    switch ([request type]) {
        case MEGARequestTypeLogin: {
            self.folderLinkNotValid = NO;
            break;
        }
            
        case MEGARequestTypeFetchNodes: {
            [SVProgressHUD show];
            break;
        }
            
        default:
            break;
    }
}

- (void)onRequestFinish:(MEGASdk *)api request:(MEGARequest *)request error:(MEGAError *)error {
    if (error.type) {
        if (error.hasExtraInfo) {
            if (error.linkStatus == MEGALinkErrorCodeDownETD) {
                [self showUnavailableLinkViewWithError:UnavailableLinkErrorETDDown];
            } else if (error.userStatus == MEGAUserErrorCodeETDSuspension) {
                [self showUnavailableLinkViewWithError:UnavailableLinkErrorUserETDSuspension];
            } else if (error.userStatus == MEGAUserErrorCodeCopyrightSuspension) {
                [self showUnavailableLinkViewWithError:UnavailableLinkErrorUserCopyrightSuspension];
            } else {
                [self showUnavailableLinkViewWithError:UnavailableLinkErrorGeneric];
            }
        } else {
            switch (error.type) {
                case MEGAErrorTypeApiEArgs: {
                    if (request.type == MEGARequestTypeLogin) {
                        if (self.isValidatingDecryptionKey) { //If the user have written the key
                            [self showDecryptionKeyNotValidAlert];
                        } else {
                            [self showUnavailableLinkViewWithError:UnavailableLinkErrorGeneric];
                        }
                    } else if (request.type == MEGARequestTypeFetchNodes) {
                        [self showUnavailableLinkViewWithError:UnavailableLinkErrorGeneric];
                    }
                    break;
                }
                    
                case MEGAErrorTypeApiENoent: {
                    if (request.type == MEGARequestTypeFetchNodes || request.type == MEGARequestTypeLogin) {
                        [self showUnavailableLinkViewWithError:UnavailableLinkErrorGeneric];
                    }
                    break;
                }
                    
                case MEGAErrorTypeApiEIncomplete: {
                    [self showDecryptionAlert];
                    break;
                }
                    
                default: {
                    if (request.type == MEGARequestTypeLogin) {
                        [self showUnavailableLinkViewWithError:UnavailableLinkErrorGeneric];
                    } else if (request.type == MEGARequestTypeFetchNodes) {
                        [api logout];
                        [self showUnavailableLinkViewWithError:UnavailableLinkErrorGeneric];
                    }
                    break;
                }
            }
        }
        
        return;
    }
    
    switch (request.type) {
        case MEGARequestTypeLogin: {
            self.loginDone = YES;
            self.fetchNodesDone = NO;
            [api fetchNodes];
            break;
        }
            
        case MEGARequestTypeFetchNodes: {
            
            if (request.flag) { //Invalid key
                [api logout];
                
                [SVProgressHUD dismiss];
                
                if (self.isValidatingDecryptionKey) { //Link without key, after entering a bad one
                    [self showDecryptionKeyNotValidAlert];
                } else { //Link with invalid key
                    [self showUnavailableLinkViewWithError:UnavailableLinkErrorGeneric];
                }
                return;
            }
            
            self.fetchNodesDone = YES;
            
            [self reloadUI];

            [self determineViewMode];
            
            [self configureContextMenuManager];

            NSArray *componentsArray = [self.publicLinkString componentsSeparatedByString:@"!"];
            if (componentsArray.count == 4) {
                [self navigateToNodeWithBase64Handle:componentsArray.lastObject];
            }
            
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"TransfersPaused"]) {
                [api pauseTransfers:YES];
            }
            [SVProgressHUD dismiss];
            break;
        }
            
        case MEGARequestTypeLogout: {
            self.loginDone = NO;
            self.fetchNodesDone = NO;
            [api removeMEGAGlobalDelegate:self];
            [api removeMEGARequestDelegate:self];
            break;
        }
            
        case MEGARequestTypeGetAttrFile: {
            for (NodeTableViewCell *nodeTableViewCell in self.flTableView.tableView.visibleCells) {
                if (request.nodeHandle == nodeTableViewCell.node.handle) {
                    MEGANode *node = [api nodeForHandle:request.nodeHandle];
                    [Helper setThumbnailForNode:node api:api cell:nodeTableViewCell];
                }
            }
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - AudioPlayerPresenterProtocol

- (void)updateContentView:(CGFloat)height {
    if (self.viewModePreference == ViewModePreferenceEntityList) {
        self.flTableView.tableView.contentInset = UIEdgeInsetsMake(0, 0, height, 0);
    } else {
        self.flCollectionView.collectionView.contentInset = UIEdgeInsetsMake(0, 0, height, 0);
    }
}

@end
