//
//  DataManager.swift
//  walking-project
//
//  Created by GMC on 2023/01/25.
//

import CoreData
import HealthKit

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
        myWalk.my_id = UUIDs[4]
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

    static var healthDataManager: DataManager = {
        let result = DataManager(inMemory: false)
        let viewContext = result.container.viewContext
        let myWalk = My_Walk(context: viewContext)
        let healthStore = HKHealthStore()
        let dataTypes = Set([HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!])

        if HKHealthStore.isHealthDataAvailable() {
            let energyBurned = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!
            let stepCount = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!
            let totalDistance = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier.distanceWalkingRunning)!
            let calendar = NSCalendar.current
            let now = Date()
            let components = calendar.dateComponents([.year, .month, .day], from: now)
            let startDate = calendar.date(from: components)!
            let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
            let today = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let interval = DateComponents(minute: 5)
            
            let energyQuery = HKStatisticsQuery(quantityType: energyBurned, quantitySamplePredicate: today, options: .cumulativeSum) { (query, statisticsOrNil, errorOrNil) in
                
                guard let statistics = statisticsOrNil else {
                    // Handle any errors here.
                    return
                }
                
                let sum = statistics.sumQuantity()!
                myWalk.calories = Int64(lround(sum.doubleValue(for: HKUnit.largeCalorie())))
            }
            
            let stepQuery = HKStatisticsQuery(quantityType: stepCount, quantitySamplePredicate: today, options: .cumulativeSum) { (query, statisticsOrNil, errorOrNil) in
                
                guard let statistics = statisticsOrNil else {
                    // Handle any errors here.
                    return
                }
                
                let sum = statistics.sumQuantity()!
                myWalk.total_walk = Int64(lround(sum.doubleValue(for: .count())))
                
            }
            
            let distQuery = HKStatisticsQuery(quantityType: totalDistance, quantitySamplePredicate: today, options: .cumulativeSum) { (query, statisticsOrNil, errorOrNil) in
                
                guard let statistics = statisticsOrNil else {
                    // Handle any errors here.
                    return
                }
                
                let sum = statistics.sumQuantity()!
                myWalk.distance = sum.doubleValue(for: .meterUnit(with: .kilo))
            }
            
            let pointQuery = HKStatisticsCollectionQuery(quantityType: stepCount, quantitySamplePredicate: nil, anchorDate: startDate, intervalComponents: interval)
            
            pointQuery.initialResultsHandler = {
                query, results, error in
                    
                // Handle errors here.
                if let error = error as? HKError {
                    switch (error.code) {
                    case .errorDatabaseInaccessible:
                        // HealthKit couldn't access the database because the device is locked.
                        return
                    default:
                        // Handle other HealthKit errors here.
                        return
                    }
                }
                
                guard let statsCollection = results else {
                    // You should only hit this case if you have an unhandled error. Check for bugs
                    // in your code that creates the query, or explicitly handle the error.
                    assertionFailure("")
                    return
                }
                
                let timeFetchReq = Fever_Times.fetchRequest()
                /*do {
                    let feverTimes = try timeFetchReq.execute() as [Fever_Times]
                    if true {
                        var score = 0
                        statsCollection.enumerateStatistics(from: startDate, to: now)
                        { (statistics, stop) in
                            if let quantity = statistics.sumQuantity() {
                                let value = quantity.doubleValue(for: .count())
                                score += lround(value)
                                myWalk.current_point = Int64(score)
                            }
                        }
                    } else {
                        var score = 0
                        var times : [DateComponents] = []
                        
                        // Example : "15:20-16:20"
                        for timeRange in feverTimes[times] {
                        }
                        // Enumerate over all the statistics objects between the start and end dates.
                        statsCollection.enumerateStatistics(from: startDate, to: now)
                        { (statistics, stop) in
                            if let quantity = statistics.sumQuantity() {
                                let value = quantity.doubleValue(for: .count())
                            }
                        }
                    }
                    
                } catch {
                }*/
            }
        } else {
            healthStore.requestAuthorization(toShare: [], read: dataTypes) { (success, error) in
                if !success {
                    fatalError("Unresolved error \(error.debugDescription)")
                }
            }
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
    
    static var DBManager: DataManager = {
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
