/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import <NetworkExtension/NetworkExtension.h>
#import <SystemExtensions/SystemExtensions.h>

#import "VPNSplitTunnelLoader.h"

@implementation VPNSplitTunnelLoader

- (NSString*) identifier {
    return @"org.mozilla.macos.FirefoxVPN.split-tunnel";
}

- (id)init {
  self = [super init];
  self.manager = nullptr;

  // Request the installation of the proxy extension
  NSLog(@"request started");
  self.request = [OSSystemExtensionRequest activationRequestForExtension: self.identifier
                                                                   queue: dispatch_get_main_queue()];
  self.request.delegate = self;
  return self;
}

- (void) setupManager:(void (^)(NSError * error)) completionHandler {
  [NETransparentProxyManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETransparentProxyManager *>* managers, NSError* err){
    if (err != nil) {
      NSLog(@"load managers failed: %@", err.localizedDescription);
      completionHandler(err);
      return;
    }

    // Check if an existing manager can be used.
    for (NETransparentProxyManager* mgr in managers) {
      auto proto = static_cast<NETunnelProviderProtocol*>([mgr protocolConfiguration]);
      NSLog(@"found existing manager: %@", proto.providerBundleIdentifier);
      if ([proto.providerBundleIdentifier isEqualToString:self.identifier]) {
        self.manager = mgr;
        completionHandler(nil);
        return;
      }
    }

    // Otherwise - create a new manager.
    auto protocol = [NETunnelProviderProtocol new];
    protocol.providerBundleIdentifier = self.identifier;
    protocol.serverAddress = @"127.0.0.1";

    self.manager = [NETransparentProxyManager new];
    self.manager.protocolConfiguration = protocol;
    self.manager.localizedDescription = @"Mozilla VPN Split Tunnel";
    completionHandler(nil);
  }];
}

- (void)    request:(OSSystemExtensionRequest *) request
didFinishWithResult:(OSSystemExtensionRequestResult) result {
  NSLog(@"request succeeded");
  // Enable the proxy manager.
  [self setupManager:^(NSError* error) {
    self.manager.enabled = true;

    // Sync preferences and start the proxy.
    [self.manager saveToPreferencesWithCompletionHandler:^(NSError* error){
      if (error == nil) {
        NSLog(@"save succeeded");
      } else {
        NSLog(@"save failed: %@", error.localizedDescription);
      }
      [self.manager loadFromPreferencesWithCompletionHandler:^(NSError* error){
        if (error == nil) {
          NSLog(@"load succeeded");
        } else {
          NSLog(@"load failed: %@", error.localizedDescription);
        }
        [self startProxy];
      }];
    }];
  }];
}

- (void) request:(OSSystemExtensionRequest *) request
didFailWithError:(NSError *) error {
  NSLog(@"request failed: %@", error.localizedDescription);
}

- (void) requestNeedsUserApproval:(OSSystemExtensionRequest *) request {
  NSLog(@"request needs user approval");
}

- (OSSystemExtensionReplacementAction) request:(OSSystemExtensionRequest *) request
                   actionForReplacingExtension:(OSSystemExtensionProperties *) existing 
                                 withExtension:(OSSystemExtensionProperties *) ext {
  NSLog(@"replacement action: %@ -> %@", existing.bundleVersion, ext.bundleVersion);
  return OSSystemExtensionReplacementActionReplace;
}

- (void) startProxy {
  NSError* startErr = nil;
  auto session = static_cast<NETunnelProviderSession*>(self.manager.connection);
  NSLog(@"proxy status: %ld", static_cast<long>([session status]));
  BOOL okay = [session startTunnelWithOptions:[NSDictionary<NSString*,id> new]
                               andReturnError:&startErr];
  if (startErr) {
    NSLog(@"start failed: %@", startErr.localizedDescription);
  }

  NSLog(@"proxy status: %ld", static_cast<long>([session status]));
}

@end
