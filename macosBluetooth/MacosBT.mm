//
//  MacosBT.mm
//  iosBluetooth
//
//  Created by Bernd Porr on 11/02/2020.
//  Copyright © 2020 Bernd Porr. Apache License.
//

#import <Foundation/Foundation.h>

#import "MacosBT.h"

#import <IOBluetooth/objc/IOBluetoothDevice.h>
#import <IOBluetooth/objc/IOBluetoothSDPUUID.h>
#import <IOBluetooth/objc/IOBluetoothRFCOMMChannel.h>
#import <IOBluetoothUI/objc/IOBluetoothDeviceSelectorController.h>

#include <thread>

@interface AsyncCommDelegate : NSObject <IOBluetoothRFCOMMChannelDelegate> {
    @public
    MacosBT* delegateCPP;
}
@end

@implementation AsyncCommDelegate {
}

-(void)rfcommChannelOpenComplete:(IOBluetoothRFCOMMChannel *)rfcommChannel status:(IOReturn)error
{
    
    if ( error != kIOReturnSuccess ) {
        fprintf(stderr,"Error - could not open the RFCOMM channel. Error code = %08x.\n",error);
        return;
    }
    else{
        fprintf(stderr,"Connected. Yeah!\n");
    }
    
}

-(void)rfcommChannelData:(IOBluetoothRFCOMMChannel *)rfcommChannel data:(void *)dataPointer length:(size_t)dataLength
{
    NSString  *message = [[NSString alloc] initWithBytes:dataPointer length:dataLength encoding:NSUTF8StringEncoding];
    delegateCPP->dataRec([message UTF8String]);
}


@end

void MacosBT::clearText()
{
    fprintf(stderr,"\n");
}

void MacosBT::sendMessage(char* dataToSend, int len)
{
    fprintf(stderr,"Sending Message\n");
    [(__bridge IOBluetoothRFCOMMChannel*)rfcommchannel writeSync:(void*)dataToSend length:len];
}

void MacosBT::dataRec(const char *text)
{
    fprintf(stderr,"%s\n",text);
}


void MacosBT::discover()
{
    fprintf(stderr,"Attempting to connect\n");
   
    NSArray *deviceArray = [IOBluetoothDevice pairedDevices];
    if ( ( deviceArray == nil ) || ( [deviceArray count] == 0 ) ) {
        throw "Error - no device has been paired.";
    }
    fprintf(stderr,"We have %lu paired device(s).\n",(unsigned long)deviceArray.count);
    IOBluetoothDevice *device = [deviceArray objectAtIndex:0];
    fprintf(stderr,"device name = %s\n",[device.name UTF8String]);
    
    IOBluetoothSDPUUID *sppServiceUUID = [IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassSerialPort];
    IOBluetoothSDPServiceRecord     *sppServiceRecord = [device getServiceRecordForUUID:sppServiceUUID];
    if ( sppServiceRecord == nil ) {
        throw "Error - this is not an spp/rfcomm device.\n";
    }
    // To connect we need a device to connect and an RFCOMM channel ID to open on the device:
    UInt8 rfcommChannelID;
    if ( [sppServiceRecord getRFCOMMChannelID:&rfcommChannelID] != kIOReturnSuccess ) {
        throw "Error - not an SPP/RFCOMM device.\n";
    }
    
    rfcommDevice = (__bridge void*) device;
}

// static function
void MacosBT::run(MacosBT* MacosBT) {
    MacosBT->running = 1;
    IOBluetoothDevice *device = (__bridge IOBluetoothDevice *)MacosBT->rfcommDevice;
    IOBluetoothSDPUUID *sppServiceUUID = [IOBluetoothSDPUUID uuid16:kBluetoothSDPUUID16ServiceClassSerialPort];
    IOBluetoothSDPServiceRecord     *sppServiceRecord = [device getServiceRecordForUUID:sppServiceUUID];
    UInt8 rfcommChannelID;
    [sppServiceRecord getRFCOMMChannelID:&rfcommChannelID];
    
    AsyncCommDelegate* asyncCommDelegate = [[AsyncCommDelegate alloc] init];
    asyncCommDelegate->delegateCPP = MacosBT;
    
    IOBluetoothRFCOMMChannel *chan;

    if ( [device openRFCOMMChannelAsync:&chan withChannelID:rfcommChannelID delegate:asyncCommDelegate] != kIOReturnSuccess ) {
        throw "Error - could not open the rfcomm.\n";
    }
    
    if ( chan == NULL ) {
        throw "Error - chan == NULL";
    }
    
    MacosBT->rfcommchannel = (__bridge void*) chan;
    
    fprintf(stderr,"Successfully connected");

    while (MacosBT->running) {
        [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]];
    }
}

void MacosBT::start() {
    discover();
    uthread = new std::thread(MacosBT::run, this);
}

void MacosBT::stop() {
    running = 0;
    uthread->join();
}

void MacosBT::closeConnection() {
    IOBluetoothRFCOMMChannel *chan = (__bridge IOBluetoothRFCOMMChannel*) rfcommchannel;
    [chan closeChannel];
    fprintf(stderr,"closing");
}
