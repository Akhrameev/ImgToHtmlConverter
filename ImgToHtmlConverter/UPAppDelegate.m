//
//  UPAppDelegate.m
//  ImgToHtmlConverter
//
//  Created by Pavel Akhrameev on 05.06.14.
//  Copyright (c) 2014 Pavel Akhrameev. All rights reserved.
//

#import "UPAppDelegate.h"

@implementation UPAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    [self convertImages];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - methods

- (void)convertImages {
    NSArray *fileNames = @[@"logo.png", @"cover.jpg", @"logo_.png", @"cover_.jpg"];
    for (NSString *name  in fileNames) {
        BOOL html = YES;
        NSString *format = html ? @"html" : @"txt";
        NSString *fileName = [NSString stringWithFormat:@"%@.%@", name, format];
        [self convertToHtmlImageWithName:name toFileName:fileName];
    }
}

- (void)convertToHtmlImageWithName:(NSString *)imgName toFileName:(NSString *)fileName {
    UIImage *img = [UIImage imageNamed:imgName];
    NSString *resultHtml = @"<HTML><head><style type=\"text/css\"> tr{height:1px} </style></head><BODY><table border=\"0\" cellspacing=\"0\" cellpadding=\"0\">";
    CGSize size = img.size;
    NSArray *array = [self.class getRGBAsFromImage:img atX:0 andY:0 count:size.height * size.width];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *documentTXTPath = [documentsDirectory stringByAppendingPathComponent:fileName];
    [resultHtml writeToFile:documentTXTPath atomically:YES];
    NSFileHandle *myHandle = [NSFileHandle fileHandleForWritingAtPath:documentTXTPath];
    
    for (NSUInteger row = 0; row < size.height; ++row) {
        UIColor *lastColor = nil;
        NSString *rowString = @"<tr>";
        NSUInteger pixelsOfSameColor = 0;
        for (NSUInteger col = 0; col < size.width; ++col) {
            UIColor *color = [array objectAtIndex:size.width * row + col];
            if ((lastColor && ![lastColor isEqual:color])) {
                NSString *hex = [NSString stringWithFormat:@"#%@", [self.class colorToWeb:lastColor]];
                if (!pixelsOfSameColor) {
                    rowString = [rowString stringByAppendingString:[NSString stringWithFormat:@"<td width='1' bgcolor=%@></td>", hex]];
                } else {
                    rowString = [rowString stringByAppendingString:[NSString stringWithFormat:@"<td colspan='%@' width='%@' bgcolor=%@></td>", @(pixelsOfSameColor + 1), @(pixelsOfSameColor + 1), hex]];
                }
                pixelsOfSameColor = 0;
            } else {
                ++pixelsOfSameColor;
            }
            lastColor = color;
        }
        if (pixelsOfSameColor) {
            NSString *hex = [NSString stringWithFormat:@"#%@", [self.class colorToWeb:lastColor]];
            if (!pixelsOfSameColor) {
                rowString = [rowString stringByAppendingString:[NSString stringWithFormat:@"<td width='1' bgcolor=%@></td>", hex]];
            } else {
                rowString = [rowString stringByAppendingString:[NSString stringWithFormat:@"<td colspan='%@' width='%@' bgcolor=%@></td>", @(pixelsOfSameColor + 1), @(pixelsOfSameColor + 1), hex]];
            }
        }
        rowString = [rowString stringByAppendingString:@"</tr>"];
        [myHandle seekToEndOfFile];
        [myHandle writeData:[rowString dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [myHandle seekToEndOfFile];
    [myHandle writeData:[@"</table></BODY></HTML>" dataUsingEncoding:NSUTF8StringEncoding]];
}

+ (NSArray*)getRGBAsFromImage:(UIImage*)image atX:(int)xx andY:(int)yy count:(int)count
{
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    
    // First get the image into your data buffer
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    
    // Now your rawData contains the image data in the RGBA8888 pixel format.
    int byteIndex = (bytesPerRow * yy) + xx * bytesPerPixel;
    for (int ii = 0 ; ii < count ; ++ii)
    {
        CGFloat red   = (rawData[byteIndex]     * 1.0) / 255.0;
        CGFloat green = (rawData[byteIndex + 1] * 1.0) / 255.0;
        CGFloat blue  = (rawData[byteIndex + 2] * 1.0) / 255.0;
        CGFloat alpha = (rawData[byteIndex + 3] * 1.0) / 255.0;
        byteIndex += 4;
        
        UIColor *acolor = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
        [result addObject:acolor];
    }
    
    free(rawData);
    
    return result;
}

+ (NSString*)colorToWeb:(UIColor*)color
{
    NSString *webColor = nil;
    
    // This method only works for RGB colors
    if (color &&
        CGColorGetNumberOfComponents(color.CGColor) == 4)
    {
        // Get the red, green and blue components
        const CGFloat *components = CGColorGetComponents(color.CGColor);
        
        // These components range from 0.0 till 1.0 and need to be converted to 0 till 255
        CGFloat red, green, blue;
        red = roundf(components[0] * 255.0);
        green = roundf(components[1] * 255.0);
        blue = roundf(components[2] * 255.0);
        
        // Convert with %02x (use 02 to always get two chars)
        webColor = [[NSString alloc]initWithFormat:@"%02x%02x%02x", (int)red, (int)green, (int)blue];
    }
    
    return webColor;
}

@end
