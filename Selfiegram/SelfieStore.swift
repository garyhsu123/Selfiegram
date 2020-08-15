//
//  SelfieStore.swift
//  Selfiegram
//
//  Created by Yu-Chun Hsu on 2020/7/6.
//  Copyright © 2020 Yu-Chun Hsu. All rights reserved.
//

import Foundation
import UIKit.UIImage
import CoreLocation.CLLocation

class Selfie:Codable
{
    struct Coordinate : Codable, Equatable
    {
        var latitude : Double
        var longitude : Double
        
        public static func == (lhs: Selfie.Coordinate, rhs: Selfie.Coordinate) -> Bool
        {
            return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
        }
        
        var location : CLLocation
        {
            get {
                return CLLocation(latitude: self.latitude, longitude: self.longitude)
            }
            
            set {
                self.latitude = newValue.coordinate.latitude
                self.longitude = newValue.coordinate.longitude
            }
        }
        
        init(location : CLLocation) {
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
        }
        
    }
    
    let created:Date
    let id:UUID
    var title = "New Selfie!"
    var position : Coordinate?
    
    var image:UIImage?
    {
        get
        {
            return SelfieStore.shared.getImage(id:self.id)
        }
        set
        {
            try?SelfieStore.shared.setImage(id: self.id, image: newValue)
        }
    }
    
    
    
    init(title:String) {
        self.title = title
        self.created = Date()
        self.id = UUID()
    }
}

enum SelfieStoreError:Error
{
    case cannotSaveImage(UIImage?)
}

final class SelfieStore
{
    static let shared = SelfieStore()
    
    private var imageCache:[UUID:UIImage?] = [:]
    var documentsFolder:URL
    {
        return FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first!
    }
    
    func getImage(id:UUID) -> UIImage?
    {
        if let image = imageCache[id] {
            return image
        }
        
        let imageURL = documentsFolder.appendingPathComponent("\(id.uuidString)-image.jpg")
        
        guard let imageData = try? Data(contentsOf: imageURL) else { return nil }
        
        guard let image = UIImage(data: imageData) else { return nil}
        
        imageCache[id] = image
        
        return image
    }
    
    func setImage(id:UUID, image:UIImage?) throws {
        
        let fileName = "\(id.uuidString)-image.jpg"
        let destinationURL = documentsFolder.appendingPathComponent(fileName)
        
        if let image = image {
            guard let data = image.jpegData(compressionQuality: 0.9) else {
                throw SelfieStoreError.cannotSaveImage(image)
            }
            
            try data.write(to: destinationURL)
        }
        else {
            try FileManager.default.removeItem(at: destinationURL)
        }
        
        imageCache[id] = image
    }
    
    func listSelfies() throws -> [Selfie] {
        let contents = try FileManager.default.contentsOfDirectory(at: self.documentsFolder, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
        return try contents.filter {$0.pathExtension == "json"}
            .map{try Data.init(contentsOf: $0)}
            .map{try JSONDecoder().decode(Selfie.self, from: $0)}
    }
    
    func delete(selfie:Selfie) throws {
        try delete(id: selfie.id)
    }
    
    func delete(id:UUID) throws {
        let selfieDataFileName = "\(id.uuidString).json"
        let imageFileName = "\(id.uuidString)-image.jpg"
        
        let selfieDataURL = self.documentsFolder.appendingPathComponent(selfieDataFileName)
        let imageURL = self.documentsFolder.appendingPathComponent(imageFileName)
        
        if FileManager.default.fileExists(atPath: selfieDataURL.path) {
            try FileManager.default.removeItem(at: selfieDataURL)
        }
        
        if FileManager.default.fileExists(atPath: imageURL.path) {
            try FileManager.default.removeItem(at: imageURL)
        }
        
        imageCache[id] = nil
    }
    
    func load(id:UUID) -> Selfie? {
        let dataFileName = "\(id.uuidString).json"
        
        let dataURL = self.documentsFolder.appendingPathComponent(dataFileName)
        
        if let data = try? Data.init(contentsOf: dataURL), let selfie = try? JSONDecoder().decode(Selfie.self, from: data) {
            return selfie
        }
        else {
            return nil
        }
    }
    
    func save(selfie:Selfie) throws {
        let selfieData = try JSONEncoder().encode(selfie)
        
        let fileName = "\(selfie.id.uuidString).json"
        
        let destinationURL = self.documentsFolder.appendingPathComponent(fileName)
        
        try selfieData.write(to: destinationURL)
    }
}


