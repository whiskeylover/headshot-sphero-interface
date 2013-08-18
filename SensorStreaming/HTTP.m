



//
//  HTTP.m
//

#import "HTTP.h"


@implementation HTTP

@synthesize receivedData;

- init {
    if ((self = [super init])) {
		
    }
    return self;
}

- (void)dealloc {
    [super dealloc];
}


- (void)setDelegate:(id)val
{
    delegate = val;
}

- (id)delegate
{
    return delegate;
}

- (void)get: (NSString *)urlString {
	
	NSLog ( @"GET: %@", urlString );
    
	self.receivedData = [[NSMutableData alloc] init];
	
    NSURLRequest *request = [[NSURLRequest alloc]
							 initWithURL: [NSURL URLWithString:urlString]
							 cachePolicy: NSURLRequestReloadIgnoringLocalCacheData
							 timeoutInterval: 10
							 ];
    
    NSURLConnection *connection = [[NSURLConnection alloc]
								   initWithRequest:request
								   delegate:self
								   startImmediately:YES];
	if(!connection) {
		NSLog(@"connection failed :(");
	} else {
		NSLog(@"connection succeeded  :)");
		
	}
	
	[connection release];
    [request release];
    [receivedData release];
}


- (void)post: (NSString *)urlString {
	
	// POST
	//[request setHTTPMethod:@"POST"];
	// NSString *postString = @"Some post string";
	//[request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
}

// ====================
// Callbacks
// ====================

#pragma mark NSURLConnection delegate methods
- (NSURLRequest *)connection:(NSURLConnection *)connection
			 willSendRequest:(NSURLRequest *)request
			redirectResponse:(NSURLResponse *)redirectResponse {
	NSLog(@"Connection received data, retain count");
    return request;
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	NSLog(@"Received response: %@", response);
	
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	NSLog(@"Received %d bytes of data", [data length]);
	
    [receivedData appendData:data];
	NSLog(@"Received data is now %d bytes", [receivedData length]);
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"Error receiving response: %@", error);
    [[NSAlert alertWithError:error] runModal];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // Once this method is invoked, "responseData" contains the complete result
	NSLog(@"Succeeded! Received %d bytes of data", [receivedData length]);
	
	NSString *dataStr=[[NSString alloc] initWithData:receivedData encoding:NSASCIIStringEncoding];
	NSLog(@"Succeeded! Received %@", dataStr);
	
	if ([delegate respondsToSelector:@selector(didFinishDownload:)]) {
		NSLog(@"Calling the delegate");
		//NSString* dataAsString = [[[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding] autorelease];
		[delegate performSelector:@selector(didFinishDownload:) withObject: dataStr];
	}
	
	[dataStr release];
}


@end