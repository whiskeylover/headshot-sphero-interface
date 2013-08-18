//
//  HTTP.h
//
#import <Cocoa/Cocoa.h>

@interface HTTP : NSObject {
	id delegate;
	NSMutableData *receivedData;
	NSURL *url;
}
@property (nonatomic,retain) NSMutableData *receivedData;
@property (retain) id delegate;

- (void)get: (NSString *)urlString;
- (void)post: (NSString *)urlString;

@end

