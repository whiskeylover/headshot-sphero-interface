![logo](http://update.orbotix.com/developer/sphero-small.png)

# Sensor Streaming

## Available Sensor Parameters

 3. **IMU** (Roll, Pitch, and Yaw)
 4. **Back EMF** (Left Motor, Right Motor)
 5. **Quaternions** - *New to Firmware 1.20*
 6. **Location Data** (X, Y, Vx, Vy) - *New to Firmware 1.20*

An accelerometer measures the force of gravity in 3-dimensions (x,y,z).  A few uses are for determining shake gestures and collisions. 

![android.jpg](https://github.com/orbotix/Sphero-Android-SDK/raw/master/assets/accelerometer.png)

On Sphero, you have access to the raw and filtered accelerometer data.  You should always stream the filtered data, unless you have use for the raw data.  The filtered accelerometer data is in units of g.  So, 1 G = a value of 9.81 m/s^2. 


A gyroscope is a device for measuring or maintaining orientation, based on the principles of angular momentum. It returns the rate of angular velocity.

![android.jpg](https://github.com/orbotix/Sphero-Android-SDK/raw/master/assets/gyroscope.png)



Back electromotive force (abbreviated Back EMF) is the voltage, or electromotive force, that pushes against the current which induces it.  Before we created the Locator, this could be used to determine how fast Sphero was traveling. It can still be used to determining what is going on with the motors.

## Quaternions

		Note: You need firmware 1.20 or above on Sphero, or these values will always be 0

Quaternions are a number system that extends the complex numbers.  They are used to represent orientation in 3D-space.  Typically, these are four numbers, all ranging from 0-1.  For data transmission reasons, we give you 4 numbers from 0-10000.  Hence, the units on these return numbers are (1/10000th) of a Q.  

## Locator Data

		Note: You need firmware 1.20 or above on Sphero, or these values will always be 0
		
The locator returns values for the x,y position of Sphero on the floor, and the current velocity vector of Sphero.  Please see the locator sample documentation for more information.


    
    	// Requesting the Accelerometer X, Y, and Z filtered (in Gs)
    	//            the IMU Angles roll, pitch, and yaw (in degrees)
    	RKDataStreamingMask mask =  RKDataStreamingMaskAccelerometerFilteredAll |
                                RKDataStreamingMaskIMUAnglesFilteredAll;
    
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
    	packetCounter = 0;
    
    	// Send command to Sphero
    	[RKSetDataStreamingCommand sendCommandWithSampleRateDivisor:divisor
                                                   packetFrames:packetFrames
                                                     sensorMask:mask
                                                    packetCount:count];

	}
    


You will receive an `onDataReceived` callback at the frequency in which you requested data streaming.  The callback will contain `DeviceAsyncData` with a certain number of frames (also determined when requesting data).  The data will contain all the variables you requested as well.

In this example, you have access to the Attitude (IMU) data and the filtered accelerometer data. 
 

	{
    	// Need to check which type of async data is received as this method will be called for
    	// data streaming packets and sleep notification packets. We are going to ignore the sleep
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
    }
}

For questions, please visit our developer's forum at [http://forum.gosphero.com/](http://forum.gosphero.com/)

	 