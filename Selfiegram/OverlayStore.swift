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
    
    static let downloadURLBase = URL(string: "https://raw.githubusercontent.com"
    + "thesecretlab/learning-swift-3rd-ed/master/Data/")!
    class var overlayListUrl: URL {
        return URL(string: "overlay.json",
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
    
    func availableOverlays() -> [Overlay] { return [] }
    func refreshOverlays(completion: @escaping (OverlayList?, Error?) -> Void) {}
    func loadOverlayAssets(refresh: Bool = false, completion: @escaping() -> Void) {}
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
