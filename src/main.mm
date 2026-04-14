#include <Geode/Geode.hpp>
#include <Geode/modify/AppDelegate.hpp>
#include <objc/runtime.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>

using namespace geode::prelude;

// Hook into AppDelegate to modify display link
class $modify(iOS120HzAppDelegate, AppDelegate) {
    bool applicationDidFinishLaunching() {
        // Call original
        if (!AppDelegate::applicationDidFinishLaunching()) {
            return false;
        }

        log::info("[iOS120Hz] Initializing 120Hz support...");

        // Get the key window's display link
        UIApplication* app = [UIApplication sharedApplication];
        UIWindow* keyWindow = nil;

        for (UIWindow* window in app.windows) {
            if (window.isKeyWindow) {
                keyWindow = window;
                break;
            }
        }

        if (!keyWindow && app.windows.count > 0) {
            keyWindow = app.windows[0];
        }

        if (keyWindow) {
            // Force 120Hz on the screen
            UIScreen* screen = keyWindow.screen;
            if (@available(iOS 15.0, *)) {
                CAFrameRateRange frameRateRange = CAFrameRateRangeMake(80, 120, 120);

                // Find and modify the display link
                [[NSNotificationCenter defaultCenter]
                    addObserverForName:CADisplayLinkDidRefreshNotification
                    object:nil
                    queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *notification) {
                        CADisplayLink* displayLink = notification.object;
                        if (displayLink) {
                            displayLink.preferredFrameRateRange = frameRateRange;
                        }
                    }];
            } else if (@available(iOS 10.0, *)) {
                // Fallback for older iOS
                [[NSNotificationCenter defaultCenter]
                    addObserverForName:CADisplayLinkDidRefreshNotification
                    object:nil
                    queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *notification) {
                        CADisplayLink* displayLink = notification.object;
                        if (displayLink) {
                            displayLink.preferredFramesPerSecond = 120;
                        }
                    }];
            }

            log::info("[iOS120Hz] Display link configured for 120Hz");
        }

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
    [self ios120hz_viewDidLoad]; // Call original

    if (@available(iOS 15.0, *)) {
        // Set preferred frame rate range for Metal/CAMetalLayer
        CAFrameRateRange frameRateRange = CAFrameRateRangeMake(80, 120, 120);

        // For MTKView/CAMetalLayer
        for (CALayer* layer in self.view.layer.sublayers) {
            if ([layer isKindOfClass:[CAMetalLayer class]]) {
                CAMetalLayer* metalLayer = (CAMetalLayer*)layer;
                // Set display link for this layer
                CADisplayLink* displayLink = [self.view displayLinkWithTarget:self selector:@selector(ios120hz_update:)];
                if (displayLink) {
                    displayLink.preferredFrameRateRange = frameRateRange;
                    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
                }
            }
        }
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
