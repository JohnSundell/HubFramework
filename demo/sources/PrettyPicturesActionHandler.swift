/*
 *  Copyright (c) 2016 Spotify AB.
 *
 *  Licensed to the Apache Software Foundation (ASF) under one
 *  or more contributor license agreements.  See the NOTICE file
 *  distributed with this work for additional information
 *  regarding copyright ownership.  The ASF licenses this file
 *  to you under the Apache License, Version 2.0 (the
 *  "License"); you may not use this file except in compliance
 *  with the License.  You may obtain a copy of the License at
 *
 *  http://www.apache.org/licenses/LICENSE-2.0
 *
 *  Unless required by applicable law or agreed to in writing,
 *  software distributed under the License is distributed on an
 *  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 *  KIND, either express or implied.  See the License for the
 *  specific language governing permissions and limitations
 *  under the License.
 */

import Foundation
import HubFramework

#if !os(tvOS)
import SafariServices
#endif

/// Action handler that opens a URL in a Safari VC
class PrettyPicturesActionHandler: NSObject, HUBActionHandler {
    func handleAction(with context: HUBActionContext) -> Bool {
        #if os(tvOS)
        return false
        #else
        guard let uri = context.componentModel?.target?.uri else {
            return false
        }

        let svc = SFSafariViewController(url: uri)
        context.viewController.present(svc, animated: true, completion: nil)

        return true
        #endif
    }
}

