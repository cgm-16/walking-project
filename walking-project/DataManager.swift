//
//  DataManager.swift
//  walking-project
//
//  Created by GMC on 2023/01/25.
//

import CoreData

struct DataManager {
    static let shared = DataManager()

    // MARK: - Remove in production - Placeholder only !!!!
    static var preview: DataManager = {
        let result = DataManager(inMemory: true)
        let viewContext = result.container.viewContext
        
        let Names: [String] = ["J.J.Won", "CWK", "J.H.Seong", "S.M.Kim", "C.W.Kim", "G.M.Choi"]
        let UUIDs: [UUID] = [UUID(), UUID(), UUID(), UUID(), UUID(), UUID()]
        let scores: [Int64] = [576100, 700000, 710800, 759500, 963200, 1274000]
        
        let myWalk = My_Walk(context: viewContext)
        
        myWalk.my_id = UUIDs[5]
        myWalk.calories = 237
        myWalk.total_walk = 12303
        myWalk.distance = 13.8
        myWalk.current_point = 160300
        
        
        for i in 0..<6 {
            let walkInfo = Walk_Info(context: viewContext)
            walkInfo.name = Names[i]
            walkInfo.id = UUIDs[i]
            walkInfo.score = scores[i]
            walkInfo.rank = Int16(6-i)
        }
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "walking_project")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.

                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
