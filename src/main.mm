#include <Geode/Geode.hpp>
#include <Geode/modify/AppDelegate.hpp>
#include <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

using namespace geode::prelude;

// Helper to create and configure a display link for 120Hz
static CADisplayLink* s_displayLink = nil;

static void setupDisplayLink() {
    if (s_displayLink) return;

    // Create a display link with a dummy target
    s_displayLink = [CADisplayLink displayLinkWithTarget:[NSObject new] selector:@selector(description)];
    if (@available(iOS 15.0, *)) {
        s_displayLink.preferredFrameRateRange = CAFrameRateRangeMake(80, 120, 120);
    } else {
        s_displayLink.preferredFramesPerSecond = 120;
    }
    [s_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    log::info("[iOS120Hz] Display link configured for 120Hz");
}

// Hook into AppDelegate to modify display link
class $modify(iOS120HzAppDelegate, AppDelegate) {
    bool applicationDidFinishLaunching() {
        // Call original
        if (!AppDelegate::applicationDidFinishLaunching()) {
            return false;
        }

        log::info("[iOS120Hz] Initializing 120Hz support...");

        // Schedule display link setup on next run loop iteration
        // to ensure the window and view hierarchy are ready
        dispatch_async(dispatch_get_main_queue(), ^{
            setupDisplayLink();
        });

        return true;
    }
};

// Hook CCDirector to modify the animation interval
class $modify(iOS120HzDirector, CCDirector) {
    void setAnimationInterval(double interval) {
        // Force 120Hz (8.333ms = 1/120)
        CCDirector::setAnimationInterval(1.0 / 120.0);
        log::debug("[iOS120Hz] Animation interval set to 120Hz");
    }

    void setNextDeltaTimeZero(bool nextDeltaTimeZero) {
        CCDirector::setNextDeltaTimeZero(nextDeltaTimeZero);
    }
};

// Hook into the view controller to set preferred refresh rate
@interface GeometryDashViewController : UIViewController
@end

@implementation GeometryDashViewController (iOS120Hz)

+ (void)load {
    Method original = class_getInstanceMethod(self, @selector(viewDidLoad));
    Method swizzled = class_getInstanceMethod(self, @selector(ios120hz_viewDidLoad));
    method_exchangeImplementations(original, swizzled);
}

- (void)ios120hz_viewDidLoad {
    [self ios120hz_viewDidLoad]; // Call original (swizzled)

    if (@available(iOS 15.0, *)) {
        CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(ios120hz_update:)];
        displayLink.preferredFrameRateRange = CAFrameRateRangeMake(80, 120, 120);
        [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}

- (void)ios120hz_update:(CADisplayLink*)displayLink {
    // Empty update handler - actual rendering is handled by Cocos2d-x
}

@end

// Settings for the mod
// Include a minimal settings implementation
$on_mod(Loaded) {
    log::info("[iOS120Hz] Mod loaded - 120Hz support enabled");

    // Check if device supports ProMotion
    UIScreen* mainScreen = [UIScreen mainScreen];
    if (@available(iOS 15.0, *)) {
        float maxFPS = mainScreen.maximumFramesPerSecond;
        log::info("[iOS120Hz] Device maximum frame rate: {}Hz", maxFPS);

        if (maxFPS < 120) {
            log::warn("[iOS120Hz] Device does not support 120Hz ProMotion display");
        }
    }
}
