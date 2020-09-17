//
//  OverlayStore.swift
//  Selfiegram
//
//  Created by Yu-Chun Hsu on 2020/8/26.
//  Copyright © 2020 Yu-Chun Hsu. All rights reserved.
//

import UIKit.UIImage

struct OverlayInformation: Codable {
    let icon: String
    let leftImage: String
    let rightImage: String
}

enum OverlayManagerError: Error {
    case notDataLoaded
    case cannotParseData(underlyingError: Error)
}

final class OverlayManager {
    static let shared = OverlayManager()
    
    typealias OverlayList = [OverlayInformation]
    private var overlayInfo: OverlayList
    
    private let loadingDispatchGroup = DispatchGroup()
    
    static let downloadURLBase = URL(string: "https://raw.githubusercontent.com/thesecretlab/learning-swift-3rd-ed/master/Data/")!
    class var overlayListUrl: URL {
        return URL(string: "overlays.json",
        relativeTo: OverlayManager.downloadURLBase)!
    }
    
    static var cacheDirectoryURL: URL {
        guard let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            fatalError("Cache directory not found! This should not happen!")
        }
        return cacheDirectory
    }
    
    static var cacheOverlayListURL: URL {
        return cacheDirectoryURL.appendingPathComponent("overlays.json", isDirectory: false)
    }
    
    init() {
        do {
            let overlayListData = try Data(contentsOf: OverlayManager.cacheOverlayListURL)
            self.overlayInfo = try JSONDecoder().decode(OverlayList.self, from: overlayListData)
        } catch {
            self.overlayInfo = []
        }
    }
    
    func urlForAsset(named assetName: String) -> URL? {
        return URL(string: assetName, relativeTo: OverlayManager.downloadURLBase)
    }
    
    func cachedUrlForAsset(named assetName: String) -> URL? {
        return URL(string: assetName, relativeTo: OverlayManager.cacheDirectoryURL)
    }
    
    func availableOverlays() -> [Overlay]
    {
        return overlayInfo.compactMap{Overlay(info: $0)}
    }
    
    func refreshOverlays(completion: @escaping (OverlayList?, Error?) -> Void) {
        URLSession.shared.dataTask(with: OverlayManager.overlayListUrl, completionHandler: { (data, response , error) in
            if let error = error {
                NSLog("Failed to download \(OverlayManager.overlayListUrl): "
                     + "\(error)")
                completion(nil, error)
                return
            }
            
            guard let data = data else {
                completion(nil, OverlayManagerError.notDataLoaded)
                return
            }
            
            do {
                try data.write(to: OverlayManager.cacheOverlayListURL)
            } catch let error {
                NSLog("Failed to write data to \(OverlayManager.cacheOverlayListURL); reason: \(error)")
                completion(nil, error)
            }
            
            do {
                let overlayList = try JSONDecoder().decode(OverlayList.self, from: data)
                
                self.overlayInfo = overlayList
                
                completion(self.overlayInfo, nil)
                return
            } catch let error {
                completion(nil, OverlayManagerError.cannotParseData(underlyingError: error))
            }
            }).resume()
    }
    
    func loadOverlayAssets(refresh: Bool = false, completion: @escaping() -> Void) {
        if (refresh) {
            self.refreshOverlays { (overlays, error) in
                self.loadOverlayAssets(refresh: false, completion: completion)
            }
            return
        }
        
        for info in overlayInfo {
            let names = [info.icon, info.leftImage, info.rightImage]
            
            typealias TaskURL = (source: URL, destination: URL)
            
            let taskURLs: [TaskURL] = names.compactMap {
                guard let sourceURL = URL(string: $0, relativeTo: OverlayManager.downloadURLBase) else {
                    return nil
                }
                
                guard let destinationURL = URL(string: $0, relativeTo:  OverlayManager.cacheDirectoryURL) else {
                    return nil
                }
                
                return (source: sourceURL, destination: destinationURL)
            }
            
            for taskURL in taskURLs {
                loadingDispatchGroup.enter()
                
                URLSession.shared.dataTask(with: taskURL.source, completionHandler: { (data, response, error) in
                    defer {
                        self.loadingDispatchGroup.leave()
                    }
                    
                    guard let data = data else {
                        NSLog("Failed to download \(taskURL.source): \(error!)")
                        return
                    }
                    
                    do {
                        try data.write(to: taskURL.destination)
                    } catch let error {
                        NSLog("Failed to write to \(taskURL.destination): \(error)")
                        return
                    }
                    }).resume()
            }
            
            
            
                
        }
        
        loadingDispatchGroup.notify(queue: .main) {
            completion()
        }
    }
}

struct Overlay {
    let previewIcon: UIImage
    
    let leftImage: UIImage
    let rightImage: UIImage
    
    init?(info: OverlayInformation) {
        guard let previewURL = OverlayManager.shared.cachedUrlForAsset(named: info.icon), let leftURL = OverlayManager.shared.cachedUrlForAsset(named: info.leftImage), let rightURL = OverlayManager.shared.cachedUrlForAsset(named: info.rightImage) else {
            return nil
        }
        
        guard let previewImage = UIImage(contentsOfFile: previewURL.path), let leftImage = UIImage(contentsOfFile: leftURL.path), let rightImage = UIImage(contentsOfFile: rightURL.path) else {
            return nil
        }
        
        self.previewIcon = previewImage
        self.leftImage = leftImage
        self.rightImage = rightImage
    } 
}
class OverlayStore: NSObject {

}
