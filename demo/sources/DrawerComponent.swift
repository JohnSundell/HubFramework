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

class DrawerComponent: NSObject, HUBComponentWithChildren, HUBComponentViewObserver, HUBComponentAnimationPerformer, HUBComponentWithRestorableUIState {
    var view: UIView?
    weak var childDelegate: HUBComponentChildDelegate?
    weak var animationPerformer: HUBAnimationPerformer?
    
    private lazy var toggleButton = UIButton()
    private var toggleButtonHeight: CGFloat { return 50 }
    private var childInfo: (model: HUBComponentModel, component: HUBComponent)?
    private var isExpanded = false

    var layoutTraits: Set<HUBComponentLayoutTrait> {
        return [.compactWidth]
    }

    func loadView() {
        toggleButton.backgroundColor = .gray
        toggleButton.addTarget(self, action: #selector(handleToggleButton), for: .touchUpInside)
        
        let containerview = UIView(frame: CGRect())
        containerview.clipsToBounds = true
        containerview.addSubview(toggleButton)
        view = containerview
    }

    func preferredViewSize(forDisplaying model: HUBComponentModel, containerViewSize: CGSize) -> CGSize {
        guard let childInfo = childInfo(forModel: model) else {
            return CGSize()
        }
        
        let childSize = childInfo.component.preferredViewSize(forDisplaying: childInfo.model, containerViewSize: containerViewSize)
        return CGSize(width: childSize.width, height: toggleButtonHeight)
    }

    func prepareViewForReuse() {
        childInfo?.component.view?.removeFromSuperview()
        childInfo = nil
    }

    func configureView(with model: HUBComponentModel, containerViewSize: CGSize) {
        toggleButton.setTitle(model.title, for: .normal)
        
        guard let childView = childInfo(forModel: model)?.component.view else {
            return
        }
        
        view?.addSubview(childView)
    }
    
    // MARK: - HUBComponentViewObserver
    
    func viewDidResize() {
        guard let view = view else {
            return
        }
        
        toggleButton.frame = CGRect(origin: CGPoint(), size: CGSize(width: view.frame.width, height: toggleButtonHeight))
        childInfo?.component.view?.frame.origin.y = toggleButtonHeight
    }
    
    func viewWillAppear() {
        // No-op
    }
    
    // MARK: - HUBComponentWithRestorableUIState
    
    func currentUIState() -> Any? {
        return isExpanded
    }
    
    func restoreUIState(_ state: Any) {
        isExpanded = (state as? Bool) ?? false
    }

    // MARK: - Private utilities
    
    private func childInfo(forModel model: HUBComponentModel) -> (model: HUBComponentModel, component: HUBComponent)? {
        if let childInfo = self.childInfo {
            return childInfo
        }
        
        guard let childModel = model.child(at: 0) else {
            return nil
        }
        
        guard let childComponent = childDelegate?.component(self, childComponentFor: childModel) else {
            return nil
        }
        
        let childInfo = (childModel, childComponent)
        self.childInfo = childInfo
        return childInfo
    }
    
    // MARK: - Target selectors
    
    @objc private func handleToggleButton() {
        
    }
}
