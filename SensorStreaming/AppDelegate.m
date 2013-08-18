//
//  AppDelegate.m
//  SensorStreaming
//
//  Created by Michael DePhillips on 6/21/12.
//  Copyright (c) 2012 Orbotix Inc. All rights reserved.
//

#import "AppDelegate.h"
//#import "HTTP.h"
#import <RobotKit/RobotKit.h>
#import <RobotKit/JSON.h>

#define TOTAL_PACKET_COUNT 200
#define PACKET_COUNT_THRESHOLD 50

@implementation AppDelegate

@synthesize receivedData;

@synthesize accelXField = _accelXField;
@synthesize accelYField = _accelYField;
@synthesize accelZField = _accelZField;
@synthesize gyroRollField = _gyroRollField;
@synthesize gyroPitchField = _gyroPitchField;
@synthesize gyroYawField = _gyroYawField;
@synthesize window = _window;




- (void)get: (NSString *)urlString {
	
	//NSLog ( @"GET: %@", urlString );
    
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
		//NSLog(@"connection failed :(");
	} else {
		//NSLog(@"connection succeeded  :)");
		
	}
	
	[connection release];
    [request release];
    [receivedData release];
}


#pragma mark NSURLConnection delegate methods
- (NSURLRequest *)connection:(NSURLConnection *)connection
			 willSendRequest:(NSURLRequest *)request
			redirectResponse:(NSURLResponse *)redirectResponse {
	//NSLog(@"Connection received data, retain count");
    return request;
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	//NSLog(@"Received response: %@", response);
	
    [receivedData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	//NSLog(@"Received %d bytes of data", [data length]);
	
    [receivedData appendData:data];
	//NSLog(@"Received data is now %d bytes", [receivedData length]);
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	NSLog(@"Error receiving response: %@", error);
    [[NSAlert alertWithError:error] runModal];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    // Once this method is invoked, "responseData" contains the complete result
	//NSLog(@"Succeeded! Received %d bytes of data", [receivedData length]);
	
	NSString *dataStr=[[NSString alloc] initWithData:receivedData encoding:NSASCIIStringEncoding];
	//NSLog(@"Succeeded! Received: %@", dataStr);
	
	//if ([delegate respondsToSelector:@selector(didFinishDownload:)]) {
	//	NSLog(@"Calling the delegate");
	//	//NSString* dataAsString = [[[NSString alloc] initWithData:receivedData encoding:NSUTF8StringEncoding] autorelease];
	//	[delegate performSelector:@selector(didFinishDownload:) withObject: dataStr];
	//}
	
 
    
    @try {
        //NSLog(@"%@", dataStr);
        RKSBJsonParser *jObject = [[RKSBJsonParser alloc] init];
    
        //NSLog(@"%@", dataStr);
        NSDictionary *jDic = [jObject objectWithString:dataStr];
    
        NSString *skelX, *skelY, *skelZ, *humanDetected;
        
        skelX = [jDic objectForKey: @"X"];
        skelY = [jDic objectForKey: @"Y"];
        skelZ = [jDic objectForKey: @"Z"];
        humanDetected = [jDic objectForKey: @"detected"];
        
        
        
        xHuman = [skelX floatValue];
        yHuman = [skelY floatValue];
        zHuman = [skelZ floatValue];
        
        detected = [humanDetected boolValue];
        
        //NSLog(@"%f",xHuman);
    
        }
    @catch (NSException *exception) {
        
    }
    @finally {
        [self get:@"http://10.15.83.21:9000/"];
        [dataStr release];

    }

}



- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(appWillTerminate:)
												 name:NSApplicationWillTerminateNotification
											   object:nil];
    
    robotOnline = NO;
    // Insert code here to initialize your application
    [self setupRobotConnection];
}

- (void)appWillTerminate:(NSNotification *)notification {
    // disconnect Sphero
    if( !robotOnline ) return;
    
    /*When the application is entering the background we need to close the connection to the robot*/
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RKDeviceConnectionOnlineNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationWillTerminateNotification object:nil];
    
    // Close the connection
    [[RKRobotProvider sharedRobotProvider] closeRobotConnection];
    
    robotOnline = NO;
}

-(void)setupRobotConnection {
    /*Try to connect to the robot*/
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleRobotOnline) name:RKDeviceConnectionOnlineNotification object:nil];
    [[RKRobotProvider sharedRobotProvider] openRobotConnection];
}

- (void)handleRobotOnline {
    /*The robot is now online, we can begin sending commands*/
    if(!robotOnline) {
        // Disable stabilization (the control unit)
        [RKStabilizationCommand sendCommandWithState:RKStabilizationStateOff];
        [RKBackLEDOutputCommand sendCommandWithBrightness:1.0];
        /* Send commands to Sphero Here: */
        [self requestDataStreaming];
        ////Register for asynchronise data streaming packets
        [[RKDeviceMessenger sharedMessenger] addDataStreamingObserver:self selector:@selector(handleAsyncData:)];
        
        // Send the first JSON request
        [self get:@"http://10.15.83.21:9000/"];
        detected = false;

        
        // testing blue LED
        
    }
    robotOnline = YES;
}

-(void)requestDataStreaming {
    
    // Requesting the Accelerometer X, Y, and Z filtered (in Gs)
    //            the IMU Angles roll, pitch, and yaw (in degrees)
    //            the Quaternion data q0, q1, q2, and q3 (in 1/10000) of a Q
    RKDataStreamingMask mask =  RKDataStreamingMaskAccelerometerFilteredAll |
    RKDataStreamingMaskIMUAnglesFilteredAll   |
    RKDataStreamingMaskQuaternionAll;
    
    // Note: If your ball has Firmware < 1.20 then these Quaternions
    //       will simply show up as zeros.
    
    // Sphero samples this data at 400 Hz.  The divisor sets the sample
    // rate you want it to store frames of data.  In this case 400Hz/40 = 10Hz
    uint16_t divisor = 40;
    
    // Packet frames is the number of frames Sphero will store before it sends
    // an async data packet to the iOS device
    uint16_t packetFrames = 1;
    
    // Count is the number of async data packets Sphero will send you before
    // it stops.  You want to register for a finite count and then send the command
    // again once you approach the limit.  Otherwise data streaming may be left
    // on when your app crashes, putting Sphero in a bad state.
    uint8_t count = TOTAL_PACKET_COUNT;
    
    // Reset finite packet counter
    packetCount = 0;
    
    // Send command to Sphero
    [RKSetDataStreamingCommand sendCommandWithSampleRateDivisor:divisor
                                                   packetFrames:packetFrames
                                                     sensorMask:mask
                                                    packetCount:count];
    
}

- (void)handleAsyncData:(RKDeviceAsyncData *)asyncData
{
    // Need to check which type of async data is received as this method will be called for
    // data streaming packets and sleep notification packets. We are going to ingnore the sleep
    // notifications.
    if ([asyncData isKindOfClass:[RKDeviceSensorsAsyncData class]]) {
        
        // Check for new data request
        packetCount++;
        if( packetCount > (TOTAL_PACKET_COUNT-PACKET_COUNT_THRESHOLD) ) {
            [self requestDataStreaming];
        }
        
        // Received sensor data, so display it to the user.  This is where
        // the developer can use the data however they please to control
        // the app
        RKDeviceSensorsAsyncData *sensorsAsyncData = (RKDeviceSensorsAsyncData *)asyncData;
        RKDeviceSensorsData *sensorsData = [sensorsAsyncData.dataFrames lastObject];
        RKAccelerometerData *accelerometerData = sensorsData.accelerometerData;
        RKAttitudeData *attitudeData = sensorsData.attitudeData;
        
        // Print the accelerometer value (float) and roll pit and yaw values (signed ints)
        [self.accelXField setStringValue:[NSString stringWithFormat:@"%.6f", accelerometerData.acceleration.x]];
        [self.accelYField setStringValue:[NSString stringWithFormat:@"%.6f", accelerometerData.acceleration.y]];
        [self.accelZField setStringValue:[NSString stringWithFormat:@"%.6f", accelerometerData.acceleration.z]];
        [self.gyroRollField setStringValue:[NSString stringWithFormat:@"%.0f", attitudeData.roll]];
        [self.gyroPitchField setStringValue:[NSString stringWithFormat:@"%.0f", attitudeData.pitch]];
        [self.gyroYawField setStringValue:[NSString stringWithFormat:@"%.0f", attitudeData.yaw]];
        
        
        //[RKRawMotorValuesCommand sendCommandWithLeftMode:2 leftPower:255 rightMode:1 rightPower:0];
        
        //return;
        
        // If no human detected, return
        if(!detected)
        {
            [RKBackLEDOutputCommand sendCommandWithBrightness:0];
            [RKRawMotorValuesCommand sendCommandWithLeftMode:0 leftPower:0 rightMode:0 rightPower:0];

            return;
        }
        float xTurret = 0, yTurret = 0, zTurret = 0;
        float yawHuman, yawTurret, pitchHuman, pitchTurret;
        
        // Calculate yawHuman
        yawHuman = atan((xHuman - xTurret) / (zHuman - zTurret));
        yawHuman = yawHuman * 180 / M_PI;
        
        NSLog(@"Human yaw is %f", yawHuman);
                
        // Calculate yawTurret
        yawTurret = attitudeData.yaw;
        
        // if abs(yTurret - yHuman) <= 5, then keep blue light on
        if(abs(yawHuman - yawTurret) <= 5)
        {
            [RKBackLEDOutputCommand sendCommandWithBrightness:1];
            [RKRawMotorValuesCommand sendCommandWithLeftMode:0 leftPower:0 rightMode:0 rightPower:0];
        }
        
        else
        {
            [RKBackLEDOutputCommand sendCommandWithBrightness:0];

            // if yawTurret < yawHuman, rotate clockwise
            if(yawTurret < yawHuman)
            {
                [RKRawMotorValuesCommand sendCommandWithLeftMode:2 leftPower:127 rightMode:1 rightPower:0];
            }
            // if yawTurret > yawHuman, rotate counterclockwise
            if(yawTurret > yawHuman)
            {
                [RKRawMotorValuesCommand sendCommandWithLeftMode:1 leftPower:127 rightMode:1 rightPower:0];
            }
        }
        
    }
}



@end
