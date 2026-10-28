#import <Cocoa/Cocoa.h>
#include <mach/mach_time.h>

static double ms_since(uint64_t t0) {
    static mach_timebase_info_data_t tb;
    if (tb.denom == 0) mach_timebase_info(&tb);
    return (double)(mach_absolute_time() - t0) * tb.numer / tb.denom / 1e6;
}

int main(void) {
    @autoreleasepool {
        NSArray *dirs = @[@"/Applications", @"/System/Applications",
                          @"/Applications/Utilities", @"/System/Applications/Utilities"];
        NSFileManager *fm = [NSFileManager defaultManager];
        NSWorkspace *ws = [NSWorkspace sharedWorkspace];
        int n = 0;
        uint64_t t0 = mach_absolute_time();
        for (NSString *dir in dirs) {
            NSArray *items = [fm contentsOfDirectoryAtPath:dir error:nil];
            for (NSString *name in items) {
                if (![name hasSuffix:@".app"]) continue;
                NSString *path = [dir stringByAppendingPathComponent:name];
                NSImage *img = [ws iconForFile:path];
                if (!img) continue;
                NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
                    initWithBitmapDataPlanes:NULL pixelsWide:128 pixelsHigh:128
                    bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
                    colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
                if (!rep) continue;
                [NSGraphicsContext saveGraphicsState];
                [NSGraphicsContext setCurrentContext:
                    [NSGraphicsContext graphicsContextWithBitmapImageRep:rep]];
                [img drawInRect:NSMakeRect(0, 0, 128, 128)
                       fromRect:NSZeroRect
                      operation:NSCompositingOperationSourceOver
                       fraction:1.0];
                [NSGraphicsContext restoreGraphicsState];
                n++;
            }
        }
        printf("icones desenhados: %d em %.1f ms\n", n, ms_since(t0));
    }
    return 0;
}
