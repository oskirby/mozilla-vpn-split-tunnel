/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import <Foundation/Foundation.h>
#import <SystemExtensions/SystemExtensions.h>

#import "VPNSplitTunnelLoader.h"

int main(int argc, char *argv[]) {
  NSLog(@"request started");
  auto loader = [[VPNSplitTunnelLoader alloc] init];
  [[OSSystemExtensionManager sharedManager] submitRequest: loader.request];

  // Run the application.
  dispatch_main();
}
