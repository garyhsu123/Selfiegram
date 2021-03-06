//
//  MasterViewController.swift
//  Selfiegram
//
//  Created by Yu-Chun Hsu on 2020/7/4.
//  Copyright © 2020 Yu-Chun Hsu. All rights reserved.
//

import UIKit
import CoreLocation

class SelfieListViewController: UITableViewController {

    var lastLocation : CLLocation?
    let locationManager = CLLocationManager()
    
    var detailViewController: SelfieDetailViewController? = nil
    var selfies:[Selfie] = []
    let timeIntervalFormatter:DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .spellOut
        formatter.maximumUnitCount = 1
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.initTopBar()
        
        do {
            selfies = try SelfieStore.shared.listSelfies().sorted(by: {$0.created > $1.created})
        } catch let error {
            showError(message: "Failed to load selfies: \(error.localizedDescription)")
        }
        
        if let split = splitViewController {
            let controllers = split.viewControllers
            detailViewController = (controllers[controllers.count-1] as? UINavigationController)?.topViewController as? SelfieDetailViewController
        }
        
        
    }

    override func viewWillAppear(_ animated: Bool) {
        clearsSelectionOnViewWillAppear = splitViewController!.isCollapsed
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Init
    
    func initTopBar()
    {
        let addSelfieButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createNewSelfie))
        
        navigationItem.rightBarButtonItem = addSelfieButton
    }
    
    func initCamera()
    {
       
    }
    
    // MARK: - Private
    
    func showError(message:String)
    {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    @objc func createNewSelfie()
    {
        lastLocation = nil
        
        let shouldGetLocation = UserDefaults.standard.bool(forKey: SettingsKey.saveLocation.rawValue)
        
        if (shouldGetLocation) {
            switch CLLocationManager.authorizationStatus() {
            case .denied, .restricted:
                return
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            default:
                break
            }
            
            self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.delegate = self
            locationManager.requestLocation()
        
        }
            
        // CaptureViewController
        
        guard let navigation = self.storyboard?.instantiateViewController(withIdentifier: "CaptureScene") as? UINavigationController, let capture = navigation.viewControllers.first as? CaptureViewController else {
            fatalError("Failed to create the capture view controller!")
        }
        
        capture.completion = {(image: UIImage?) in
            if let image = image {
                self.newSelfieTaken(image: image)
            }
            
            self.dismiss(animated: true, completion: nil)
        }
        
        self.present(navigation, animated: true, completion: nil)
    }

    //MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.lastLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        showError(message: error.localizedDescription)
    }
    
    
    
    // MARK: - Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selfies.count
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let share = UIContextualAction(style: .normal, title: "Share") { (action, view, boolValue) in
            guard let image = self.selfies[indexPath.row].image else {
                self.showError(message: "Unable to share selfie without an image")
                return
            }
            let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            
            self.present(activity, animated: true, completion: nil)
        }
        
        share.backgroundColor = self.view.tintColor
        
        let delete = UIContextualAction(style: .destructive, title: "Delete") { (action, view, boolValue) in
            let selfieToRemove = self.selfies[indexPath.row]
            
            do
            {
                try SelfieStore.shared.delete(selfie: selfieToRemove)
                
                self.selfies.remove(at: indexPath.row)
                
                tableView.deleteRows(at: [indexPath], with: .fade)
            }
            catch
            {
                self.showError(message: "Failed to delete \(selfieToRemove.title).")
            }
        }
        return UISwipeActionsConfiguration(actions: [delete, share])
    }
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        let selfie = selfies[indexPath.row]
        cell.textLabel!.text = selfie.title
        
        if let interval = timeIntervalFormatter.string(from: selfie.created, to: Date()) {
            cell.detailTextLabel?.text = "\(interval) ago"
        }
        else {
            cell.detailTextLabel?.text = nil
        }
        cell.imageView?.image = selfie.image
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let selfieToRemove = selfies[indexPath.row]
            
            do {
                try SelfieStore.shared.delete(selfie: selfieToRemove)
                
                selfies.remove(at: indexPath.row)
                
                tableView.deleteRows(at: [indexPath], with: .fade)
            } catch {
                let title = selfieToRemove.title
                showError(message: "Failed to delete \(title)")
            }
        }
    }
    
    // MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let selfie = selfies[indexPath.row]
                if let controller = (segue.destination as? UINavigationController)?.topViewController as? SelfieDetailViewController {
                    controller.selfie = selfie
                    controller.navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem
                    controller.navigationItem.leftItemsSupplementBackButton = true
                    
                }
            }
        }
    }
}

extension SelfieListViewController : UINavigationControllerDelegate {
    // MARK: - UIImagePickerControllerDelegate
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        self.dismiss(animated: true, completion: nil)
    }

    func newSelfieTaken(image: UIImage)
    {
        let newSelfie = Selfie(title: "New Selfie")
        
        newSelfie.image = image
        
        if let location = self.lastLocation {
            newSelfie.position = Selfie.Coordinate(location: location)
        }
        
        do {
            try SelfieStore.shared.save(selfie: newSelfie)
        } catch let error {
            showError(message: "Can't save photo: \(error)")
            return
        }
        
        selfies.insert(newSelfie, at: 0)
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
    }
}

extension SelfieListViewController : CLLocationManagerDelegate {
    
}
