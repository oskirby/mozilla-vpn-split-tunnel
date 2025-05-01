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

  // Request the installation of the proxy extension
  self.request = [OSSystemExtensionRequest activationRequestForExtension: self.identifier
                                                                   queue: dispatch_get_main_queue()];
  self.request.delegate = self;

  [NETransparentProxyManager loadAllFromPreferencesWithCompletionHandler:^(NSArray<NETransparentProxyManager *>* managers, NSError* err){
    if (err != nil) {
      printf("load all failed: %s\n", [err.localizedDescription UTF8String]);
    } else {
      printf("load all: %d\n", managers.count);
    }
  }];

  // Create the proxy manager.
  auto protocol = [NETunnelProviderProtocol new];
  protocol.providerBundleIdentifier = self.identifier;
  protocol.serverAddress = @"127.0.0.1";
  self.manager = [NETransparentProxyManager new];
  self.manager.protocolConfiguration = protocol;
  self.manager.localizedDescription = @"Mozilla VPN Split Tunnel";

  return self;
}

- (void)    request:(OSSystemExtensionRequest *) request
didFinishWithResult:(OSSystemExtensionRequestResult) result {
  printf("request succeeded\n");
  // Enable the proxy manager.
  self.manager.enabled = true;

  // Load preferences
  [self.manager saveToPreferencesWithCompletionHandler:^(NSError* error){
    if (error == nil) {
      printf("save succeeded\n");
    } else {
      printf("save failed: %s\n", [error.localizedDescription UTF8String]);
    }
    [self.manager loadFromPreferencesWithCompletionHandler:^(NSError* error){
      if (error == nil) {
        printf("load succeeded\n");
      } else {
        printf("load failed: %s\n", [error.localizedDescription UTF8String]);
      }
      [self startProxy];
    }];
  }];
}

- (void) request:(OSSystemExtensionRequest *) request
didFailWithError:(NSError *) error {
  printf("failed to load: %s\n", [self.identifier UTF8String]);
  printf("request failed: %s\n", [[error localizedDescription] UTF8String]);
}

- (void) requestNeedsUserApproval:(OSSystemExtensionRequest *) request {
  printf("request needs user approval\n");
}

- (OSSystemExtensionReplacementAction) request:(OSSystemExtensionRequest *) request
                   actionForReplacingExtension:(OSSystemExtensionProperties *) existing 
                                 withExtension:(OSSystemExtensionProperties *) ext {
  printf("replacement action: %s -> %s\n",
         [existing.bundleVersion UTF8String], [ext.bundleVersion UTF8String]);
  return OSSystemExtensionReplacementActionReplace;
}


- (void) startProxy {
  NSError* startErr = nil;
  auto session = static_cast<NETunnelProviderSession*>(self.manager.connection);
  printf("proxy status: %ld\n", static_cast<long>([session status]));
  BOOL okay = [session startTunnelWithOptions:[NSDictionary<NSString*,id> new]
                               andReturnError:&startErr];
  if (startErr) {
    printf("start failed: %s\n", [[startErr localizedDescription] UTF8String]);
  }

  printf("proxy status: %ld\n", static_cast<long>([session status]));
}

@end
