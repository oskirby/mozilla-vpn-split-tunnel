/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef VPNSPLITTUNNELLOADER_H
#define VPNSPLITTUNNELLOADER_H

#include <NetworkExtension/NetworkExtension.h>
#include <SystemExtensions/SystemExtensions.h>

@interface VPNSplitTunnelLoader : NSObject <OSSystemExtensionRequestDelegate>

@property(readonly) NSString* identifier;
@property OSSystemExtensionRequest* request;
@property NETransparentProxyManager* manager;

- (void)    request:(OSSystemExtensionRequest *) request
didFinishWithResult:(OSSystemExtensionRequestResult) result;

- (void) request:(OSSystemExtensionRequest *) request 
didFailWithError:(NSError *) error;

- (void) requestNeedsUserApproval:(OSSystemExtensionRequest *) request;

- (OSSystemExtensionReplacementAction) request:(OSSystemExtensionRequest *) request 
                   actionForReplacingExtension:(OSSystemExtensionProperties *) existing 
                                 withExtension:(OSSystemExtensionProperties *) ext;
@end

#endif  // VPNSPLITTUNNELLOADER_H
