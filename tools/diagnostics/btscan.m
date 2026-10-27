#import <Foundation/Foundation.h>
#import <IOBluetooth/IOBluetooth.h>
@interface Scanner : NSObject <IOBluetoothDeviceInquiryDelegate>
@end
@implementation Scanner
- (void)deviceInquiryDeviceFound:(IOBluetoothDeviceInquiry *)inquiry device:(IOBluetoothDevice *)device {
  printf("ACHOU: %s  %s\n", [[device nameOrAddress] UTF8String], [[device addressString] UTF8String]);
}
- (void)deviceInquiryComplete:(IOBluetoothDeviceInquiry *)inquiry error:(IOReturn)error aborted:(BOOL)aborted {
  printf("FIM: error=0x%x aborted=%d\n", error, aborted);
  CFRunLoopStop(CFRunLoopGetCurrent());
}
@end
int main(void) {
  @autoreleasepool {
    Scanner *s = [Scanner new];
    IOBluetoothDeviceInquiry *inq = [IOBluetoothDeviceInquiry inquiryWithDelegate:s];
    IOReturn r = [inq start];
    printf("start=0x%x\n", r);
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 14, false);
    [inq stop];
  }
  return 0;
}