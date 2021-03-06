// Copyright (c) 2013 GitHub, Inc.
// Use of this source code is governed by the MIT license that can be
// found in the LICENSE file.

#import "atom/browser/mac/atom_application.h"

#include "atom/browser/browser.h"
#include "base/auto_reset.h"
#include "base/strings/sys_string_conversions.h"
#include "content/public/browser/browser_accessibility_state.h"

@implementation AtomApplication

+ (AtomApplication*)sharedApplication {
  return (AtomApplication*)[super sharedApplication];
}

- (BOOL)isHandlingSendEvent {
  return handlingSendEvent_;
}

- (void)sendEvent:(NSEvent*)event {
  base::AutoReset<BOOL> scoper(&handlingSendEvent_, YES);
  [super sendEvent:event];
}

- (void)setHandlingSendEvent:(BOOL)handlingSendEvent {
  handlingSendEvent_ = handlingSendEvent;
}

- (void)awakeFromNib {
  [[NSAppleEventManager sharedAppleEventManager]
      setEventHandler:self
          andSelector:@selector(handleURLEvent:withReplyEvent:)
        forEventClass:kInternetEventClass
           andEventID:kAEGetURL];
}

- (IBAction)closeAllWindows:(id)sender {
  atom::Browser::Get()->Quit();
}

- (void)handleURLEvent:(NSAppleEventDescriptor*)event
        withReplyEvent:(NSAppleEventDescriptor*)replyEvent {
  NSString* url = [
      [event paramDescriptorForKeyword:keyDirectObject] stringValue];
  atom::Browser::Get()->OpenURL(base::SysNSStringToUTF8(url));
}

- (void)accessibilitySetValue:(id)value forAttribute:(NSString *)attribute {
  // Undocumented attribute that VoiceOver happens to set while running.
  // Chromium uses this too, even though it's not exactly right.
  if ([attribute isEqualToString:@"AXEnhancedUserInterface"]) {
    [self updateAccessibilityEnabled:[value boolValue]];
  }
  return [super accessibilitySetValue:value forAttribute:attribute];
}

- (void)updateAccessibilityEnabled:(BOOL)enabled {
  auto ax_state = content::BrowserAccessibilityState::GetInstance();

  if (enabled) {
    ax_state->OnScreenReaderDetected();
  } else {
    ax_state->DisableAccessibility();
  }
}

@end
