//
//  EditController.m
//  Blog Creature
//
//  Created by Daniel Weber on 9/16/12.
//
//

#import "EditController.h"
#import "LSColorPopUpButton.h"
#import "NSColor+Hex.h"
#import "RegexKitLite.h"
#import "DataManager.h"
#import "XMLRPCManager.h"
#import "PostsController.h"
#import "AccountsController.h"
#import "DraftsTableViewDelegate.h"
#import "MediaController.h"
#import "LSDocument.h"
#import "INAppStoreWindow.h"
#import "NSAlert+SynchronousSheet.h"
#import "AFHTTPRequestOperation.h"
#import "RegexKitLite.h"
#import "NSString+HTML.h"
#import "NSMenu+Utils.h"
#import <ACEView/ACEView.h>
#import <ACEView/ACEThemeNames.h>
#import <WebKit/WebKit.h>
#include <stdio.h>
#include <errno.h>
#include "tidy.h"
#include "buffio.h"


@implementation EditController

- (void)start {
    [self setupFontMenu];
    [self drawButtonImages];
    [self setupEditor];

    [self.webView setFrameLoadDelegate:self];
    [self.webView setEditingDelegate:self];
    [self.webView setDownloadDelegate:self];
    [self.webView setUIDelegate:self.webView];
    [self.webView setPolicyDelegate:self];
    [self.webView setEditable:YES];
    [self.webView setDrawsBackground:NO];
    
    [self.previewWebView setFrameLoadDelegate:self];
    [self.previewWebView setPolicyDelegate:self];
    [self.previewWebView setResourceLoadDelegate:self];
    self.failedResources = [NSMutableArray array];
    
    self.previewWindow.titleBarHeight = 30.0;
    self.previewWindow.showsTitle = NO;
    
    NSString *title = @"Preview";
    NSDictionary *attrs = @{NSFontAttributeName: [NSFont fontWithName:@"Helvetica" size:15.0], NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:0.2 alpha:1.0]};
    CGSize size = [title sizeWithAttributes:attrs];
    NSView *titleBarView = [self.previewWindow titleBarView];
    NSTextField *titleField = [[[NSTextField alloc] initWithFrame:NSMakeRect(NSMidX(titleBarView.bounds) - 0.5*size.width, NSMidY(titleBarView.bounds) - 0.5*size.height, size.width, size.height)] autorelease];
    [titleField setAttributedStringValue:[[[NSAttributedString alloc] initWithString:title attributes:attrs] autorelease]];
    [titleField setDrawsBackground:NO];
    [titleField setBezeled:NO];
    [titleField setEditable:NO];
    [titleField setSelectable:NO];
    [titleField sizeToFit];
    [titleField setAutoresizingMask:NSViewMinXMargin|NSViewMaxXMargin];
    [[self.previewWindow titleBarView] addSubview:titleField];
    
    self.previewWindow.titleBarEndColor = [NSColor colorWithCalibratedWhite:247/255.f alpha:1.0];
    self.previewWindow.titleBarStartColor = [NSColor colorWithCalibratedWhite:232/255.f alpha:1.0];
    self.previewWindow.baselineSeparatorColor = [NSColor colorWithCalibratedWhite:194/255.f alpha:1.0];
    self.previewWindow.inactiveTitleBarEndColor = [NSColor colorWithCalibratedWhite:247/255.f alpha:1.0];
    self.previewWindow.inactiveTitleBarStartColor = [NSColor colorWithCalibratedWhite:232/255.f alpha:1.0];
    self.previewWindow.inactiveBaselineSeparatorColor = [NSColor colorWithCalibratedWhite:194/255.f alpha:1.0];

    [self.fontPopUpButton setAction:@selector(editButtonPressed:)];
    [self.fontPopUpButton setTarget:self];
    [self.styleSegmentedControl setAction:@selector(editButtonPressed:)];
    [self.styleSegmentedControl setTarget:self];
    [self.colorPopUpButton setAction:@selector(editButtonPressed:)];
    [self.colorPopUpButton setTarget:self];
    [self.clearSegmentedControl setAction:@selector(editButtonPressed:)];
    [self.clearSegmentedControl setTarget:self];
    [self.alignmentSegmentedControl setAction:@selector(editButtonPressed:)];
    [self.alignmentSegmentedControl setTarget:self];
    [self.floatSegmentedControl setAction:@selector(editButtonPressed:)];
    [self.floatSegmentedControl setTarget:self];
    [self.formatPopUpButton setAction:@selector(editButtonPressed:)];
    [self.formatPopUpButton setTarget:self];
    [self.listPopUpButton setAction:@selector(editButtonPressed:)];
    [self.listPopUpButton setTarget:self];
    [self.insertPopUpButton setAction:@selector(editButtonPressed:)];
    [self.insertPopUpButton setTarget:self];

    [draftsTableViewDelegate.draftsTableView setTarget:self];
    [draftsTableViewDelegate.draftsTableView setDoubleAction:@selector(closeSheet:)];
}

- (void)stop {
    self.html = nil;
    self.tmpFile = nil;
    self.failedResources = nil;
}

- (void)setWebViewEnabled:(BOOL)isEnabled {
    [self.webView setEditable:isEnabled];
}

- (void)setEditorOptions {
    [self.aceEditor setDelegate:self];
    [self.aceEditor setMode:ACEModeHTML];
    [self.aceEditor setTheme:[self.htmlEditorThemePopUpButton indexOfSelectedItem]-1];
    [self.aceEditor setUseSoftWrap:YES];
    [self.aceEditor setHighlightActiveLine:NO];
    [self.aceEditor setHighlightGutterLine:NO];
    [self.aceEditor performSelector:@selector(executeScriptWhenLoaded:) withObject:@"editor.setShowPrintMargin(false);"];
}

- (void)activate {
    // WordPress's online editor doesn't use paragraph tags -- it uses double returns.
    // Replace double returns with paragraph tags.
    if ([self.html rangeOfString:@"\n\n"].location != NSNotFound) {
        NSArray *paragraphs = [self.html componentsSeparatedByString:@"\n\n"];
        NSMutableString *result = [NSMutableString stringWithString:@""];
        for (NSString *p in paragraphs) {
            if (p.length != 0)
                [result appendFormat:@"<p>%@</p>", p];
        }
        self.html = result;
    }
    
    // Ensure the ACEView editor is set up correctly. Set mode, theme, other options.
    [self setEditorOptions];
    
    self.ignoreHTMLEditorStringChange = YES;
    [self.aceEditor setString:self.html];
    [self loadPost];
}

#pragma mark -

- (void)updatePreview {
    if (self.previewWindow.isVisible) {
        WebScriptObject *windowObject = self.previewWebView.windowScriptObject;
        [windowObject setValue:self.html forKey:@"postHTML"];
        [windowObject setValue:postsController.selectedDocumentTitle forKey:@"postTitle"];
        
        NSString *script = @"var nodeList = document.querySelectorAll('.entry-title');nodeList[0].innerHTML = postTitle;";
        [self.previewWebView stringByEvaluatingJavaScriptFromString:script];
        
        script = @"var nodeList = document.querySelectorAll('.entry-content');nodeList[0].innerHTML = postHTML;";
        [self.previewWebView stringByEvaluatingJavaScriptFromString:script];
    }
}

- (void)refreshPostPreview {
    if (self.previewWindow.isVisible) {
        NSString *blogHTMLPath = [dataManager blogHTMLPath];
        NSURL *url = nil;
        if ([[NSFileManager defaultManager] fileExistsAtPath:blogHTMLPath]) {
            url = [NSURL fileURLWithPath:blogHTMLPath];
        } else {
            NSString *path = [[NSBundle mainBundle] pathForResource:@"preview" ofType:@"html"];
            url = [NSURL fileURLWithPath:path];
        }
        [self.failedResources removeAllObjects];
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [[self.previewWebView mainFrame] loadRequest:request];
    }
}

- (IBAction)loadBlogTheme:(id)sender {
    self.isThemeFirstLoad = YES;

    [[NSFileManager defaultManager] removeItemAtPath:dataManager.blogHTMLPath error:nil];

    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:postsController.selectedDocument.link]];
    AFHTTPRequestOperation *operation = [[[AFHTTPRequestOperation alloc] initWithRequest:request] autorelease];
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:[dataManager blogHTMLPath] append:NO];
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self refreshPostPreview];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        // Deal with failure
        NSLog(@"%@", error.localizedDescription);
    }];
    [operation start];
}

- (IBAction)removeTheme:(id)sender {
    NSString *path = [dataManager blogHTMLPath];
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    [self refreshPostPreview];
}

#pragma mark -

- (void)loadPost {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"index" withExtension:@"html"];
    
	NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10.0];
	[[self.webView mainFrame] loadRequest:request];
}

- (void)updatePost {
    WebScriptObject *windowObject = self.webView.windowScriptObject;
    [windowObject setValue:[self replaceMoreTags:self.html] forKey:@"postHTML"];
    [self.webView stringByEvaluatingJavaScriptFromString:@"loadPost()"];
}

- (BOOL)webView:(WebView *)webView shouldInsertText:(NSString *)text replacingDOMRange:(DOMRange *)range givenAction:(WebViewInsertAction)action {
    if ([text isEqualToString:@"\t"]) {
        [self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.execCommand('insertHTML', false, '%@');", @"&nbsp;"]];
        return NO;
    }
    return YES;
}

- (void)textDidChange:(NSNotification *)notification {
    if ([notification object] == self.aceEditor) {
        if (self.ignoreHTMLEditorStringChange) {
            self.ignoreHTMLEditorStringChange = NO;
        } else {
            //[NSObject cancelPreviousPerformRequestsWithTarget:self];
            [self.mainWindow setDocumentEdited:YES];
            
            self.html = [self.aceEditor string];
            [self updatePreview];
            [self updatePost];
            //[self performSelector:@selector(loadPost) withObject:nil afterDelay:1.0];
        }
    }
}

- (void)webViewDidChange:(NSNotification *)notification {
    if (self.editorMode == EditorWYSIWYGMode) {
        [self.mainWindow setDocumentEdited:YES];

        NSString *html = [self.webView stringByEvaluatingJavaScriptFromString:@"document.body.innerHTML"];
        self.html = [self restoreMoreTags:html];

        self.ignoreHTMLEditorStringChange = YES;
        [self.aceEditor setString:self.html];
        [self updatePreview];
        
        [self.webView performSelector:@selector(updateOverlays)];
    }
}

- (void)moveCaretToEndOfWebView {
    DOMRange *range = [[self.webView mainFrameDocument] createRange];
    [range selectNodeContents:[self.webView mainFrameDocument]];
    [range collapse:NO];
    [self.webView setSelectedDOMRange:range affinity:NSSelectionAffinityDownstream];
}

- (void)focusHTMLEditor {
    WebView *aceWebView = [self.aceEditor subviews][1];
    [aceWebView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('textarea')[0].focus()"];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    if (sender == self.webView) {
        NSString *cssString = [dataManager cssString];
        
        DOMDocument* domDocument=[self.webView mainFrameDocument];
        DOMElement* styleElement=[domDocument createElement:@"style"];
        [styleElement setAttribute:@"type" value:@"text/css"];
        DOMText* cssText=[domDocument createTextNode:cssString];
        [styleElement appendChild:cssText];
        DOMElement* headElement=(DOMElement*)[[domDocument getElementsByTagName:@"head"] item:0];
        [headElement appendChild:styleElement];
        
        [self.webView stringByEvaluatingJavaScriptFromString:@"loadPost()"];
        [self refreshPostPreview];
        [self moveCaretToEndOfWebView];
    } else if (sender == self.previewWebView) {
        if (self.isThemeFirstLoad && [[NSFileManager defaultManager] fileExistsAtPath:dataManager.blogHTMLPath]) {
            self.isThemeFirstLoad = NO;
            
            NSString *script = @"jQuery('.entry-title').empty();";
            [self.previewWebView stringByEvaluatingJavaScriptFromString:script];
            
            script = @"jQuery('.entry-content').empty();";
            [self.previewWebView stringByEvaluatingJavaScriptFromString:script];
            
            //script = @"jQuery('head').append('__hide_broken_images__')";
            //[self.previewWebView stringByEvaluatingJavaScriptFromString:script];
            
            
            NSString *html = [self.previewWebView stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML.replace(/\\s+/g, ' ');"];
            //html = [html stringByReplacingOccurrencesOfString:@"__hide_broken_images__" withString:@"<script>jQuery(document).ready(function(){jQuery('img').error(function(){jQuery(this).hide();});});</script>"];
                        
            [html writeToFile:dataManager.blogHTMLPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
        }
        
        NSString *script = @"var nodeList = document.querySelectorAll('.entry-title');nodeList[0].innerHTML = postTitle;";
        [self.previewWebView stringByEvaluatingJavaScriptFromString:script];
        
        script = @"var nodeList = document.querySelectorAll('.entry-content');nodeList[0].innerHTML = postHTML;";
        [self.previewWebView stringByEvaluatingJavaScriptFromString:script];
        
        script = @"var nodeList = document.querySelectorAll('img'); for(i=0; i<nodeList.length; i++) {var image = nodeList[i]; if(image.naturalWidth == 0) {image.style.display='none';}}";
        //jQuery('img').each(function(){if(this.naturalWidth==0){jQuery(this).hide();}});";
        [self.previewWebView stringByEvaluatingJavaScriptFromString:script];
        
        /*DOMDocument *domDoc = [self.previewWebView mainFrameDocument];
        DOMNodeList *images = [domDoc querySelectorAll:@"img"];
        for (int i = 0; i < images.length; i++) {
            DOMHTMLImageElement *image = (DOMHTMLImageElement *)[images item:i];
            if (image.naturalWidth == 0) {
                [domDoc removeChild:image];
            }
        }*/
    }
}

- (void)webView:(WebView *)webView didClearWindowObject:(WebScriptObject *)windowObject forFrame:(WebFrame *)frame {
    if (webView == self.webView) {
        [windowObject setValue:[self replaceMoreTags:self.html] forKey:@"postHTML"];
    }
    if (webView == self.previewWebView) {
        [windowObject setValue:self.html forKey:@"postHTML"];
        [windowObject setValue:postsController.selectedDocumentTitle forKey:@"postTitle"];
    }
}

- (BOOL)webView:(WebView *)webView doCommandBySelector:(SEL)selector {
    if (selector == @selector(changeColor:)) {
        DOMCSSStyleDeclaration *style = [self.webView styleDeclarationWithText:[NSString stringWithFormat:@"color: %@;", self.colorPopUpButton.rgbString]];
        [self.webView applyStyle:style];
        return YES;
    }
    return NO;
}

- (void)webView:(WebView *)sender resource:(id)identifier didFailLoadingWithError:(NSError *)error fromDataSource:(WebDataSource *)dataSource {
    NSString *failedURL = error.userInfo[@"NSErrorFailingURLKey"];
    [self.failedResources addObject:failedURL];
}

#pragma mark -

- (void)updateEditBarWithInfo:(NSDictionary *)userInfo {
	DOMCSSStyleDeclaration *style = [userInfo objectForKey:@"style"];

	//NSLog(@"%@", [style cssText]);

	[self.styleSegmentedControl setSelected:NO forSegment:0];
	[self.styleSegmentedControl setSelected:NO forSegment:1];
	[self.styleSegmentedControl setSelected:NO forSegment:2];
	if ([[style getPropertyValue:@"font-weight"] isEqualToString:@"bold"])
		[self.styleSegmentedControl setSelected:YES forSegment:0];
	if ([[style getPropertyValue:@"font-style"] isEqualToString:@"italic"])
		[self.styleSegmentedControl setSelected:YES forSegment:1];
	if ([[style getPropertyValue:@"text-decoration"] isEqualToString:@"line-through"])
		[self.styleSegmentedControl setSelected:YES forSegment:2];

	NSString *fontFamily = [style getPropertyValue:@"font-family"];
	fontFamily = [fontFamily stringByReplacingOccurrencesOfString:@"'" withString:@""];
    fontFamily = [fontFamily stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    for (NSInteger i = [self.fontPopUpButton numberOfItems] - 1; i >= 0; i--) {
        if ([[self.fontPopUpButton itemAtIndex:i] tag] == -1)
            [self.fontPopUpButton removeItemAtIndex:i];
    }
    if ([[self.fontPopUpButton itemTitles] containsObject:fontFamily]) {
        [self.fontPopUpButton selectItemWithTitle:fontFamily];
    } else {
        [self.fontPopUpButton insertItemWithTitle:fontFamily atIndex:0];
        [[self.fontPopUpButton itemAtIndex:0] setTag:-1];
        [[self.fontPopUpButton menu] insertItem:[NSMenuItem separatorItem] atIndex:1];
        [[self.fontPopUpButton itemAtIndex:1] setTag:-1];
        [self.fontPopUpButton selectItemAtIndex:0];
    }

	NSString *blockElement = [userInfo objectForKey:@"blockElement"];
	[self.formatPopUpButton selectItemWithTitle:blockElement];

    [self.colorPopUpButton selectRGBColorString:[style getPropertyValue:@"color"]];

	[self.alignmentSegmentedControl setSelected:NO forSegment:0];
	[self.alignmentSegmentedControl setSelected:NO forSegment:1];
	[self.alignmentSegmentedControl setSelected:NO forSegment:2];
	if ([[style getPropertyValue:@"text-align"] isEqualToString:@"left"] || [[style getPropertyValue:@"text-align"] isEqualToString:@"-webkit-auto"])
		[self.alignmentSegmentedControl setSelected:YES forSegment:0];
	if ([[style getPropertyValue:@"text-align"] isEqualToString:@"center"])
		[self.alignmentSegmentedControl setSelected:YES forSegment:1];
	if ([[style getPropertyValue:@"text-align"] isEqualToString:@"right"])
		[self.alignmentSegmentedControl setSelected:YES forSegment:2];

	/*[self.editVerticalAlignmentControl setSelected:NO forSegment:0];
     [self.editVerticalAlignmentControl setSelected:NO forSegment:1];
     if ([[style getPropertyValue:@"vertical-align"] isEqualToString:@"super"])
     [self.editVerticalAlignmentControl setSelected:YES forSegment:0];
     if ([[style getPropertyValue:@"vertical-align"] isEqualToString:@"sub"])
     [self.editVerticalAlignmentControl setSelected:YES forSegment:1];*/

	[self.floatSegmentedControl setSelected:NO forSegment:0];
	[self.floatSegmentedControl setSelected:NO forSegment:1];
	if ([[style getPropertyValue:@"float"] isEqualToString:@"left"])
		[self.floatSegmentedControl setSelected:YES forSegment:0];
	if ([[style getPropertyValue:@"float"] isEqualToString:@"right"])
		[self.floatSegmentedControl setSelected:YES forSegment:1];

    [self.fontPopUpButton.menu adjustLineHeightFromIndex:0];
    [self.colorPopUpButton.menu adjustLineHeightFromIndex:1];
    [self.formatPopUpButton.menu adjustLineHeightFromIndex:0];
    [self.listPopUpButton.menu adjustLineHeightFromIndex:1];
    [self.insertPopUpButton.menu adjustLineHeightFromIndex:1];
}

- (IBAction)editButtonPressed:(id)sender {
	NSMutableString *styleString = [NSMutableString stringWithString:@""];

	if (sender == self.styleSegmentedControl) {
		if ([self.styleSegmentedControl isSelectedForSegment:0])
			[styleString appendString:@"font-weight: bold;"];
		else
			[styleString appendString:@"font-weight: normal;"];
		if ([self.styleSegmentedControl isSelectedForSegment:1])
			[styleString appendString:@"font-style: italic;"];
		else
			[styleString appendString:@"font-style: normal;"];
		if ([self.styleSegmentedControl isSelectedForSegment:2])
			[styleString appendString:@"text-decoration: line-through;"];
		else
			[styleString appendString:@"text-decoration: none;"];
	}

	if (sender == self.fontPopUpButton) {
        NSString *fontFamily = [sender titleOfSelectedItem];
		[styleString appendString:[NSString stringWithFormat:@"font-family: '%@';", fontFamily]];
	}

	if (sender == self.colorPopUpButton) {
        //NSColorPanel *colorPanel = [NSColorPanel sharedColorPanel];
        //[colorPanel setColor:[self.colorPopUpButton selectedColor]];
        [self.webView changeColor:nil];
	}

	if (sender == self.alignmentSegmentedControl) {
		if ([self.alignmentSegmentedControl isSelectedForSegment:0])
			[styleString appendString:@"text-align: left;"];
		if ([self.alignmentSegmentedControl isSelectedForSegment:1])
			[styleString appendString:@"text-align: center;"];
		if ([self.alignmentSegmentedControl isSelectedForSegment:2])
			[styleString appendString:@"text-align: right;"];
	}

	if (sender == self.floatSegmentedControl) {
		if ([sender selectedSegment] == 0 && [self.floatSegmentedControl isSelectedForSegment:0]) {
			[self.floatSegmentedControl setSelected:NO forSegment:1];
			[styleString appendString:@"float: left;"];
		} else if ([sender selectedSegment] == 1 && [self.floatSegmentedControl isSelectedForSegment:1]) {
			[self.floatSegmentedControl setSelected:NO forSegment:0];
			[styleString appendString:@"float: right;"];
		} else {
			[self.floatSegmentedControl setSelected:NO forSegment:0];
			[self.floatSegmentedControl setSelected:NO forSegment:1];
			[styleString appendString:@"float: none;"];
		}
	}

	if (sender == self.formatPopUpButton) {
		NSString *blockElement = @"";
		if ([[self.formatPopUpButton titleOfSelectedItem] isEqualToString:@"Unformatted"]) {
			DOMRange *range = [self.webView selectedDOMRange];
			DOMNode *node = [range startContainer];
			int startOffset = [range startOffset];
			DOMNode *endNode = [range endContainer];
			int endOffset = [range endOffset];
			DOMNode *parent = node;

			NSArray *blockElements = [NSArray arrayWithObjects:@"P", @"H1", @"H2", @"H3", @"H4", @"H5", @"H6", @"ADDRESS", @"PRE", @"BLOCKQUOTE", nil];

			while (parent) {
				if ([blockElements containsObject:[parent nodeName]]) {
					break;
				}
				parent = [parent parentNode];
			}
			if (parent) {
				while([parent firstChild]) {
					[[parent parentNode] insertBefore:parent.firstChild refChild:parent];
				}
				[[parent parentNode] removeChild:parent];
				DOMRange *newRange = [[self.webView mainFrameDocument] createRange];
				[newRange setStart:node offset:startOffset];
				[newRange setEnd:endNode offset:endOffset];

				[self.webView setSelectedDOMRange:newRange affinity:NSSelectionAffinityDownstream];
				return;
			}
		}
		if ([[self.formatPopUpButton titleOfSelectedItem] isEqualToString:@"Paragraph"])
			blockElement = @"p";
		else if ([[self.formatPopUpButton titleOfSelectedItem] isEqualToString:@"Heading 1"])
			blockElement = @"h1";
		else if ([[self.formatPopUpButton titleOfSelectedItem] isEqualToString:@"Heading 2"])
			blockElement = @"h2";
		else if ([[self.formatPopUpButton titleOfSelectedItem] isEqualToString:@"Heading 3"])
			blockElement = @"h3";
		else if ([[self.formatPopUpButton titleOfSelectedItem] isEqualToString:@"Heading 4"])
			blockElement = @"h4";
		else if ([[self.formatPopUpButton titleOfSelectedItem] isEqualToString:@"Heading 5"])
			blockElement = @"h5";
		else if ([[self.formatPopUpButton titleOfSelectedItem] isEqualToString:@"Heading 6"])
			blockElement = @"h6";
		else if ([[self.formatPopUpButton titleOfSelectedItem] isEqualToString:@"Address"])
			blockElement = @"address";
		else if ([[self.formatPopUpButton titleOfSelectedItem] isEqualToString:@"Preformatted"])
			blockElement = @"pre";
		else if ([[self.formatPopUpButton titleOfSelectedItem] isEqualToString:@"Blockquote"])
			blockElement = @"blockquote";

		[self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.execCommand('formatBlock', false, '%@');", blockElement]];
	}

	if (sender == self.listPopUpButton) {
		if ([self.listPopUpButton indexOfSelectedItem] == 1) {
			[self.webView stringByEvaluatingJavaScriptFromString:@"document.execCommand('insertOrderedList', false, null);"];
		} else if ([self.listPopUpButton indexOfSelectedItem] == 2) {
			[self.webView stringByEvaluatingJavaScriptFromString:@"document.execCommand('insertUnorderedList', false, null);"];
		} else if ([self.listPopUpButton indexOfSelectedItem] == 4) {
			[self.webView stringByEvaluatingJavaScriptFromString:@"document.execCommand('indent', false, null);"];
		} else if ([self.listPopUpButton indexOfSelectedItem] == 5) {
			[self.webView stringByEvaluatingJavaScriptFromString:@"document.execCommand('outdent', false, null);"];
		}
	}

	if (sender == self.clearSegmentedControl) {
		[self.webView stringByEvaluatingJavaScriptFromString:@"document.execCommand('removeFormat', false, null);"];
	}

	if (sender == self.insertPopUpButton) {
		if ([self.insertPopUpButton indexOfSelectedItem] == 1) {
			NSAlert *linkAlert = [NSAlert alertWithMessageText:@"Enter the link URL:" defaultButton:@"Create link" alternateButton:@"Cancel" otherButton:nil informativeTextWithFormat:@"Valid URLs usually start with http:// and end in .com, .net, or .org."];
			NSTextField *input = [[[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 300, 22)] autorelease];
			[[input cell] setPlaceholderString:@"http://"];
			[linkAlert setAccessoryView:input];
			[linkAlert beginSheetModalForWindow:[sender window] modalDelegate:self didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:) contextInfo:nil];
		}
        if ([self.insertPopUpButton indexOfSelectedItem] == 2) {
            [mediaController setMode:MediaPanelInsertMode];
            [mediaController showMediaPanelForWindow:[sender window]];
        }
		if ([self.insertPopUpButton indexOfSelectedItem] == 4) {
			[self.webView stringByEvaluatingJavaScriptFromString:@"document.execCommand('insertHorizontalRule', false, null);"];
		}
        if ([self.insertPopUpButton indexOfSelectedItem] == 5) {
			[self.webView stringByEvaluatingJavaScriptFromString:@"document.execCommand('insertHTML', false, '<br><div class=\"wp-more\">More</div><br>');"];
		}
	}
    
	if (![styleString isEqualToString:@""]) {
		DOMCSSStyleDeclaration *style = [self.webView styleDeclarationWithText:styleString];
		[self.webView applyStyle:style];
	}
}

- (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	NSString *urlString = [((NSTextField *)[alert accessoryView]) stringValue];
	NSURL *url = [NSURL URLWithString:urlString];
	if (url && url.scheme && url.host) {
		[self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.execCommand('createLink', false, '%@');", [url absoluteString]]];
	} else {
		//NSLog(@"URL not valid.");
	}
}

- (void)webViewDidChangeSelection:(NSNotification *)notification {
	if ([notification object] == self.webView) {
		DOMRange *range = [self.webView selectedDOMRange];
		DOMNode *node = [range startContainer];

		BOOL isImageSelected = NO;
		if (![range collapsed]) {
			if ([[node nodeName] isEqualToString:@"IMG"]) {
				isImageSelected = YES;
				[[NSNotificationCenter defaultCenter] postNotificationName:@"PostDidSelectImage" object:node];
			} else {
				DOMNodeList *children = [node childNodes];
				for (int i = [range startOffset]; i < [children length]; i++) {
					DOMNode *child = [children item:i];
					if ([[child nodeName] isEqualToString:@"IMG"]) {
						isImageSelected = YES;
						[[NSNotificationCenter defaultCenter] postNotificationName:@"PostDidSelectImage" object:child];
						break;
					}
				}
			}
		}
		if (!isImageSelected) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"PostDidNotSelectImage" object:nil];
		}

		if ([node isKindOfClass:[DOMElement class]] || [node isKindOfClass:[DOMText class]]) {
			DOMElement *element = (DOMElement *)node;
			DOMCSSStyleDeclaration *style = [self.webView computedStyleForElement:element pseudoElement:nil];

			NSString *blockElement = @"Unformatted";
			DOMNode *parent = node;
			while (parent) {
				if ([[parent nodeName] isEqualToString:@"P"])
					blockElement = @"Paragraph";
				if ([[parent nodeName] isEqualToString:@"H1"])
					blockElement = @"Heading 1";
				if ([[parent nodeName] isEqualToString:@"H2"])
					blockElement = @"Heading 2";
				if ([[parent nodeName] isEqualToString:@"H3"])
					blockElement = @"Heading 3";
				if ([[parent nodeName] isEqualToString:@"H4"])
					blockElement = @"Heading 4";
				if ([[parent nodeName] isEqualToString:@"H5"])
					blockElement = @"Heading 5";
				if ([[parent nodeName] isEqualToString:@"H6"])
					blockElement = @"Heading 6";
				if ([[parent nodeName] isEqualToString:@"ADDRESS"])
					blockElement = @"Address";
				if ([[parent nodeName] isEqualToString:@"PRE"])
					blockElement = @"Preformatted";
				if ([[parent nodeName] isEqualToString:@"BLOCKQUOTE"])
					blockElement = @"Blockquote";
				parent = [parent parentNode];
			}

			//NSLog(@"%@", [style cssText]);
			NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
			[userInfo setObject:blockElement forKey:@"blockElement"];
			[userInfo setObject:style forKey:@"style"];
			[self updateEditBarWithInfo:userInfo];
		}
	}
}

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener {
    NSUInteger actionType = [[actionInformation objectForKey:WebActionNavigationTypeKey] unsignedIntValue];
    if (actionType == WebNavigationTypeLinkClicked) {
        
    } else {
        [listener use];
    }
}

#pragma mark -

- (IBAction)showEditor:(id)sender {
    [self.showWYSIWYGMenuItem setState:NSOffState];
    [self.showHTMLMenuItem setState:NSOffState];
    if ([[sender title] isEqualToString:@"Show WYSIWYG Editor"]) {
        [[NSUserDefaults standardUserDefaults] setValue:@"wysiwyg" forKey:@"editor"];
        self.editorMode = EditorWYSIWYGMode;
        [self.editorTabView selectTabViewItemAtIndex:0];
        [self.showWYSIWYGMenuItem setState:NSOnState];
        [self moveCaretToEndOfWebView];
    } else if ([[sender title] isEqualToString:@"Show HTML Editor"]) {
        [[NSUserDefaults standardUserDefaults] setValue:@"html" forKey:@"editor"];
        self.editorMode = EditorHTMLMode;
        [self.editorTabView selectTabViewItemAtIndex:2];
        [self.showHTMLMenuItem setState:NSOnState];
        [self focusHTMLEditor];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)showPreview:(id)sender {
    [self.previewWindow makeKeyAndOrderFront:nil];
    [self refreshPostPreview];
}

- (void)setAceEditor2Mode:(ACEMode)mode {
    [self.aceEditor2 setDelegate:self];
    [self.aceEditor2 setMode:mode];
    [self.aceEditor2 setTheme:[self.htmlEditorThemePopUpButton indexOfSelectedItem]-1];
    [self.aceEditor2 setUseSoftWrap:YES];
    [self.aceEditor2 setHighlightActiveLine:NO];
    [self.aceEditor2 setHighlightGutterLine:NO];
    [self.aceEditor2 performSelector:@selector(executeScriptWhenLoaded:) withObject:@"editor.setShowPrintMargin(false);"];
    [self.aceEditor2 performSelector:@selector(executeScriptWhenLoaded:) withObject:@"editor.renderer.setShowGutter(false);"];
}

- (IBAction)showThemeEditor:(id)sender {
    self.editor2Mode = ACEModeHTML;
    [self setAceEditor2Mode:ACEModeHTML];
    [self.aceEditor2 setString:[dataManager blogHTMLString]];
    [NSApp beginSheet:self.aceEditor2Window modalForWindow:self.previewWindow modalDelegate:self didEndSelector:@selector(editorWindowClosed:returnCode:contextInfo:) contextInfo:nil];
    
}

- (IBAction)showCSSEditor:(id)sender {
    self.editor2Mode = ACEModeCSS;
    [self setAceEditor2Mode:ACEModeCSS];
    [self.aceEditor2 setString:[dataManager cssString]];
    [NSApp beginSheet:self.aceEditor2Window modalForWindow:self.mainWindow modalDelegate:self didEndSelector:@selector(editorWindowClosed:returnCode:contextInfo:) contextInfo:nil];
}

- (IBAction)closeEditorWindow:(id)sender {
    if ([sender tag] == 1) {
        if (self.editor2Mode == ACEModeCSS) {
            NSFileManager *fm = [NSFileManager defaultManager];
            NSString *cssString = [self.aceEditor2 string];
            NSString *blogCSSPath = [dataManager blogCSSPath];
            if (cssString.length == 0) {
                // Remove user css
                [fm removeItemAtPath:blogCSSPath error:nil];
            } else {
                [fm createDirectoryAtPath:[[dataManager appSupportFolder] stringByAppendingPathComponent:@"style"] withIntermediateDirectories:YES attributes:nil error:NULL];
                [cssString writeToFile:blogCSSPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
            }
            
            [self activate];
        } else if (self.editor2Mode == ACEModeHTML) {
            NSFileManager *fm = [NSFileManager defaultManager];
            if ([self.aceEditor2 string].length == 0) {
                [fm removeItemAtPath:dataManager.blogHTMLPath error:nil];
            } else {
                [[self.aceEditor2 string] writeToFile:dataManager.blogHTMLPath atomically:NO encoding:NSUTF8StringEncoding error:nil];
            }
            [self refreshPostPreview];
        }
    }
    [NSApp endSheet:self.aceEditor2Window];
}

- (void)editorWindowClosed:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

#pragma mark -

- (NSString *)processMarkdownString:(NSString *)str {
	NSTask *task = [[NSTask alloc] init];

	NSString *perlFile = [[NSBundle mainBundle] pathForResource:@"Markdown" ofType:@"pl"];
	[task setLaunchPath:perlFile];

	[task setStandardInput:[NSPipe pipe]];
	[task setStandardOutput:[NSPipe pipe]];

	NSFileHandle *writingHandle = [[task standardInput] fileHandleForWriting];
	[writingHandle writeData:[str dataUsingEncoding:NSUTF8StringEncoding]];
	[writingHandle closeFile];

	[task launch];
	[task waitUntilExit];

	NSData *outputData = [[[task standardOutput] fileHandleForReading] readDataToEndOfFile];
	NSString *resultString = [[[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding] autorelease];

	[task release];
    
	return resultString;
}

- (NSString *)replaceMoreTags:(NSString *)html {
    NSString *regEx = @"<!--more ?(.*?)?-->";
    html = [html stringByReplacingOccurrencesOfRegex:regEx usingBlock:^NSString *(NSInteger captureCount, NSString *const *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
        if ([capturedStrings[1] isEqualToString:@""]) {
            return @"<div class=\"wp-more\">More</div>";
        } else {
            return [NSString stringWithFormat:@"<div class=\"wp-more\">%@</div>", capturedStrings[1]];
        }
    }];
    return html;
}

- (NSString *)restoreMoreTags:(NSString *)html {
    NSString *regEx = @"<div class=\"wp-more\">(.*?)?</div>";
    html = [html stringByReplacingOccurrencesOfRegex:regEx usingBlock:^NSString *(NSInteger captureCount, NSString *const *capturedStrings, const NSRange *capturedRanges, volatile BOOL *const stop) {
        NSString *moreText = capturedStrings[1];
        moreText = [moreText stringByReplacingOccurrencesOfRegex:@"<br ?/?>" withString:@""];
        moreText = [moreText stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@""];
        moreText = [moreText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if ([moreText isEqualToString:@""] || [[moreText lowercaseString] isEqualToString:@"more"]) {
            return @"<!--more-->";
        } else {
            return [NSString stringWithFormat:@"<!--more %@-->", capturedStrings[1]];
        }
    }];
    return html;
}

#pragma mark -

- (void)setupEditor {
    [self setupTidy];
    
    [self.htmlEditorThemePopUpButton addItemsWithTitles:[ACEThemeNames humanThemeNames]];
    NSString *themeTitle = [[NSUserDefaults standardUserDefaults] stringForKey:@"editor-theme"];
    if (themeTitle) {
        [self.htmlEditorThemePopUpButton selectItemWithTitle:themeTitle];
        [[self.htmlEditorThemePopUpButton itemWithTitle:themeTitle] setState:NSOnState];
    }
}

- (void)setupFontMenu {
	[self.fontPopUpButton removeAllItems];
	NSMutableArray *fontList = [[[NSMutableArray alloc] initWithArray:[[NSFontManager sharedFontManager] availableFontFamilies]] autorelease];
	[fontList sortUsingSelector:@selector(caseInsensitiveCompare:)];

    [self.fontPopUpButton addItemWithTitle:@"Generic"];
    [[self.fontPopUpButton lastItem] setTarget:nil];
    NSArray *genericFonts = [NSArray arrayWithObjects:@"serif", @"sans-serif", @"cursive", @"fantasy", @"monospace", nil];
    for (NSString *title in genericFonts) {
        [self.fontPopUpButton addItemWithTitle:title];
        [[self.fontPopUpButton lastItem] setIndentationLevel:1];
    }

    [[self.fontPopUpButton menu] addItem:[NSMenuItem separatorItem]];

    [self.fontPopUpButton addItemWithTitle:@"My Fonts"];
    [[self.fontPopUpButton lastItem] setTarget:nil];
	for (NSString *title in fontList) {
		[self.fontPopUpButton addItemWithTitle:title];
        [[self.fontPopUpButton lastItem] setIndentationLevel:1];
	}
}

- (IBAction)themeAction:(id)sender {
    NSMenuItem *selectedItem = [self.htmlEditorThemePopUpButton selectedItem];
    [self.htmlEditorThemePopUpButton selectItem:nil];
    [self.htmlEditorThemePopUpButton selectItem:selectedItem];
    for (NSMenuItem *item in self.htmlEditorThemePopUpButton.menu.itemArray)
        [item setState:NSOffState];
    [selectedItem setState:NSOnState];
    [self.aceEditor setTheme:[self.htmlEditorThemePopUpButton indexOfSelectedItem]-1];
    [[NSUserDefaults standardUserDefaults] setValue:[self.htmlEditorThemePopUpButton titleOfSelectedItem] forKey:@"editor-theme"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)popoverDidClose:(NSNotification *)notification {
    [self.tidySegmentedControl setSelected:NO forSegment:1];
    [[NSUserDefaults standardUserDefaults] setValue:self.tidyOptionsField.stringValue forKey:@"tidy-options"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)commandSelector {
    BOOL result = NO;
    if (commandSelector == @selector(insertNewline:)) {
        [textView insertNewlineIgnoringFieldEditor:self];
        result = YES;
    }
    return result;
}

- (IBAction)tidyAction:(id)sender {
    if (self.tidySegmentedControl.selectedSegment == 0) {
        //NSLog(@"%@", [self tidyHTML:self.html]);
        [self runTidy];
    } else if (self.tidySegmentedControl.selectedSegment == 1) {
        [self.tidyPopover showRelativeToRect:NSMakeRect([self.tidySegmentedControl widthForSegment:0]+1, 0, [self.tidySegmentedControl widthForSegment:1], self.tidySegmentedControl.bounds.size.height) ofView:self.tidySegmentedControl preferredEdge:NSMinYEdge];
    }
}

-(NSAttributedString *)stringFromHTML:(NSString *)html withFont:(NSFont *)font {
    if (!font) font = [NSFont systemFontOfSize:0.0];  // Default font
    html = [NSString stringWithFormat:@"<span style=\"font-family:'%@'; font-size:%dpx;\">%@</span>", [font fontName], (int)[font pointSize], html];
    NSData *data = [html dataUsingEncoding:NSUTF8StringEncoding];
    NSAttributedString* string = [[[NSAttributedString alloc] initWithHTML:data documentAttributes:nil] autorelease];
    return string;
}

- (void)setupTidy {
    [self.tidyLinkField setAllowsEditingTextAttributes:YES];
    [self.tidyLinkField setSelectable:YES];
    NSString *credits = @"See <a href=\"http://tidy.sourceforge.net/docs/quickref.html\">the HTML Tidy website</a> for documentation.";
    [self.tidyLinkField setAttributedStringValue:[self stringFromHTML:credits withFont:[self.tidyLinkField font]]];
    
    NSString *tidyOptions = [[NSUserDefaults standardUserDefaults] stringForKey:@"tidy-options"];
    if (tidyOptions)
        [self.tidyOptionsField setStringValue:tidyOptions];
}

- (void)runTidy {
    const char *input = [self.html cStringUsingEncoding:NSUTF8StringEncoding];
    
    // Write options to temp config file
    NSString *tmpFile = dataManager.tmpFile;
    [self.tidyOptionsField.stringValue writeToFile:tmpFile atomically:NO encoding:NSASCIIStringEncoding error:nil];
    const char *configfile = [tmpFile cStringUsingEncoding:NSASCIIStringEncoding];

    // Initialize variables
    TidyBuffer errbuf = {0};
    TidyBuffer output = {0};
    TidyDoc tdoc = tidyCreate();
    int rc = 0;
    tidyBufInit(&output);
    tidyBufInit(&errbuf);
    
    if ((rc >= 0) && configfile && *configfile) {
        rc = tidyLoadConfig(tdoc, configfile);
    }
    if (rc >= 0) {
        rc = tidySetErrorBuffer(tdoc, &errbuf);  // Capture diagnostics
    }
    if (rc >= 0) {
        rc = tidyParseString(tdoc, input);   // Parse the input
    }
    if (rc >= 0) {
        rc = tidyCleanAndRepair(tdoc);
    }
    if (rc > 1) {
        rc = (tidyOptSetBool(tdoc, TidyForceOutput, yes) ? rc : -1);
    }
    if (rc >= 0) {
        rc = tidySaveBuffer(tdoc, &output);
    }
    if (rc >= 0) {
        rc = tidyRunDiagnostics(tdoc);
    }
    if (rc >= 0 && output.bp && errbuf.bp) {
        NSString *html = [NSString stringWithCString:(char *)output.bp encoding:NSUTF8StringEncoding];
        [self.tidySegmentedControl setSelected:NO forSegment:0];
        self.html = html;
        [self.aceEditor setString:html];
        [self focusHTMLEditor];
    }
    
    tidyBufFree(&output);
    tidyBufFree(&errbuf);
    tidyRelease(tdoc);
}

- (void)drawButtonImages {
    CGFloat s = 1.f;
    if ([[NSScreen mainScreen] respondsToSelector:@selector(backingScaleFactor)]) {
        //s = [NSScreen mainScreen].backingScaleFactor;
    }
    
	NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	[style setAlignment:NSCenterTextAlignment];
	NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
	[attrs setObject:style forKey:NSParagraphStyleAttributeName];
	[attrs setObject:[NSFont fontWithName:@"Menlo Bold" size:11.0] forKey:NSFontAttributeName];
	NSImage *boldImage = [[[NSImage alloc] initWithSize:NSMakeSize(18, 18)] autorelease];
	[boldImage lockFocus];
	[@"B" drawInRect:NSMakeRect(1, 1, 18, 18) withAttributes:attrs];
	[boldImage unlockFocus];
	[boldImage setTemplate:YES];
	[self.styleSegmentedControl setImage:boldImage forSegment:0];
    //[markdownStyleControl setImage:boldImage forSegment:0];

	[attrs setObject:[NSFont fontWithName:@"Menlo Bold Italic" size:11.0] forKey:NSFontAttributeName];
	NSImage *italicImage = [[[NSImage alloc] initWithSize:NSMakeSize(18, 18)] autorelease];
	[italicImage lockFocus];
	[@"I" drawInRect:NSMakeRect(0, 1, 18, 18) withAttributes:attrs];
	[italicImage unlockFocus];
	[italicImage setTemplate:YES];
	[self.styleSegmentedControl setImage:italicImage forSegment:1];
    //[markdownStyleControl setImage:italicImage forSegment:1];

	[attrs setObject:[NSNumber numberWithInteger:NSUnderlinePatternSolid | NSUnderlineStyleSingle] forKey:NSStrikethroughStyleAttributeName];
	[attrs setObject:[NSFont fontWithName:@"Menlo Bold" size:11.0] forKey:NSFontAttributeName];
	NSImage *strikethroughImage = [[[NSImage alloc] initWithSize:NSMakeSize(18, 18)] autorelease];
	[strikethroughImage lockFocus];
	[@"S" drawInRect:NSMakeRect(0, 1, 18, 18) withAttributes:attrs];
	[strikethroughImage unlockFocus];
	[strikethroughImage setTemplate:YES];
	[self.styleSegmentedControl setImage:strikethroughImage forSegment:2];
    //[markdownStyleControl setImage:strikethroughImage forSegment:2];

    NSImage *listImage = [[[NSImage alloc] initWithSize:NSMakeSize(18, 18)] autorelease];
    [listImage lockFocus];
    [[NSColor blackColor] set];

    /*NSRectFill(NSMakeRect(5*s, 5*s, listImage.size.width, 1*s));
    NSRectFill(NSMakeRect(5*s, 8*s, listImage.size.width, 1*s));
    NSRectFill(NSMakeRect(5*s, 11*s, listImage.size.width, 1*s));
    
    NSRectFill(NSMakeRect(2*s, 5*s, 2*s, 1*s));
    NSRectFill(NSMakeRect(2*s, 8*s, 2*s, 1*s));
    NSRectFill(NSMakeRect(2*s, 11*s, 2*s, 1*s));*/

    //Horizontal Lines
    NSRectFill(NSMakeRect(6*s, 5*s, listImage.size.width, 1*s));
    NSRectFill(NSMakeRect(6*s, 8*s, listImage.size.width, 1*s));
    NSRectFill(NSMakeRect(6*s, 11*s, listImage.size.width, 1*s));

    //Horizontal Bullets
    NSRectFill(NSMakeRect(2*s, 5*s, 3*s, 1*s));
    NSRectFill(NSMakeRect(2*s, 8*s, 3*s, 1*s));
    NSRectFill(NSMakeRect(2*s, 11*s, 3*s, 1*s));

    NSRectFill(NSMakeRect(3, 4, 1, 3));
    NSRectFill(NSMakeRect(3, 10, 1, 3));

    [[NSColor colorWithCalibratedWhite:0.0 alpha:0.5] set];
    NSRectFill(NSMakeRect(3, 7, 1, 1));
    NSRectFill(NSMakeRect(3, 9, 1, 1));
    //NSRectFill(NSMakeRect(3, 10, 1, 3));

    //NSRectFill(NSMakeRect(2*s, 13*s, 3*s, 1*s));
    //NSRectFill(NSMakeRect(3*s, 12*s, 1*s, 3*s));
    


    [listImage unlockFocus];
    [listImage setTemplate:YES];
    [[self.listPopUpButton itemAtIndex:0] setImage:listImage];
    //[self.styleSegmentedControl setImage:[NSImage imageNamed:@"InspectorBarListTemplate.pdf"] forSegment:0];

	/*[attrs removeObjectForKey:NSStrikethroughStyleAttributeName];
     NSDictionary *smallAttrs = [NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Menlo Bold" size:7.0] forKey:NSFontAttributeName];
     NSImage *superscriptImage = [[[NSImage alloc] initWithSize:NSMakeSize(18, 18)] autorelease];
     [superscriptImage lockFocus];
     [@"A" drawInRect:NSMakeRect(0, 1, 18, 18) withAttributes:attrs];
     [@"2" drawInRect:NSMakeRect(12, 7, 10, 10) withAttributes:smallAttrs];
     [superscriptImage unlockFocus];
     [superscriptImage setTemplate:YES];
     [self.editVerticalAlignmentControl setImage:superscriptImage forSegment:0];

     NSImage *subscriptImage = [[[NSImage alloc] initWithSize:NSMakeSize(18, 18)] autorelease];
     [subscriptImage lockFocus];
     [@"A" drawInRect:NSMakeRect(0, 1, 18, 18) withAttributes:attrs];
     [@"2" drawInRect:NSMakeRect(12, 4, 10, 10) withAttributes:smallAttrs];
     [subscriptImage unlockFocus];
     [subscriptImage setTemplate:YES];
     [self.editVerticalAlignmentControl setImage:subscriptImage forSegment:1];*/
}

@end
