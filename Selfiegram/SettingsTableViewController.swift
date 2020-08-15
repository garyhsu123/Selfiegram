//
//  SettingsTableViewController.swift
//  Selfiegram
//
//  Created by Yu-Chun Hsu on 2020/7/24.
//  Copyright © 2020 Yu-Chun Hsu. All rights reserved.
//

import UIKit
import UserNotifications

class SettingsTableViewController: UITableViewController {


    @IBOutlet weak var locationSwitch: UISwitch!
    @IBOutlet weak var reminderSwtich: UISwitch!
    
    private let notificationId = "SelfiegramReminder"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationSwitch.isOn = UserDefaults.standard.bool(forKey: SettingsKey.saveLocation.rawValue)
        self.updateReminderSwitch()
    }

    // MARK: - UserNotification
    
    func addNotificationRequest() {
        let current = UNUserNotificationCenter.current()
        
        current.removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = "宇倫, 請起床吃早餐！"
        
        var components = DateComponents()
        components.setValue(10, for: Calendar.Component.hour)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
//        let trigger = UNTimeIntervalNotificationTrigger(timeInterval:10, repeats: false)
        
        let request = UNNotificationRequest(identifier: self.notificationId, content: content, trigger: trigger)
        
        current.add(request, withCompletionHandler: { (error) in
            self.updateReminderSwitch()
        })
    }
    
    // MARK: - Private
    
    func updateReminderSwitch() {
        UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
            switch settings.authorizationStatus {
            case .authorized:
                UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (requests) in
                    let active = requests.filter({ $0.identifier == self.notificationId }).count > 0
                        
                    self.updateReminderUI(enabled: true, active: active)
                })
            case .denied:
                self.updateReminderUI(enabled: false, active: false)
            case .notDetermined:
                self.updateReminderUI(enabled: true, active: false)
            default:
                break
            }
        })
    }
    
    private func updateReminderUI(enabled:Bool, active:Bool) {
        OperationQueue.main.addOperation {
            self.reminderSwtich.isEnabled = enabled
            self.reminderSwtich.isOn = active
        }
    }
    // MARK: - IBAction
    
    @IBAction func locationSwitchToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(locationSwitch.isOn, forKey: SettingsKey.saveLocation.rawValue)
    }
    
    
    @IBAction func reminderSwitchToggled(_ sender: Any) {
        let current = UNUserNotificationCenter.current()
        switch reminderSwtich.isOn {
        case true:
            let notificationOptions : UNAuthorizationOptions = [.alert]
            
            current.requestAuthorization(options: notificationOptions, completionHandler: { (granted, error) in
                if granted {
                    self.addNotificationRequest()
                }
                self.updateReminderSwitch()
            })
        case false:
            current.removeAllPendingNotificationRequests()
        }
    }
    

}

enum SettingsKey : String {
    case saveLocation
}
