//
//  MessageController.swift
//  CKBulletinBoard
//
//  Created by Jordan Hendrickson on 6/3/19.
//  Copyright © 2019 Jordan Hendrickson. All rights reserved.
//

import Foundation
import CloudKit

class MessageController {

    //Singleton
    static let shared = MessageController()
    //Source of Truth
    var messages: [Message] = []
    //database
    let privateDB = CKContainer.default().privateCloudDatabase
    
    //CRUD Functions
    //Create
    func createMessage(text:String , timestamp: Date, completion: @escaping (Bool)-> Void) {
        let message = Message(text: text, timestamp: timestamp)
        
        self.saveMessage(message: message, completion: completion)
            //Bad Error Handling
            
        }
    //Remove - Delete
    func removeMessage(message: Message, completion: @escaping (Bool) -> ()) {
        guard let index = MessageController.shared.messages.firstIndex(of: message) else {return}
        MessageController.shared.messages.remove(at: index)
        privateDB.delete(withRecordID: message.ckRecordID) { (_, error) in
            if let error = error{
            print("you got some errors\(#function) ; \(error) ; \(error.localizedDescription)")
            completion(false)
            return
            }else{
                print("Message Deleted")
                completion(true)
            }
        }
        
    }
    //Save
    func saveMessage(message: Message, completion: @escaping (Bool) -> ()){
        let messageRecord = CKRecord(message: message)
        privateDB.save(messageRecord) { (record, error) in
            if let error = error {
                print("you got some errors\(#function) ; \(error) ; \(error.localizedDescription)")
                completion(false)
                return
            }
            guard let record = record, let message = Message(ckRecord: record) else {completion(false);return}
            self.messages.insert(message, at: 0)
            completion(true)
            //record exists
        }
    }
    //Load
    func fetchMessages(completion: @escaping (Bool) -> ()){
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: Constants.recordKey, predicate: predicate)
        
        privateDB.perform(query, inZoneWith: nil) { (records, error) in
            if let error = error {
                print("you got some errors\(#function) ; \(error) ; \(error.localizedDescription)")
                completion(false)
                return
            }
            guard let records = records else {completion(false); return}
            var messages = records.compactMap({Message(ckRecord: $0)})
            messages.sort{ $0.timestamp > $1.timestamp }
            self.messages = messages
            completion(true)
        }
    }
    //subsciption
    func subscribeToNotifications(completion: @escaping (Error?) -> Void) {
        let predicate = NSPredicate(value: true)
        
        let subscription = CKQuerySubscription(recordType: Constants.recordKey, predicate: predicate, options: .firesOnRecordCreation)
        
        let notificationInfo = CKSubscription.NotificationInfo()
        
        notificationInfo.alertBody = "New Post Big Boy! Go check it out."
        notificationInfo.shouldBadge = true
        notificationInfo.soundName = "default"
        
        subscription.notificationInfo = notificationInfo
        
        privateDB.save(subscription) { (_, error) in
            if let error = error {
                print("subscription did not save: \(error.localizedDescription)")
                completion(error)
                return
            }
            completion(nil)
        }
        
    }
}//End of class
