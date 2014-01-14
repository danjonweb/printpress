//
//  MediaController.m
//  Blog Creature
//
//  Created by Daniel Weber on 11/11/12.
//
//

#import "MediaController.h"
#import "DataManager.h"
#import "AccountsController.h"
#import "PostsController.h"
#import "LSFeaturedImageView.h"
#import "IKBBrowserItem.h"
#import "ImageWithPathView.h"
#import "NSImage+MGCropExtensions.h"
#import "XMLRPCManager.h"
#import "EditController.h"
#import "AFHTTPRequestOperation.h"
#import <WebKit/WebKit.h>

@implementation MediaController

- (void)awakeFromNib {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadImageDidChange:) name:UploadImageDidChangeNotification object:nil];
    self.downloadQueue = [NSMutableArray array];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.downloadQueue = nil;
}

#pragma mark -

- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)aBrowser {
	return [dataManager.media count];
}

- (id)imageBrowser:(IKImageBrowserView *)aBrowser itemAtIndex:(NSUInteger)index {
	return [dataManager.media objectAtIndex:index];
}

- (void)imageBrowserSelectionDidChange:(IKImageBrowserView *)aBrowser {
    if ([[self.imageBrowserView selectionIndexes] count] == 0) {
        [self.okButton setEnabled:NO];
    } else {
        [self.okButton setEnabled:YES];
    }
}

#pragma mark -

- (void)showMediaPanelForWindow:(NSWindow *)window {
    [self.uploadImageView setImage:nil];
    [self.imageBrowserView reloadData];
    [NSApp beginSheet:self.mediaPanel modalForWindow:window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}

- (IBAction)closeMediaPanel:(id)sender {
    [NSApp endSheet:self.mediaPanel];
    [self.mediaPanel orderOut:self];

    if (sender == self.okButton) {
        IKBBrowserItem *item = [dataManager.media objectAtIndex:[[self.imageBrowserView selectionIndexes] firstIndex]];
        if (mode == MediaPanelInsertMode) {
            //[editController.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"document.execCommand('insertImage', false, '%@');", [item.URL absoluteString]]];
            DOMElement *imgElement = [editController.webView.mainFrameDocument createElement:@"img"];
            [imgElement setAttribute:@"src" value:item.fileName];
            //[imgElement setAttribute:@"style" value:@"padding-left: .5em; padding-right: .5em;"];
            DOMRange *range = [editController.webView selectedDOMRange];
            [range insertNode:imgElement];
            [editController webViewDidChange:nil];
        } else if (mode == MediaPanelChooseMode) {
            [postsController.featuredImageView setImage:item.image];
            postsController.featuredImageView.imageID = item.imageID;
            [dataManager saveDraft:nil];
        }
    }
}

#pragma mark -

- (void)setMode:(MediaPanelMode)aMode {
    if (aMode == MediaPanelInsertMode) {
        [self.okButton setTitle:@"Insert"];
    } else if (aMode == MediaPanelChooseMode) {
        [self.okButton setTitle:@"Choose"];
    }
    mode = aMode;
}

#pragma mark -

- (void)handleGetMediaLibraryResponseWithData:(id)data {
    [dataManager removeAllMedia];
    dataManager.mediaData = data;
    
    // Cache data file
    NSString *cacheFile = [[self mediaFolder] stringByAppendingPathComponent:@"Media Data.plist"];
    [dataManager.mediaData writeToFile:cacheFile atomically:NO];

    ////////////
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:cacheFile]) {
        //NSLog(@"!!!!! Media file exists at path: %@", cacheFile);
    } else {
        //NSLog(@"!!!!! Media file error at path: %@", cacheFile);
    }
    ////////////

    // Check to see if any files need to be downloaded.
    NSInteger numberOfFilesToDownload = 0;
    for (NSDictionary *mediaDict in dataManager.mediaData) {
        NSString *fileName = [[self mediaFolder] stringByAppendingPathComponent:[self fileNameForMediaObject:mediaDict]];
        ////////////
        //NSLog(@"!!!!! Media object path: %@", fileName);
        ////////////
        if (![[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
            numberOfFilesToDownload++;
            // Download the file
            //fileDownloadCount++;
            //NSString *link = mediaDict[@"link"];
            //[self startDownloadingLink:link toDestination:fileName];
        }
    }
    
    if (numberOfFilesToDownload > 0) {
        self.downloadProgressIndicator.minValue = 0;
        self.downloadProgressIndicator.maxValue = numberOfFilesToDownload;
        self.downloadProgressIndicator.doubleValue = 0;
        if (self.mainWindow.attachedSheet == nil) {
            [NSApp beginSheet:self.downloadProgressWindow modalForWindow:self.mainWindow modalDelegate:self didEndSelector:@selector(didEndSheet:returnCode:contextInfo:) contextInfo:nil];
        }
        [self.downloadQueue removeAllObjects];
        for (NSDictionary *mediaDict in dataManager.mediaData) {
            NSString *fileName = [[self mediaFolder] stringByAppendingPathComponent:[self fileNameForMediaObject:mediaDict]];
            if (![[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
                [self.downloadQueue addObject:@{@"link": mediaDict[@"link"], @"filename": fileName}];
            }
        }
        [self downloadMediaLibrary];
    } else {
        [self loadMediaLibrary];
    }
}

- (void)endDownloadSheet {
    [self loadMediaLibrary];
    [NSApp endSheet:self.downloadProgressWindow];
}

- (void)didEndSheet:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    [sheet orderOut:self];
}

- (IBAction)cancelDownload:(id)sender {
    [self.downloadQueue removeAllObjects];
}

- (void)downloadMediaLibrary {
    if (self.downloadQueue.count > 0) {
        NSString *link = [self.downloadQueue[0] objectForKey:@"link"];
        NSString *fileName = [self.downloadQueue[0] objectForKey:@"filename"];
        [self.downloadQueue removeObjectAtIndex:0];

        [self.downloadProgressIndicator incrementBy:1];
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:link] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:60.0];
        AFHTTPRequestOperation *operation = [[AFHTTPRequestOperation alloc] initWithRequest:request];
        operation.outputStream = [NSOutputStream outputStreamToFileAtPath:fileName append:NO];
        [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
            [self downloadMediaLibrary];
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            [self downloadMediaLibrary];
        }];
        [operation start];
    } else {
        [self performSelectorOnMainThread:@selector(endDownloadSheet) withObject:nil waitUntilDone:NO];
    }
}

- (NSString *)mediaFolder {
    NSString *mediaFolder = [[dataManager appSupportFolder] stringByAppendingPathComponent:@"media"];
    mediaFolder = [mediaFolder stringByAppendingPathComponent:accountsController.blogUUID];
    BOOL isDir;
    NSFileManager *fileManager= [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:mediaFolder isDirectory:&isDir] && isDir) {} else
        [fileManager createDirectoryAtPath:mediaFolder withIntermediateDirectories:YES attributes:nil error:NULL];
    return mediaFolder;
}

- (NSString *)fileNameForMediaObject:(NSDictionary *)mediaDict {
    NSString *attachmentID = mediaDict[@"attachment_id"];
    NSString *extension = [mediaDict[@"link"] pathExtension];
    return [attachmentID stringByAppendingPathExtension:extension];
}

- (void)loadMediaFromCache {
    NSString *cacheFile = [[self mediaFolder] stringByAppendingPathComponent:@"Media Data.plist"];
    dataManager.mediaData = [NSMutableArray arrayWithContentsOfFile:cacheFile];
    [self loadMediaLibrary];
}

- (void)loadMediaLibrary {
    for (NSDictionary *mediaDict in dataManager.mediaData) {
        NSString *fileName = [[self mediaFolder] stringByAppendingPathComponent:[self fileNameForMediaObject:mediaDict]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:fileName] && [[self imageExtensions] containsObject:fileName.pathExtension]) {
            IKBBrowserItem *item = [IKBBrowserItem browserItem];
            item.image = [[NSImage alloc] initWithContentsOfFile:fileName];
            item.imageID = [mediaDict objectForKey:@"attachment_id"];
            item.title = [mediaDict objectForKey:@"title"];
            item.URL = [NSURL URLWithString:[mediaDict objectForKey:@"link"]];
            item.fileName = fileName;
            if (![dataManager.media containsObject:item])
                [dataManager addMediaItem:item];
        }
    }
    [self.imageBrowserView reloadData];
}

- (IBAction)reloadMediaLibrary:(id)sender {
    NSString *mediaFolder = [self mediaFolder];
    NSFileManager *fm = [[NSFileManager alloc] init];
    NSDirectoryEnumerator *en = [fm enumeratorAtPath:mediaFolder];
    NSError *err = nil;
    BOOL res;
    
    NSString *file;
    while (file = [en nextObject]) {
        res = [fm removeItemAtPath:[mediaFolder stringByAppendingPathComponent:file] error:&err];
        if (!res && err) {
            NSLog(@"Cannot remove file: %@", err.localizedDescription);
        }
    }
    
    [xmlrpcManager queueXMLRPCRequestUsingMethod:@"wp.getMediaLibrary" withParameters:@[accountsController.blogID, accountsController.username, accountsController.password]];
    [xmlrpcManager startProcessingQueue];
}

#pragma mark -

- (void)handleUploadFileResponseWithData:(id)data {
    if (data) {
        IKBBrowserItem *item = [IKBBrowserItem browserItem];
        item.image = [self.uploadImageView image];
        item.imageID = [data objectForKey:@"id"];
        item.title = [data objectForKey:@"file"];
        item.URL = [NSURL URLWithString:[data objectForKey:@"url"]];

        [dataManager addMediaItem:item];
        [self.imageBrowserView reloadData];

        [self.uploadImageView setImage:nil];
    }
}

- (NSString *)mimeTypeForFile:(NSString *)file {
    if (!file || [file length] == 0)
        return nil;
    NSString *ext = [file pathExtension];
    if (!ext || [ext length] == 0)
        return nil;
    ext = [ext lowercaseString];
    NSString *mimeType = nil;
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge  CFStringRef)ext, NULL);
    if(!UTI)
        return nil;
    CFStringRef registeredType = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    if(!registeredType) {
        // check for edge case
        if([ext isEqualToString:@"m4v"])
            mimeType = @"video/x-m4v";
        else if([ext isEqualToString:@"m4p"])
            mimeType = @"audio/x-m4p";
    } else {
        mimeType = (__bridge  NSString *)registeredType;
    }
    CFRelease(UTI);
    return mimeType;
}

- (NSBitmapImageFileType)fileTypeForFile:(NSString *)file {
    if (!file || [file length] == 0)
        return 0;
    NSString *ext = [file pathExtension];
    if (!ext || [ext length] == 0)
        return 0;
    ext = [ext lowercaseString];

    if ([ext isEqualToString:@"png"])
        return NSPNGFileType;
    else if ([ext isEqualToString:@"gif"])
        return NSGIFFileType;
    else if ([ext isEqualToString:@"jpg"] || [ext isEqualToString:@"jpeg"])
        return NSJPEGFileType;
    else
        return NSTIFFFileType;
}

- (NSArray *)imageExtensions {
    return @[@"jpg", @"jpeg", @"png", @"gif"];
}

- (void)uploadImageDidChange:(NSNotification *)notification {
    // Reset
    [self.uploadFileNameField setStringValue:@""];
    [self.uploadDocumentTypePopUpButton selectItemAtIndex:-1];
    [self.uploadDocumentTypePopUpButton setEnabled:NO];
    [self.uploadFileSizeField setStringValue:@""];
    [self.uploadImageSizePopUpButton selectItemAtIndex:-1];
    [self.uploadImageSizePopUpButton setEnabled:NO];
    [self.uploadImageWidthField setStringValue:@""];
    [self.uploadImageWidthField setEnabled:NO];
    [self.uploadImageHeightField setStringValue:@""];
    [self.uploadImageHeightField setEnabled:NO];
    [self.uploadImageQualitySlider setEnabled:NO];
    [self.uploadImageButton setEnabled:NO];

    NSImage *image = [notification object];
    NSString *filePath = [image name];
    if (!image || !filePath)
        return;
    NSString *extension = [[filePath pathExtension] lowercaseString];

    [self.uploadFileNameField setStringValue:[filePath lastPathComponent]];

    unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
    NSString *fileSizeString;
    if (fileSize >= 1024 * 1024 * 1024)
        fileSizeString = [NSString stringWithFormat:@"%.2f GB", fileSize / (1024.f * 1024.f * 1024.f)];
    else if (fileSize >= 1024 * 1024)
        fileSizeString = [NSString stringWithFormat:@"%.2f MB", fileSize / (1024.f * 1024.f)];
    else if (fileSize >= 1024)
        fileSizeString = [NSString stringWithFormat:@"%.1f KB", fileSize / (1024.f)];
    else
        fileSizeString = [NSString stringWithFormat:@"%llu B", fileSize];
    [self.uploadFileSizeField setStringValue:fileSizeString];

    [self.uploadDocumentTypePopUpButton removeAllItems];
    if ([[self imageExtensions] containsObject:extension]) {
        if ([extension isEqualToString:@"jpeg"])
            extension = @"jpg";

        [self.uploadDocumentTypePopUpButton setEnabled:YES];
        for (NSString *type in [self imageExtensions]) {
            if (![type isEqualToString:@"jpeg"]) {
                [self.uploadDocumentTypePopUpButton addItemWithTitle:[type uppercaseString]];
            }
        }
        [self.uploadDocumentTypePopUpButton selectItemWithTitle:[extension uppercaseString]];

        [self.uploadImageSizePopUpButton selectItemWithTitle:@"Medium"];
        [self.uploadImageSizePopUpButton setEnabled:YES];
        //[self.uploadImageWidthField setIntegerValue:[image size].width];
        //[self.uploadImageHeightField setIntegerValue:[image size].height];
        //[self.uploadImageWidthField setEnabled:YES];
        //[self.uploadImageHeightField setEnabled:YES];
        [self imageSizeDidChange:nil];

        [self imageTypeDidChange:nil];

        [self.uploadImageButton setEnabled:YES];
    }

}

- (CGSize)originalImageSize {
    NSImage *image = [self.uploadImageView image];
    return NSMakeSize(image.size.width, image.size.height);
}

- (CGFloat)imageRatio {
    NSSize imageSize = [self originalImageSize];
    return imageSize.width / imageSize.height;
}

- (CGFloat)maximumImageLength {
    // Returns 0 if custom size should be used. Returns -1 if original size should be used.
    CGFloat ratio = [self imageRatio];
    CGFloat maxLength = -1;
    if ([[self.uploadImageSizePopUpButton titleOfSelectedItem] isEqualToString:@"X-Small"])
        maxLength = ratio >= 1 ? 320 : 240;
    if ([[self.uploadImageSizePopUpButton titleOfSelectedItem] isEqualToString:@"Small"])
        maxLength = ratio >= 1 ? 640 : 480;
    if ([[self.uploadImageSizePopUpButton titleOfSelectedItem] isEqualToString:@"Medium"])
        maxLength = ratio >= 1 ? 800 : 600;
    if ([[self.uploadImageSizePopUpButton titleOfSelectedItem] isEqualToString:@"Large"])
        maxLength = ratio >= 1 ? 1024 : 768;
    if ([[self.uploadImageSizePopUpButton titleOfSelectedItem] isEqualToString:@"X-Large"])
        maxLength = ratio >= 1 ? 1280 : 1024;
    if ([[self.uploadImageSizePopUpButton titleOfSelectedItem] isEqualToString:@"Custom"])
        maxLength = 0;
    return maxLength;
}

- (CGSize)optimizedImageSize {
    CGSize originalSize = [self originalImageSize];
    CGFloat maxLength = [self maximumImageLength];
    CGFloat ratio = [self imageRatio];
    NSSize newSize = NSZeroSize;
    if (maxLength > 0) {
        // A preset is selected
        if (ratio >= 1) {
            // Horizontal image
            if (maxLength <= originalSize.width) {
                newSize.width = (NSInteger)maxLength;
                newSize.height = (NSInteger)(newSize.width / ratio);
            }
        } else {
            // Vertical image
            if (maxLength <= originalSize.height) {
                newSize.height = (NSInteger)maxLength;
                newSize.width = (NSInteger)(newSize.height * ratio);
            }
        }
        if (NSEqualSizes(newSize, NSZeroSize)) {
            // Image was smaller than preset, so just keep original dimensions.
            newSize = originalSize;
        }
    } else if (maxLength == 0) {
        // Use custom size
        newSize = NSMakeSize([self.uploadImageWidthField integerValue], [self.uploadImageHeightField integerValue]);
    } else {
        // Use original size
        newSize = originalSize;
    }
    return newSize;
}

/*- (void)updateSizeField {
    NSSize newSize = [self optimizedImageSize];
    [self.uploadImageSizeField setStringValue:[NSString stringWithFormat:@"%lu × %lu", (NSInteger)newSize.width, (NSInteger)newSize.height]];
}*/

- (void)controlTextDidChange:(NSNotification *)notification {
    CGFloat ratio = [self imageRatio];
    BOOL customSizeDidChange = NO;
    if ([notification object] == self.uploadImageWidthField) {
        [self.uploadImageHeightField setIntegerValue:[self.uploadImageWidthField floatValue] / ratio];
        customSizeDidChange = YES;
    } else if ([notification object] == self.uploadImageHeightField) {
        [self.uploadImageWidthField setIntegerValue:[self.uploadImageHeightField floatValue] * ratio];
        customSizeDidChange = YES;
    }
    if (customSizeDidChange) {
        //[self.uploadImageSizePopUpButton selectItemWithTitle:@"Custom"];
        //[self imageSizeDidChange:nil];
    }
}

- (IBAction)imageTypeDidChange:(id)sender {
    NSString *extension = [self.uploadDocumentTypePopUpButton titleOfSelectedItem];
    if ([extension isEqualToString:@"JPG"]) {
        [self.uploadImageQualitySlider setFloatValue:0.85];
        [self.uploadImageQualitySlider setEnabled:YES];
    } else {
        [self.uploadImageQualitySlider setFloatValue:1.0];
        [self.uploadImageQualitySlider setEnabled:NO];
    }
}

- (IBAction)imageSizeDidChange:(id)sender {
    //[self updateSizeField];
    if ([[self.uploadImageSizePopUpButton titleOfSelectedItem] isEqualToString:@"Custom"]) {
        NSSize size = [self originalImageSize];
        [self.uploadImageWidthField setIntegerValue:size.width];
        [self.uploadImageHeightField setIntegerValue:size.height];
        [self.uploadImageWidthField setEnabled:YES];
        [self.uploadImageHeightField setEnabled:YES];
    } else {
        NSSize size = [self optimizedImageSize];
        [self.uploadImageWidthField setIntegerValue:size.width];
        [self.uploadImageHeightField setIntegerValue:size.height];
        [self.uploadImageWidthField setEnabled:NO];
        [self.uploadImageHeightField setEnabled:NO];
    }
}

- (IBAction)uploadImage:(id)sender {
    NSImage *image = [self.uploadImageView image];
    NSMutableDictionary *imageDict = [NSMutableDictionary dictionary];
    
    NSString *imageName = [self.uploadFileNameField stringValue];
    
    if ([self.uploadImageSizePopUpButton.titleOfSelectedItem isEqualToString:@"Original"]) {
        [imageDict setObject:imageName forKey:@"name"];
        [imageDict setObject:[self mimeTypeForFile:imageName] forKey:@"type"];
        [imageDict setObject:[NSNumber numberWithBool:NO] forKey:@"overwrite"];
        NSData *data = [[NSData alloc] initWithContentsOfFile:self.uploadImageView.filePath];
        [imageDict setObject:data forKey:@"bits"];
    } else {
        imageName = [imageName stringByDeletingPathExtension];
        imageName = [imageName stringByAppendingPathExtension:[[self.uploadDocumentTypePopUpButton titleOfSelectedItem] lowercaseString]];
        NSBitmapImageRep *imageRep = nil;
        
        CGSize newSize = [self optimizedImageSize];
        NSImage *newImage = [[NSImage alloc] initWithSize:newSize];
        [newImage lockFocus];
        [image drawInRect:NSMakeRect(0, 0, newSize.width, newSize.height) operation:NSCompositeSourceOver fraction:1.0 method:MGImageResizeCrop];
        [newImage unlockFocus];
        imageRep = [NSBitmapImageRep imageRepWithData:[newImage TIFFRepresentation]];
        
        [imageDict setObject:imageName forKey:@"name"];
        [imageDict setObject:[self mimeTypeForFile:imageName] forKey:@"type"];
        [imageDict setObject:[NSNumber numberWithBool:NO] forKey:@"overwrite"];
        
        NSData *data = [imageRep representationUsingType:[self fileTypeForFile:imageName] properties:[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:[self.uploadImageQualitySlider floatValue]] forKey:NSImageCompressionFactor]];
        [imageDict setObject:data forKey:@"bits"];
    }

    [xmlrpcManager queueXMLRPCRequestUsingMethod:@"wp.uploadFile" withParameters:@[accountsController.blogID, accountsController.username, accountsController.password, imageDict]];
    [xmlrpcManager queueXMLRPCRequestUsingMethod:@"wp.getMediaLibrary" withParameters:@[accountsController.blogID, accountsController.username, accountsController.password]];
    
    [xmlrpcManager startProcessingQueue];
}

- (void)imageBrowser:(IKImageBrowserView *)aBrowser cellWasDoubleClickedAtIndex:(NSUInteger)index {
    [self closeMediaPanel:self.okButton];
}

- (IBAction)zoomValueChanged:(id)sender {
    [self.imageBrowserView setZoomValue:[sender floatValue]];
}

@end
