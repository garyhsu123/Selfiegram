//
//  DetailViewController.swift
//  Selfiegram
//
//  Created by Yu-Chun Hsu on 2020/7/4.
//  Copyright © 2020 Yu-Chun Hsu. All rights reserved.
//

import UIKit
import MapKit
import CoreImage.CIFilterBuiltins

class SelfieDetailViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var dateCreatedLabel
    : UILabel!
    @IBOutlet weak var selfieNameField: UITextField!
    @IBOutlet weak var selfieImageView: UIImageView!
    @IBOutlet weak var mapview: MKMapView!
    
    
    
    
    let dateFormatter = {() -> DateFormatter in
        let d = DateFormatter()
        d.dateStyle = .short
        d.timeStyle = .short
        return d
    }()
    
    var selfie: Selfie? {
        didSet {
            configureView()
        }
    }
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        configureView()
    }

    func configureView() {
        guard let selfie = selfie else {
            return
        }
        
        guard let selfieNameField = selfieNameField, let selfieImageView = selfieImageView, let dateCreatedLabel = dateCreatedLabel else {
            return
        }
        
        self.selfieNameField.delegate = self
        selfieNameField.text = selfie.title
        dateCreatedLabel.text = dateFormatter.string(from:selfie.created)
//        selfieImageView.image = self.downScaleImage(inputImage: selfie.image)
        selfieImageView.image = selfie.image
        
        if let position = selfie.position {
            self.mapview.setCenter(position.location.coordinate, animated: false)
            mapview.isHidden = false
        }
    }

    // MARK: - Private
    
//    func isValid(str: String) -> Bool
//    {
//        let string = "[^<>\\/\\|%\\\\‘“]*";
//        let displayNameTest = NSPredicate.init(format: "SELF MATCHES %@", string)
//        return displayNameTest.evaluate(with: str)
//    }
    
    //MARK: - IBAction

    @IBAction func doneButtonTapped(_ sender: Any)
    {
        self.selfieNameField.resignFirstResponder()
        guard let selfie = selfie else {
            return
        }
        
        guard let text = selfieNameField?.text else {
            return
        }
        
        selfie.title = text
        
        try? SelfieStore.shared.save(selfie: selfie)
    }
    
    @IBAction func expandMap(_ sender: Any)
    {
        if let coordinate = self.selfie?.position {
            let options = [ MKLaunchOptionsMapCenterKey:NSValue(mkCoordinate: coordinate.location.coordinate), MKLaunchOptionsMapTypeKey: NSNumber(value: MKMapType.mutedStandard.rawValue)]
            
            let placemark = MKPlacemark(coordinate: coordinate.location.coordinate, addressDictionary: nil)
            let item = MKMapItem(placemark: placemark)
            item.name = selfie?.title
            
            item.openInMaps(launchOptions: options)
            
        }
    }
    
    @IBAction func sharedSelfie(_ sender: Any)
    {
        guard let image = self.selfie?.image else {
            let alert = UIAlertController(title: "Error", message: "Unable to share selfie without an image", preferredStyle: .alert)
            
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            
                alert.addAction(action)
            
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        self.present(activity, animated: true, completion: nil)
    }
    
    override func didChangeValue(forKey key: String) {
        print("hello")
    }
    
    //MARK: - CoreImage -
    func downScaleImage(inputImage: UIImage?) -> UIImage?
    {
        guard let inputImage = inputImage else {
            return nil
        }
        let f = CIFilter.lanczosScaleTransform()
        f.inputImage = CIImage(image: inputImage)
        f.scale = 0.01
        return UIImage(ciImage: f.outputImage!)
    
    }
}

