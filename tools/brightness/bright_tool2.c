#include <CoreFoundation/CoreFoundation.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/graphics/IOGraphicsLib.h>
#include <stdio.h>
#include <stdlib.h>

static void dump(io_service_t svc) {
    CFMutableDictionaryRef props = NULL;
    if (IORegistryEntryCreateCFProperties(svc, &props, kCFAllocatorDefault, 0) == KERN_SUCCESS && props) {
        CFTypeRef p = CFDictionaryGetValue(props, CFSTR("IODisplayParameters"));
        if (p) {
            CFStringRef s = CFCopyDescription(p);
            char buf[2048];
            if (CFStringGetCString(s, buf, sizeof buf, kCFStringEncodingUTF8)) printf("  params: %s\n", buf);
            CFRelease(s);
        }
        CFRelease(props);
    }
}

int main(int argc, char **argv) {
    io_iterator_t iter;
    if (IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("AppleBacklightDisplay"), &iter) != KERN_SUCCESS) {
        printf("sem AppleBacklightDisplay\n"); return 1;
    }
    io_service_t svc;
    const char *keys[] = {"bklt", "brightness", "brightness-level"};
    while ((svc = IOIteratorNext(iter))) {
        printf("servico %u\n", (unsigned)svc);
        dump(svc);
        for (int k = 0; k < 3; k++) {
            CFStringRef ks = CFStringCreateWithCString(kCFAllocatorDefault, keys[k], kCFStringEncodingUTF8);
            float v = -1;
            IOReturn r = IODisplayGetFloatParameter(svc, 0, ks, &v);
            printf("  get %s -> r=0x%x v=%.3f\n", keys[k], r, v);
            CFRelease(ks);
        }
        if (argc > 1) {
            float v = (float)atof(argv[1]);
            CFStringRef ks = CFStringCreateWithCString(kCFAllocatorDefault, "bklt", kCFStringEncodingUTF8);
            IOReturn r = IODisplaySetFloatParameter(svc, 0, ks, v);
            printf("  SET bklt=%.2f -> 0x%x\n", v, r);
            CFRelease(ks);
            dump(svc);
        }
        IOObjectRelease(svc);
    }
    IOObjectRelease(iter);
    return 0;
}
