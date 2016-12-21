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

/// Content operation used by the "Todo list" feature
class TodoListContentOperation: NSObject, HUBContentOperationActionPerformer, HUBContentOperationActionObserver {
    weak var delegate: HUBContentOperationDelegate?
    weak var actionPerformer: HUBActionPerformer?
    private var addActionIdentifier: HUBIdentifier {
        return HUBIdentifier(namespace: TodoListActionFactory.namespace, name: TodoListActionNames.addCompleted)
    }
    private var filterActionIdentifier: HUBIdentifier {
        return HUBIdentifier(namespace: TodoListActionFactory.namespace, name: "filter")
    }
    private var markActionIdentifier: HUBIdentifier {
        return HUBIdentifier(namespace: TodoListActionFactory.namespace, name: "mark")
    }
    private var filter: String?
    private var transitionDuration = TimeInterval(0)
    private lazy var items = [String]()
    private lazy var markedItemIndexes = Set<UInt>()

    func perform(forViewURI viewURI: URL, featureInfo: HUBFeatureInfo, connectivityState: HUBConnectivityState, viewModelBuilder: HUBViewModelBuilder, previousError: Error?) {
        if markedItemIndexes.isEmpty {
            viewModelBuilder.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleAddButton))
        } else {
            let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(handleDoneButton))
            let deleteButton = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(handleDeleteButton))
            viewModelBuilder.navigationItem.rightBarButtonItems = [doneButton, deleteButton]
        }
        
        // Add a search bar if we have at least one item
        if !items.isEmpty {
            let searchBarBuilder = viewModelBuilder.builderForBodyComponentModel(withIdentifier: "searchBar")
            searchBarBuilder.componentName = DefaultComponentNames.searchBar
            searchBarBuilder.customData = [
                SearchBarComponentCustomDataKeys.placeholder: "Filter your todo items",
                SearchBarComponentCustomDataKeys.actionIdentifier: filterActionIdentifier.identifierString,
                SearchBarComponentCustomDataKeys.actionDelay: 0
            ]
        }
        
        items.enumerated().forEach { index, item in
            if let filter = self.filter {
                if !item.lowercased().contains(filter) {
                    return
                }
            }
            
            let itemRowBuilder = viewModelBuilder.builderForBodyComponentModel(withIdentifier: "item-\(index)")
            itemRowBuilder.title = item
            itemRowBuilder.targetBuilder.actionIdentifiers.add(markActionIdentifier)
            
            var customData = itemRowBuilder.customData ?? [:]
            customData[RowComponent.CustomDataKeys.marked] = markedItemIndexes.contains(UInt(index))
            itemRowBuilder.customData = customData
        }
        
        viewModelBuilder.transitionDuration = transitionDuration
        transitionDuration = 0
        
        delegate?.contentOperationDidFinish(self)
    }
    
    func actionPerformed(with context: HUBActionContext, featureInfo: HUBFeatureInfo, connectivityState: HUBConnectivityState) {
        if !handleAddAction(withContext: context) {
            if !handleFilterAction(withContext: context) {
                if !handleMarkAction(withContext: context) {
                    return
                }
            }
        }
        
        delegate?.contentOperationRequiresRescheduling(self)
    }
    
    // MARK: - Private
    
    private func handleAddAction(withContext context: HUBActionContext) -> Bool {
        guard context.customActionIdentifier == addActionIdentifier else {
            return false
        }
        
        if let itemTitle = context.customData?[TodoListAddActionCustomDataKeys.itemTitle] as? String {
            items.append(itemTitle)
        }
        
        return true
    }
    
    private func handleFilterAction(withContext context: HUBActionContext) -> Bool {
        guard context.customActionIdentifier == filterActionIdentifier else {
            return false
        }
        
        if let filter = context.customData?[SearchBarComponentCustomDataKeys.text] as? String {
            self.filter = filter.isEmpty ? nil : filter.lowercased()
        } else {
            self.filter = nil
        }
        
        return true
    }
    
    private func handleMarkAction(withContext context: HUBActionContext) -> Bool {
        guard context.customActionIdentifier == markActionIdentifier else {
            return false
        }
        
        guard let index = context.componentModel?.index else {
            return false
        }
        
        let relativeIndex = index - 1
        
        if markedItemIndexes.remove(relativeIndex) == nil {
            markedItemIndexes.insert(relativeIndex)
        }
        
        return true
    }
    
    @objc private func handleAddButton() {
        let actionIdentifier = HUBIdentifier(namespace: TodoListActionFactory.namespace, name: TodoListActionNames.add)
        actionPerformer?.performAction(withIdentifier: actionIdentifier, customData: nil)
    }
    
    @objc private func handleDoneButton() {
        markedItemIndexes = []
        delegate?.contentOperationRequiresRescheduling(self)
    }
    
    @objc private func handleDeleteButton() {
        items = items.enumerated().flatMap { (index, item) in
            return markedItemIndexes.contains(UInt(index)) ? nil : item
        }
        
        markedItemIndexes = []
        transitionDuration = 1
        delegate?.contentOperationRequiresRescheduling(self)
    }
}
