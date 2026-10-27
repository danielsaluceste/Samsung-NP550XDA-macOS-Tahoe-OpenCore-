#include <CoreGraphics/CoreGraphics.h>
#include <stdio.h>
int main(void) {
  CGDirectDisplayID d = CGMainDisplayID();
  CGDisplayModeRef m = CGDisplayCopyDisplayMode(d);
  printf("display %u: %zux%zu, refresh=%.2f Hz, pixel=%zux%zu, %s\n",
         (unsigned)d,
         CGDisplayModeGetWidth(m), CGDisplayModeGetHeight(m),
         CGDisplayModeGetRefreshRate(m),
         CGDisplayModeGetPixelWidth(m), CGDisplayModeGetPixelHeight(m),
         CGDisplayModeIsUsableForDesktopGUI(m) ? "usable" : "NAO usable");
  CFArrayRef modes = CGDisplayCopyAllDisplayModes(d, NULL);
  if (modes) {
    CFIndex n = CFArrayGetCount(modes);
    printf("modos: %ld\n", (long)n);
    for (CFIndex i = 0; i < n && i < 10; i++) {
      CGDisplayModeRef mm = (CGDisplayModeRef)CFArrayGetValueAtIndex(modes, i);
      printf("  %zux%zu @ %.2f Hz\n", CGDisplayModeGetWidth(mm), CGDisplayModeGetHeight(mm), CGDisplayModeGetRefreshRate(mm));
    }
  }
  return 0;
}