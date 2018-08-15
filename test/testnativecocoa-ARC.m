
#include "testnative.h"

#ifdef TEST_NATIVE_COCOA

#include <Cocoa/Cocoa.h>

static void *CreateWindowCocoa(int w, int h);
static void DestroyWindowCocoa(void *window);

NativeWindowFactory CocoaWindowFactory = {
    "cocoa",
    CreateWindowCocoa,
    DestroyWindowCocoa
};

static void *CreateWindowCocoa(int w, int h)
{
    NSWindow *nswindow;
    NSRect rect;
    NSUInteger style;

	@autoreleasepool {

    rect.origin.x = 0;
    rect.origin.y = 0;
    rect.size.width = w;
    rect.size.height = h;
    rect.origin.y = CGDisplayPixelsHigh(kCGDirectMainDisplay) - rect.origin.y - rect.size.height;

    style = (NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask);

    nswindow = [[NSWindow alloc] initWithContentRect:rect styleMask:style backing:NSBackingStoreBuffered defer:FALSE];
    [nswindow makeKeyAndOrderFront:nil];

	}
	
    return CFBridgingRetain(nswindow);
}

static void DestroyWindowCocoa(void *window)
{
	@autoreleasepool {
    NSWindow *nswindow = CFBridgingRelease(window);

    [nswindow close];
	}
}

#endif
