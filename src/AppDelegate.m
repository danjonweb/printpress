#import "AppDelegate.h"
#import "PostsController.h"
#import "EditController.h"
#import "AccountsController.h"
#import "XMLRPCManager.h"
#import "DataManager.h"
#import "INAppStoreWindow.h"
#import "LSDocument.h"
#import "NSColor+CGColor.h"
#import "NSAlert+SynchronousSheet.h"
#import "NSImage+Tint.h"
#import "NSColor+Hex.h"
#import "NSMenu+Utils.h"


@implementation AppDelegate

+ (void)initialize {
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Defaults" ofType:@"plist"]]];
}

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startProgressAnimation:) name:XMLRPCBeginQueueNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(stopProgressAnimation:) name:XMLRPCEndQueueNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postDoubleClicked:) name:@"PostDoubleClickedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postSelectionChanged:) name:@"PostSelectionDidChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(postSelectionWillChange:) name:@"PostSelectionWillChangeNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newPostCreated:) name:@"NewPostCreatedNotification" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountChanged:) name:@"AccountDidChangeNotification" object:nil];

    //[self redirectNSLogToDocuments];

    NSView *titleBarView = [mainWindow titleBarView];
    mainWindow.titleBarHeight = 46.0;
    mainWindow.centerFullScreenButton = YES;
    [toolbarProgressIndicator setFrameOrigin:NSMakePoint(NSWidth(titleBarView.bounds) - NSWidth(toolbarProgressIndicator.bounds) - 30, 0.5 * (NSHeight(titleBarView.bounds) - NSHeight(toolbarProgressIndicator.bounds)))];
    [toolbarProgressIndicator setAutoresizingMask:NSViewMinXMargin];
    [titleBarView addSubview:toolbarProgressIndicator];
    //[toolbarCenterView setFrameOrigin:NSMakePoint(0, 0.5 * (NSHeight(titleBarView.bounds) - NSHeight(toolbarCenterView.bounds)))];
    [toolbarTitleField setFrame:NSMakeRect(0, 0.5 * (NSHeight(titleBarView.bounds) - NSHeight(toolbarTitleField.bounds)), NSWidth(titleBarView.bounds), NSHeight(toolbarTitleField.bounds))];
    [toolbarTitleField setAutoresizingMask:NSViewWidthSizable];
    [toolbarTitleField setEnabled:NO];
    //[titleBarView addSubview:toolbarTitleField];

    [toolbarButtonView setFrame:NSMakeRect(0.5 * (NSWidth(titleBarView.bounds) - NSWidth(toolbarButtonView.bounds)), 0.5 * (NSHeight(titleBarView.bounds) - NSHeight(toolbarButtonView.bounds)), NSWidth(toolbarButtonView.bounds), NSHeight(toolbarButtonView.bounds))];
    [titleBarView addSubview:toolbarButtonView];
    [toolbarButtonView setAutoresizingMask:(NSViewMinXMargin | NSViewMaxXMargin)];
    
    [toolbarGoToPostsButton setFrame:NSMakeRect([mainWindow trafficLightButtonsLeftMargin] + 61, 0.5 * (NSHeight(titleBarView.bounds) - NSHeight(toolbarGoToPostsButton.bounds)) - 1, NSWidth(toolbarGoToPostsButton.bounds), NSHeight(toolbarGoToPostsButton.bounds))];
    //[titleBarView addSubview:toolbarGoToPostsButton];

    mainWindow.titleBarEndColor = [NSColor colorWithCalibratedWhite:247/255.f alpha:1.0];
    mainWindow.titleBarStartColor = [NSColor colorWithCalibratedWhite:232/255.f alpha:1.0];
    mainWindow.baselineSeparatorColor = [NSColor colorWithCalibratedWhite:194/255.f alpha:1.0];

    mainWindow.inactiveTitleBarEndColor = [NSColor colorWithCalibratedWhite:247/255.f alpha:1.0];
    mainWindow.inactiveTitleBarStartColor = [NSColor colorWithCalibratedWhite:232/255.f alpha:1.0];
    mainWindow.inactiveBaselineSeparatorColor = [NSColor colorWithCalibratedWhite:194/255.f alpha:1.0];

    [self setupMainViews];
    [self setupToolbarButtons];
    [toolbarTitleField setStringValue:@"Accounts"];
    [toolbarGoToPostsButton setHidden:YES];
    [toolbarProgressIndicator setHidden:YES];
    //[[self.actionButton menu] setFont:[NSFont boldSystemFontOfSize:11.0]];
    [self resetEnabledControls];

    [accountsController start];
    [xmlrpcManager start];
    [dataManager start];
    [editController start];
    [postsController start];

    if (IN_TRIAL_MODE) {
        [accountsController refreshSelectedBlog];
        [self transitiontoView:mainPostsView animate:NO];
    } else {
        if ([accountsController shouldAutoLogin]) {
            [accountsController selectAutoLoginAccount];
            [accountsController refreshSelectedBlog];
            [self transitiontoView:mainPostsView animate:NO];
        }
    }
}

- (void)dealloc {
    [accountsController stop];
    [xmlrpcManager stop];
    [dataManager stop];
    [editController stop];
    [postsController stop];
    
    [super dealloc];
}

- (void)redirectNSLogToDocuments {
    NSArray *allPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [allPaths objectAtIndex:0];
    NSString *pathForLog = [documentsDirectory stringByAppendingPathComponent:@"printpress.log"];
    
    [[NSFileManager defaultManager] removeItemAtPath:pathForLog error:nil];

    freopen([pathForLog cStringUsingEncoding:NSASCIIStringEncoding],"a+",stderr);
}

#pragma mark Notifications

- (void)windowWillEnterFullScreen:(NSNotification *)notification {
    NSView *titleBarView = [mainWindow titleBarView];
    [toolbarGoToPostsButton setFrame:NSMakeRect([mainWindow trafficLightButtonsLeftMargin], 0.5 * (NSHeight(titleBarView.bounds) - NSHeight(toolbarGoToPostsButton.bounds)) - 1, NSWidth(toolbarGoToPostsButton.bounds), NSHeight(toolbarGoToPostsButton.bounds))];
}

- (void)windowWillExitFullScreen:(NSNotification *)notification {
    NSView *titleBarView = [mainWindow titleBarView];
    [toolbarGoToPostsButton setFrame:NSMakeRect([mainWindow trafficLightButtonsLeftMargin] + 61, 0.5 * (NSHeight(titleBarView.bounds) - NSHeight(toolbarGoToPostsButton.bounds)) - 1, NSWidth(toolbarGoToPostsButton.bounds), NSHeight(toolbarGoToPostsButton.bounds))];
}

- (BOOL)windowShouldClose:(NSNotification *)notification {
    if ([mainWindow isDocumentEdited]) {
        [self showUnsavedDocumentAlertWithContext:@{@"action":@"window"}];
        return NO;
    }
    return YES;
}

- (void)windowWillClose:(NSNotification *)notification {
    [NSApp terminate:self];
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    [mainAccountView setNeedsDisplay:YES];
    [mainPostsView setNeedsDisplay:YES];
    [mainEditView setNeedsDisplay:YES];
    //[dataManager loadDrafts];
}

- (void)windowDidResignKey:(NSNotification *)notification {
    [mainAccountView setNeedsDisplay:YES];
    [mainPostsView setNeedsDisplay:YES];
    [mainEditView setNeedsDisplay:YES];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    if ([self windowShouldClose:nil]) {
        return NSTerminateNow;
    }
    return NSTerminateCancel;
}

- (void)accountChanged:(NSNotification *)notification {
    [postsController.postsOutlineView deselectAll:nil];
    [self resetEnabledControls];
}

#pragma mark -

- (IBAction)emailTheDeveloper:(id)sender {
    NSString *encodedSubject = [NSString stringWithFormat:@"SUBJECT=%@", [@"Printpress App Support" stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    NSString *encodedBody = [NSString stringWithFormat:@"BODY=%@", [@"" stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
    NSString *encodedTo = [@"hello@printpressapp.com" stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding];
    NSString *encodedURLString = [NSString stringWithFormat:@"mailto:%@?%@&%@", encodedTo, encodedSubject, encodedBody];
    NSURL *mailtoURL = [NSURL URLWithString:encodedURLString];
    [[NSWorkspace sharedWorkspace] openURL:mailtoURL];
}

#pragma mark -

- (void)startProgressAnimation:(NSNotification *)notification {
    [postsController setEnabled:NO];
    [toolbarProgressIndicator setHidden:NO];
    [postsController.createPostButton setEnabled:NO];
    [self resetEnabledControls];
    [toolbarProgressIndicator startAnimation:nil];
}

- (void)stopProgressAnimation:(NSNotification *)notification {
    [postsController setEnabled:YES];
    [toolbarProgressIndicator setHidden:YES];
    [postsController.createPostButton setEnabled:YES];
    [self resetEnabledControls];
    [toolbarProgressIndicator stopAnimation:nil];
}

#pragma mark -

- (void)performActionWithContext:(NSDictionary *)context {
    if ([context[@"action"] isEqualToString:@"transition"]) {
        [self transitiontoView:context[@"view"] animate:@(YES)];
    }
    if ([context[@"action"] isEqualToString:@"selection"]) {
        NSInteger row = [context[@"row"] integerValue];
        if (row == -1)
            [postsController.postsOutlineView deselectAll:nil];
        else
            [postsController.postsOutlineView selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }
    if ([context[@"action"] isEqualToString:@"window"]) {
        [mainWindow performClose:nil];
    }
    [context release];
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertDefaultReturn) {
        // Save
        [dataManager saveDraft:nil];
    } else if (returnCode == NSAlertOtherReturn) {
        // Cancel
        return;
    } else if (returnCode == NSAlertAlternateReturn) {
        // Delete
        [mainWindow setDocumentEdited:NO];
    }

    [self performSelector:@selector(performActionWithContext:) withObject:contextInfo afterDelay:0.3];
}

- (void)showUnsavedDocumentAlertWithContext:(NSDictionary *)context {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Save changes?" defaultButton:@"Save" alternateButton:@"Don't Save" otherButton:@"Cancel" informativeTextWithFormat:@"Changes will be saved to a local draft, which you can send to your blog later. If you do not save, changes will be lost."];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert beginSheetModalForWindow:mainWindow modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:[context retain]];
}

- (IBAction)refreshAndGoToPosts:(id)sender {
    [accountsController refreshSelectedBlog];
    [self transitiontoView:mainPostsView animate:@(YES)];
}

- (void)postDoubleClicked:(NSNotification *)notification {
    [self transitiontoView:mainEditView animate:@(YES)];
}

- (void)postSelectionChanged:(NSNotification *)notification {
    if (postsController.isDocumentSelected) {
        [self.goToEditorMenuItem setEnabled:YES];
        [self.goToEditorButton setEnabled:YES];
        [self.commitMenuItem setEnabled:YES];
        [self.saveDraftMenuItem setEnabled:YES];
        [self.togglePostPreviewMenuItem setEnabled:YES];
        [self.loadPostPreviewMenuItem setEnabled:postsController.selectedDocument.docType == DocumentPostType];

        if (currentMainView == mainPostsView) {
            if ([self.actionButton.menu indexOfItemWithTag:1] == -1) {
                [self.actionButton.menu insertItemWithTitle:@"Save To Blog" action:@selector(actionPressed:) keyEquivalent:@"t" atIndex:0];
                [self.actionButton.menu insertItemWithTitle:@"Save Draft" action:@selector(actionPressed:) keyEquivalent:@"s" atIndex:1];
                [self.actionButton.menu insertItem:[NSMenuItem separatorItem] atIndex:2];
                [self.actionButton.menu insertItemWithTitle:@"Delete Post…" action:@selector(actionPressed:) keyEquivalent:@"" atIndex:4];
                [[self.actionButton.menu itemAtIndex:0] setTag:1];
                [[self.actionButton.menu itemAtIndex:1] setTag:1];
                [[self.actionButton.menu itemAtIndex:2] setTag:1];
                [[self.actionButton.menu itemAtIndex:4] setTag:1];
            }
        }

    } else {
        [self.goToEditorMenuItem setEnabled:NO];
        [self.goToEditorButton setEnabled:NO];
        [self.commitMenuItem setEnabled:NO];
        [self.saveDraftMenuItem setEnabled:NO];
        [self.togglePostPreviewMenuItem setEnabled:NO];
        [self.loadPostPreviewMenuItem setEnabled:NO];

        if (currentMainView == mainPostsView) {
            for (NSMenuItem *item in self.actionButton.menu.itemArray) {
                if (item.tag == 1)
                    [self.actionButton.menu removeItem:item];
            }
        }
    }
    [self.actionButton.menu adjustLineHeightFromIndex:0];
}

#pragma mark -
#pragma mark Main Views

- (void)resetEnabledControls {
    [self.goToAccountsButton setEnabled:NO];
    [self.goToPostsButton setEnabled:NO];
    [self.goToEditorButton setEnabled:NO];
    [self.actionButton setEnabled:NO];

    [self.goToAccountsMenuItem setEnabled:NO];
    [self.goToPostsMenuItem setEnabled:NO];
    [self.goToEditorMenuItem setEnabled:NO];
    [self.reloadPostsMenuItem setEnabled:NO];
    [self.reloadImagesMenuItem setEnabled:NO];

    [self.togglePostDetailsMenuItem setEnabled:NO];
    [self.showWYSIWYGMenuItem setEnabled:NO];
    [self.showHTMLMenuItem setEnabled:NO];
    [self.saveDraftMenuItem setEnabled:NO];
    [self.commitMenuItem setEnabled:NO];
    [self.togglePostPreviewMenuItem setEnabled:NO];

    [self.showCSSEditorMenuItem setEnabled:NO];

    if (toolbarProgressIndicator.isHidden) {
        [self.actionButton setEnabled:YES];

        [self.goToAccountsButton setEnabled:YES];
        [self.goToAccountsMenuItem setEnabled:YES];

        if ([accountsController.lastAccountLoaded isEqualToString:accountsController.blogUUID]) {
            [self.goToPostsButton setEnabled:YES];
            [self.goToPostsMenuItem setEnabled:YES];
        }

        if (postsController.isDocumentSelected) {
            [self.goToEditorButton setEnabled:YES];
            [self.goToEditorMenuItem setEnabled:YES];
            [self.commitMenuItem setEnabled:YES];
        }
        
        NSColor *toolbarIconSelectedColor = [NSColor colorFromHexRGB:@"1D77EF"];

        if (currentMainView == mainAccountView) {
            //NSImage *image = [NSImage imageNamed:[NSString stringWithFormat:@"%@-selected", [self.goToAccountsButton identifier]]];
            //[self.goToAccountsButton setImage:image];
            //[self.goToAccountsButton setAlternateImage:image];
            self.goToAccountsButton.image = [[NSImage imageNamed:@"769-male"] imageWithTint:toolbarIconSelectedColor];
            self.goToAccountsButton.alternateImage = [[NSImage imageNamed:@"769-male"] imageWithTint:toolbarIconSelectedColor];
            

            [toolbarTitleField setStringValue:@"Accounts"];
            [toolbarGoToPostsButton setHidden:YES];
            [self.reloadPostsMenuItem setEnabled:YES];
            [self.reloadImagesMenuItem setEnabled:YES];
        } else if (currentMainView == mainPostsView) {
            //NSImage *image = [NSImage imageNamed:[NSString stringWithFormat:@"%@-selected", [self.goToPostsButton identifier]]];
            //[self.goToPostsButton setImage:image];
            //[self.goToPostsButton setAlternateImage:image];
            self.self.goToPostsButton.image = [[NSImage imageNamed:@"747-tag"] imageWithTint:toolbarIconSelectedColor];
            self.self.goToPostsButton.alternateImage = [[NSImage imageNamed:@"747-tag"] imageWithTint:toolbarIconSelectedColor];

            [toolbarTitleField setStringValue:@"Posts"];
            [toolbarGoToPostsButton setHidden:YES];
            [postsController.postsOutlineViewDelegate reloadSelectedPostAndContent:YES];

            [self.togglePostDetailsMenuItem setEnabled:YES];
            [self.reloadPostsMenuItem setEnabled:YES];
            [self.reloadImagesMenuItem setEnabled:YES];
        } else if (currentMainView == mainEditView) {
            //NSImage *image = [NSImage imageNamed:[NSString stringWithFormat:@"%@-selected", [self.goToEditorButton identifier]]];
            //[self.goToEditorButton setImage:image];
            //[self.goToEditorButton setAlternateImage:image];
            self.self.goToEditorButton.image = [[NSImage imageNamed:@"704-compose"] imageWithTint:toolbarIconSelectedColor];
            self.self.goToEditorButton.alternateImage = [[NSImage imageNamed:@"704-compose"] imageWithTint:toolbarIconSelectedColor];
            
            [toolbarTitleField setStringValue:postsController.selectedDocumentTitle];
            [toolbarGoToPostsButton setHidden:NO];
            [self.showWYSIWYGMenuItem setEnabled:YES];
            [self.showHTMLMenuItem setEnabled:YES];
            [self.saveDraftMenuItem setEnabled:YES];
            [self.showCSSEditorMenuItem setEnabled:YES];
            [self.togglePostPreviewMenuItem setEnabled:YES];
        }
    }
}

- (void)loadActionMenu {
    [self.actionButton.menu removeAllItems];
    if (currentMainView == mainAccountView) {
        [self.actionButton.menu addItemWithTitle:@"Load Posts" action:@selector(actionPressed:) keyEquivalent:@""];
    } else if (currentMainView == mainPostsView) {
        [self.actionButton.menu addItemWithTitle:@"New Post" action:@selector(actionPressed:) keyEquivalent:@""];
        [self.actionButton.menu addItem:[NSMenuItem separatorItem]];
        [self.actionButton.menu addItemWithTitle:@"Reload Posts" action:@selector(actionPressed:) keyEquivalent:@"r"];
        [self.actionButton.menu addItemWithTitle:@"Show Post Preview" action:@selector(actionPressed:) keyEquivalent:@"u"];
        [self.actionButton.menu addItemWithTitle:@"Toggle Post Details" action:@selector(actionPressed:) keyEquivalent:@""];
    } else if (currentMainView == mainEditView) {
        [self.actionButton.menu addItemWithTitle:@"Save To Blog" action:@selector(actionPressed:) keyEquivalent:@"t"];
        [self.actionButton.menu addItemWithTitle:@"Save Draft" action:@selector(actionPressed:) keyEquivalent:@"s"];
        [self.actionButton.menu addItem:[NSMenuItem separatorItem]];
        [self.actionButton.menu addItemWithTitle:@"Show WYSIWYG Editor" action:@selector(actionPressed:) keyEquivalent:@"W"];
        [self.actionButton.menu addItemWithTitle:@"Show HTML Editor" action:@selector(actionPressed:) keyEquivalent:@"H"];
        [self.actionButton.menu addItemWithTitle:@"Show Post Preview" action:@selector(actionPressed:) keyEquivalent:@"u"];
    }
    [self.actionButton.menu adjustLineHeightFromIndex:0];
}

- (void)setupToolbarButtons {
    /*[self.goToAccountsButton setImage:[NSImage imageNamed:[NSString stringWithFormat:@"%@", [self.goToAccountsButton identifier]]]];
    [self.goToAccountsButton setAlternateImage:[NSImage imageNamed:[NSString stringWithFormat:@"%@-pressed", [self.goToAccountsButton identifier]]]];

    [self.goToPostsButton setImage:[NSImage imageNamed:[NSString stringWithFormat:@"%@", [self.goToPostsButton identifier]]]];
    [self.goToPostsButton setAlternateImage:[NSImage imageNamed:[NSString stringWithFormat:@"%@-pressed", [self.goToPostsButton identifier]]]];

    [self.goToEditorButton setImage:[NSImage imageNamed:[NSString stringWithFormat:@"%@", [self.goToEditorButton identifier]]]];
    [self.goToEditorButton setAlternateImage:[NSImage imageNamed:[NSString stringWithFormat:@"%@-pressed", [self.goToEditorButton identifier]]]];*/
    
    
    NSColor *toolbarIconColor = [NSColor darkGrayColor];
    NSColor *toolbarIconPressedColor = [NSColor blackColor];
    
    self.goToAccountsButton.image = [[NSImage imageNamed:@"769-male"] imageWithTint:toolbarIconColor];
    self.goToPostsButton.image = [[NSImage imageNamed:@"747-tag"] imageWithTint:toolbarIconColor];
    self.goToEditorButton.image = [[NSImage imageNamed:@"704-compose"] imageWithTint:toolbarIconColor];
    
    self.goToAccountsButton.alternateImage = [[NSImage imageNamed:@"769-male"] imageWithTint:toolbarIconPressedColor];
    self.goToPostsButton.alternateImage = [[NSImage imageNamed:@"747-tag"] imageWithTint:toolbarIconPressedColor];
    self.goToEditorButton.alternateImage = [[NSImage imageNamed:@"704-compose"] imageWithTint:toolbarIconPressedColor];
    
    self.actionButton.image = [[NSImage imageNamed:@"764-arrow-down"] imageWithTint:toolbarIconColor];
    self.actionButton.alternateImage = [[NSImage imageNamed:@"764-arrow-down"] imageWithTint:toolbarIconColor];
        

    [self loadActionMenu];
}

- (void)setupMainViews {
    NSRect mainRect = [mainView bounds];

    [mainAccountView setFrame:mainRect];
    [mainAccountView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [mainView addSubview:mainAccountView];
    currentMainView = mainAccountView;

    NSRect offsetRect = NSOffsetRect(mainRect, NSWidth(mainRect), 0);
    [mainPostsView setFrame:offsetRect];
    [mainPostsView setHidden:YES];
    [mainView addSubview:mainPostsView];

    [mainEditView setFrame:offsetRect];
    [mainEditView setHidden:YES];
    [mainView addSubview:mainEditView];
}

- (void)postSelectionWillChange:(NSNotification *)notification {
    [self showUnsavedDocumentAlertWithContext:@{@"action":@"selection", @"row":notification.object}];
}

- (void)transitiontoView:(NSView *)newView animate:(NSNumber *)animate {
	if (currentMainView == newView)
        return;
    if (newView == mainEditView) {
        NSString *editor = [[NSUserDefaults standardUserDefaults] stringForKey:@"editor"];
        if ([editor isEqualToString:@"html"]) {
            [editController showEditor:self.showHTMLMenuItem];
        } else {
            [editController showEditor:self.showWYSIWYGMenuItem];
        }
    }
    if (mainWindow.isDocumentEdited) {
        [self showUnsavedDocumentAlertWithContext:@{@"action":@"transition", @"view":newView}];
        return;
    }

    BOOL shouldAnimate = [animate boolValue];
    NSRect mainRect = [mainView bounds];
    NSRect oldRect, newRect;
    if (currentMainView == mainAccountView) {
        oldRect = NSOffsetRect(mainRect, -NSWidth(mainRect), 0);
        newRect = NSOffsetRect(mainRect, NSWidth(mainRect), 0);
    } else if (currentMainView == mainPostsView && newView == mainAccountView) {
        oldRect = NSOffsetRect(mainRect, NSWidth(mainRect), 0);
        newRect = NSOffsetRect(mainRect, -NSWidth(mainRect), 0);
    } else if (currentMainView == mainPostsView && newView == mainEditView) {
        oldRect = NSOffsetRect(mainRect, -NSWidth(mainRect), 0);
        newRect = NSOffsetRect(mainRect, NSWidth(mainRect), 0);
    } else if (currentMainView == mainEditView) {
        oldRect = NSOffsetRect(mainRect, NSWidth(mainRect), 0);
        newRect = NSOffsetRect(mainRect, -NSWidth(mainRect), 0);
    }

    [newView setFrame:newRect];
    [newView setHidden:NO];

    [NSAnimationContext beginGrouping];
    if (shouldAnimate)
        [[NSAnimationContext currentContext] setDuration:0.25f];
    else
        [[NSAnimationContext currentContext] setDuration:0.0f];
    [[NSAnimationContext currentContext] setCompletionHandler:^{
        [currentMainView setHidden:YES];
        [newView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
        currentMainView = newView;
        [self loadActionMenu];
        [self setupToolbarButtons];
        [self resetEnabledControls];
        if (currentMainView == mainPostsView) {
            [postsController.postsOutlineView reloadItem:nil reloadChildren:YES];
            [self postSelectionChanged:nil];
        }
        if (currentMainView == mainEditView) {
            
        }
    }];

    [[currentMainView animator] setFrame:oldRect];
    [[newView animator] setFrame:mainRect];
    [NSAnimationContext endGrouping];
}

- (IBAction)gotoMainView:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MainViewWillTransitionNotification" object:self];
    if ([sender tag] == 1)
        [self transitiontoView:mainAccountView animate:@(YES)];
    if ([sender tag] == 2)
        [self transitiontoView:mainPostsView animate:@(YES)];
    if ([sender tag] == 3)
        [self transitiontoView:mainEditView animate:@(YES)];
}

- (IBAction)selectTab:(id)sender {
    [self gotoMainView:sender];
}

- (void)newPostCreated:(NSNotification *)notification {
    [self gotoMainView:self.goToPostsButton];
}

#pragma mark -
#pragma mark Action

- (IBAction)actionPressed:(id)sender {
    if ([[sender title] isEqualToString:@"Load Posts"]) {
        [self refreshAndGoToPosts:nil];
    }
    if ([[sender title] isEqualToString:@"Toggle Post Details"]) {
        [postsController togglePostInfoSidebar:nil];
    }
    if ([[sender title] isEqualToString:@"Reload Posts"]) {
        [accountsController refreshSelectedBlog];
    }
    if ([[sender title] isEqualToString:@"Save To Blog"]) {
        [postsController commitPost:nil];
    }
    if ([[sender title] isEqualToString:@"Show WYSIWYG Editor"]) {
        [editController showEditor:sender];
    }
    if ([[sender title] isEqualToString:@"Show HTML Editor"]) {
        [editController showEditor:sender];
    }
    if ([[sender title] isEqualToString:@"Save Draft"]) {
        [dataManager saveDraft:nil];
    }
    if ([[sender title] isEqualToString:@"New Post"]) {
        [postsController newPost:nil];
    }
    if ([[sender title] isEqualToString:@"Delete Post…"]) {
        [postsController deletePost:nil];
    }
    if ([[sender title] isEqualToString:@"Show Post Preview"]) {
        [editController showPreview:nil];
    }
}

@end
