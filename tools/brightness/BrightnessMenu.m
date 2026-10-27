#import <Cocoa/Cocoa.h>
#import <IOKit/IOKitLib.h>
#import <IOKit/graphics/IOGraphicsLib.h>
#import <Carbon/Carbon.h>

static io_service_t g_svc = 0;
static float g_level = 0.5f;
static NSStatusItem *g_item = nil;

static io_service_t findBacklight(void) {
    io_iterator_t it;
    if (IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("AppleBacklightDisplay"), &it) != KERN_SUCCESS)
        return 0;
    io_service_t s = IOIteratorNext(it);
    IOObjectRelease(it);
    return s;
}

static void refreshTitle(void);

static float readLevel(void) {
    if (!g_svc) g_svc = findBacklight();
    if (!g_svc) return -1;
    float v = -1;
    if (IODisplayGetFloatParameter(g_svc, 0, CFSTR("bklt"), &v) != kIOReturnSuccess) return -1;
    return v;
}

static void writeLevel(float v) {
    if (v < 0.01f) v = 0.01f;
    if (v > 1.0f) v = 1.0f;
    if (!g_svc) g_svc = findBacklight();
    if (!g_svc) return;
    IODisplaySetFloatParameter(g_svc, 0, CFSTR("bklt"), v);
    g_level = v;
    refreshTitle();
}

static void step(float d) {
    float v = readLevel();
    if (v < 0) v = g_level;
    writeLevel(v + d);
}

static void refreshTitle(void) {
    float v = readLevel();
    if (v >= 0) g_level = v;
    int pct = (int)(g_level * 100.0f + 0.5f);
    dispatch_async(dispatch_get_main_queue(), ^{
        if (g_item) g_item.button.title = [NSString stringWithFormat:@"\u2600 %d%%", pct];
    });
}

static OSStatus hotkeyHandler(EventHandlerCallRef next, EventRef ev, void *ud) {
    EventHotKeyID hk;
    GetEventParameter(ev, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof hk, NULL, &hk);
    if (hk.id == 1) step(+0.0625f);
    else if (hk.id == 2) step(-0.0625f);
    return noErr;
}

@interface AppDelegate : NSObject <NSApplicationDelegate>
@end

@implementation AppDelegate
- (void)applicationDidFinishLaunching:(NSNotification *)note {
    g_svc = findBacklight();
    g_item = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    NSMenu *m = [[NSMenu alloc] init];
    [m addItemWithTitle:@"Aumentar  (\u2303\u2325\u2191)" action:@selector(up:) keyEquivalent:@""];
    [m addItemWithTitle:@"Diminuir  (\u2303\u2325\u2193)" action:@selector(down:) keyEquivalent:@""];
    [m addItem:[NSMenuItem separatorItem]];
    [m addItemWithTitle:@"25%" action:@selector(q25:) keyEquivalent:@""];
    [m addItemWithTitle:@"50%" action:@selector(q50:) keyEquivalent:@""];
    [m addItemWithTitle:@"75%" action:@selector(q75:) keyEquivalent:@""];
    [m addItemWithTitle:@"100%" action:@selector(q100:) keyEquivalent:@""];
    [m addItem:[NSMenuItem separatorItem]];
    [m addItemWithTitle:@"Sair" action:@selector(quit:) keyEquivalent:@"q"];
    for (NSMenuItem *i in m.itemArray) i.target = self;
    g_item.menu = m;
    refreshTitle();

    EventHotKeyID up = {'brgt', 1}, dn = {'brgt', 2};
    EventHotKeyRef ref;
    RegisterEventHotKey(kVK_UpArrow, controlKey | optionKey, up, GetApplicationEventTarget(), 0, &ref);
    RegisterEventHotKey(kVK_DownArrow, controlKey | optionKey, dn, GetApplicationEventTarget(), 0, &ref);
    EventTypeSpec t = { kEventClassKeyboard, kEventHotKeyPressed };
    InstallApplicationEventHandler(NewEventHandlerUPP(hotkeyHandler), 1, &t, NULL, NULL);
}
- (void)up:(id)s { step(+0.0625f); }
- (void)down:(id)s { step(-0.0625f); }
- (void)q25:(id)s { writeLevel(0.25f); }
- (void)q50:(id)s { writeLevel(0.50f); }
- (void)q75:(id)s { writeLevel(0.75f); }
- (void)q100:(id)s { writeLevel(1.0f); }
- (void)quit:(id)s { [NSApp terminate:nil]; }
@end

int main(void) {
    @autoreleasepool {
        [NSApplication sharedApplication];
        AppDelegate *d = [[AppDelegate alloc] init];
        [NSApp setDelegate:d];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyAccessory];
        [NSApp run];
    }
    return 0;
}
