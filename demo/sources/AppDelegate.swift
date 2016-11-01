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

import UIKit
import HubFramework

/// The delegate of the application
@UIApplicationMain class AppDelegate: UIResponder, UIApplicationDelegate, HUBLiveServiceDelegate {
    var window: UIWindow?
    var navigationController: UINavigationController!
    var hubManager: HUBManager!
    
    // MARK: - UIApplicationDelegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        setup()
        
        let viewController = hubManager.viewControllerFactory.createViewController(
            forViewURI: URL(string: "beautiful-cities:root")!,
            contentOperations: [BeautifulCitiesContentOperation()],
            featureIdentifier: "beautiful-cities",
            featureTitle: "Beautiful Cities"
        )
        
        prepareAndPush(viewController: viewController, animated: false)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        return open(viewURI: url, animated: true)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        startLiveService()
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        hubManager.liveService?.stop()
    }
    
    // MARK: - HUBLiveServiceDelegate
    
    func liveService(_ liveService: HUBLiveService, didCreateViewController viewController: UIViewController) {
        prepareAndPush(viewController: viewController, animated: true)
    }
    
    // MARK: - Private
    
    private func setup() {
        let window = UIWindow(frame: UIScreen.main.bounds)
        
        self.window = window
        navigationController = UINavigationController()
        
        hubManager = makeHubManager()
        
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        
        registerDefaultComponentFactory()
        startLiveService()
    }
    
    private func makeHubManager() -> HUBManager {
        return HUBManager(
            componentLayoutManager: ComponentLayoutManager(),
            componentFallbackHandler: ComponentFallbackHandler()
        )
    }
    
    private func registerDefaultComponentFactory() {
        hubManager.componentRegistry.register(componentFactory: DefaultComponentFactory(), namespace: DefaultComponentFactory.namespace)
    }
    
    private func startLiveService() {
        #if DEBUG
        hubManager.liveService?.delegate = self
        hubManager.liveService?.start(onPort: 7777)
        #endif
    }
    
    // MARK: - Opening view URIs
    
    @discardableResult private func open(viewURI: URL, animated: Bool) -> Bool {
        guard let viewController = hubManager?.viewControllerFactory.createViewController(forViewURI: viewURI) else {
            return false
        }
        
        prepareAndPush(viewController: viewController, animated: animated)
        
        return true
    }
    
    // MARK: - View controller handling
    
    private func prepareAndPush(viewController: UIViewController, animated: Bool) {
        viewController.view.backgroundColor = .white
        navigationController?.pushViewController(viewController, animated: animated)
    }
}

