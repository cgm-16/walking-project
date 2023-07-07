//
//  HealthDataManager.swift
//  walking-project
//
//  Created by GMC on 2023/06/02.
//

import Foundation
import HealthKit

// Global Constants
private let FEVERMULTI = 2
private let STEPSTOPOINTS = 100
private let CALORIEPERSTEPMULTI = 0.00053

func HKRequestAuth() async {
    let healthStore = DataManager.shared.healthstore
    
    let dataTypes = Set([HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                         HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                         HKObjectType.quantityType(forIdentifier: .stepCount)!])
    
    guard HKHealthStore.isHealthDataAvailable() else {
        return
    }
    
    do {
        try await healthStore.requestAuthorization(toShare: [], read: dataTypes)
    } catch {
        fatalError(error.localizedDescription)
    }
}

private func stepEnergyQuery(pred: String) async throws -> (HKStatistics?) {
    return try await withCheckedThrowingContinuation { continuation in
        let healthStore = DataManager.shared.healthstore
        let stepCount = HKSampleType.quantityType(forIdentifier: .stepCount)!
        let autoAndToday = NSPredicate(format: pred)
        let devicePredicate = HKQuery.predicateForObjects(withDeviceProperty: HKDevicePropertyKeyModel, allowedValues: [HKDevice.local().model!])
        let pred = NSCompoundPredicate(andPredicateWithSubpredicates: [autoAndToday, devicePredicate])
        
        let stepEnergyQuery = HKStatisticsQuery(
            quantityType: stepCount,
            quantitySamplePredicate: pred,
            options: .cumulativeSum) { (query, statisticsOrNil, errorOrNil) in
                if let error = errorOrNil {
                    continuation.resume(throwing: error)
                } else if let statistics = statisticsOrNil {
                    continuation.resume(returning: statistics)
                }
            }
        healthStore.execute(stepEnergyQuery)
    }
}

private func distQuery(pred: String) async throws -> (HKStatistics?) {
    return try await withCheckedThrowingContinuation { continuation in
        let healthStore = DataManager.shared.healthstore
        let totalDistance = HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!
        let autoAndToday = NSPredicate(format: pred)
        let devicePredicate = HKQuery.predicateForObjects(withDeviceProperty: HKDevicePropertyKeyModel, allowedValues: [HKDevice.local().model!])
        let pred = NSCompoundPredicate(andPredicateWithSubpredicates: [autoAndToday, devicePredicate])
        
        let distQuery = HKStatisticsQuery(
            quantityType: totalDistance,
            quantitySamplePredicate: pred,
            options: .cumulativeSum) { (query, statisticsOrNil, errorOrNil) in
                if let error = errorOrNil {
                    continuation.resume(throwing: error)
                } else if let statistics = statisticsOrNil {
                    continuation.resume(returning: statistics)
                }
            }
        healthStore.execute(distQuery)
    }
}

private func pointQuery(pred: String) async throws -> (HKStatisticsCollection?) {
    return try await withCheckedThrowingContinuation { continuation in
        let healthStore = DataManager.shared.healthstore
        let stepCount = HKSampleType.quantityType(forIdentifier: .stepCount)!
        let devicePredicate = HKQuery.predicateForObjects(withDeviceProperty: HKDevicePropertyKeyModel, allowedValues: [HKDevice.local().model!])
        let autoAndToday = NSPredicate(format: pred)
        let pred = NSCompoundPredicate(andPredicateWithSubpredicates: [autoAndToday, devicePredicate])
        let interval = DateComponents(minute: 5)
        let cal = Calendar.current
        let now = Date()
        let startDate = cal.startOfDay(for: now)
        
        let pointQuery = HKStatisticsCollectionQuery(quantityType: stepCount, quantitySamplePredicate: pred, anchorDate: startDate, intervalComponents: interval)
        
        pointQuery.initialResultsHandler = { query, results, error in
            // Handle errors here.
            if let error = error as? HKError {
                continuation.resume(throwing: error)
            }
            
            guard let statsCollection = results else {
                // You should only hit this case if you have an unhandled error. Check for bugs
                // in your code that creates the query, or explicitly handle the error.
                assertionFailure("")
                return
            }
            
            continuation.resume(returning: statsCollection)
        }
        
        healthStore.execute(pointQuery)
    }
}

private func cumPointQuery() async throws -> (HKStatisticsCollection?) {
    return try await withCheckedThrowingContinuation { continuation in
        let healthStore = DataManager.shared.healthstore
        let stepCount = HKSampleType.quantityType(forIdentifier: .stepCount)!
        let cal = Calendar.current
        let now = Date()
        // startDate = start of yesterday (86400 : seconds in a day)
        let startDate = cal.startOfDay(for: now).advanced(by: -86400)
        let endDate = cal.date(byAdding: .day, value: 1, to: startDate)!
        let today = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let auto = NSPredicate(format: "metadata.%K != YES", HKMetadataKeyWasUserEntered)
        let devicePredicate = HKQuery.predicateForObjects(withDeviceProperty: HKDevicePropertyKeyModel, allowedValues: [HKDevice.local().model!])
        let pred = NSCompoundPredicate(andPredicateWithSubpredicates: [today, auto, devicePredicate])
        let interval = DateComponents(minute: 5)
        
        let pointQuery = HKStatisticsCollectionQuery(quantityType: stepCount, quantitySamplePredicate: pred, anchorDate: startDate, intervalComponents: interval)
        
        pointQuery.initialResultsHandler = { query, results, error in
            // Handle errors here.
            if let error = error as? HKError {
                continuation.resume(throwing: error)
            }
            
            guard let statsCollection = results else {
                // You should only hit this case if you have an unhandled error. Check for bugs
                // in your code that creates the query, or explicitly handle the error.
                assertionFailure("")
                return
            }
            
            continuation.resume(returning: statsCollection)
        }
        
        healthStore.execute(pointQuery)
    }
}

func healthDataSync() {
    let viewContext = DataManager.shared.viewContext
    
    let cal = Calendar.current
    let now = Date()
    let startDate = cal.startOfDay(for: now)
    let endDate = cal.date(byAdding: .day, value: 1, to: startDate)!
    let pred = "(startDate >= CAST(\(startDate.timeIntervalSinceReferenceDate), 'NSDate') AND startDate < CAST(\(endDate.timeIntervalSinceReferenceDate), 'NSDate'))"
    
    Task (priority: .high) {
        await HKRequestAuth()
        let pointStats = try? await pointQuery(pred: pred)
        
        if let pointStats {
            if let feverTimes = try? viewContext.fetch(Fever_Times.fetchRequest()), !feverTimes.isEmpty {
                var score = 0
                var dateTimes : [Date] = [startDate, now]
                
                // Example : "15:20-16:20"
                for row in feverTimes {
                    if let times = row.times {
                        for timeStr in times.split(separator: "-") {
                            let timeEle = timeStr.split(separator: ":", maxSplits: 1)
                            if let dt = cal.date(bySettingHour: Int(timeEle[0]) ?? -1, minute: Int(timeEle[1]) ?? -1, second: 0, of: startDate), dt <= now {
                                dateTimes.append(dt)
                            }
                        }
                    }
                }
                dateTimes = dateTimes.sorted()
                // Enumerate over all the statistics objects between the start and end dates.
                for i in 0..<dateTimes.count-1 {
                    pointStats.enumerateStatistics(from: dateTimes[i], to: dateTimes[i+1])
                    { (statistics, stop) in
                        if let quantity = statistics.sumQuantity() {
                            let value = quantity.doubleValue(for: .count())
                            if i%2==1 {
                                score += lround(value) * FEVERMULTI
                            } else {
                                score += lround(value)
                            }
                        }
                    }
                }
                if let myWalk = try? viewContext.fetch(My_Walk.fetchRequest()).first {
                    myWalk.current_point = Int64(score * STEPSTOPOINTS)
                } else {
                    let myWalk = My_Walk(context: viewContext)
                    myWalk.current_point = Int64(score * STEPSTOPOINTS)
                }
            } else {
                var score = 0
                pointStats.enumerateStatistics(from: startDate, to: now)
                { (statistics, stop) in
                    if let quantity = statistics.sumQuantity() {
                        let value = quantity.doubleValue(for: .count())
                        score += lround(value)
                    }
                }
                if let myWalk = try? viewContext.fetch(My_Walk.fetchRequest()).first {
                    myWalk.current_point = Int64(score * STEPSTOPOINTS)
                } else {
                    let myWalk = My_Walk(context: viewContext)
                    myWalk.current_point = Int64(score * STEPSTOPOINTS)
                }
            }
        }
        
        scoreSync()
        
        let stepEnergyStats = try? await stepEnergyQuery(pred: pred)
        let distanceStats = try? await distQuery(pred: pred)
        var steps : Int64 = 0
        var cals = 0.0
        var distance = 0.0
        
        let myInfo = try? viewContext.fetch(My_Info.fetchRequest()).first
        let weight = Double(myInfo?.weight ?? 0)
        
        if let stepEnergyStats {
            let sum = stepEnergyStats.sumQuantity() ?? .init(unit: .count(), doubleValue: .zero)
            steps = Int64(lround(sum.doubleValue(for: .count())))
            cals = sum.doubleValue(for: .count()) * weight * CALORIEPERSTEPMULTI
        }
        
        if let distanceStats {
            let sum = distanceStats.sumQuantity() ?? .init(unit: .meterUnit(with: .kilo), doubleValue: .zero)
            distance = sum.doubleValue(for: .meterUnit(with: .kilo))
        }
        
        if let myWalk = try? viewContext.fetch(My_Walk.fetchRequest()).first {
            myWalk.total_walk = steps
            myWalk.calories = cals
            myWalk.distance = distance
        } else {
            let myWalk = My_Walk(context: viewContext)
            myWalk.total_walk = steps
            myWalk.calories = cals
            myWalk.distance = distance
        }
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
}

func calcCum() {
    let viewContext = DataManager.shared.viewContext
    
    let cal = Calendar.current
    let now = Date()
    // 86400 : seconds in a day
    let startDate = cal.startOfDay(for: now).advanced(by: -86400)
    let endDate = cal.date(byAdding: .day, value: 1, to: startDate)!
    let defaults = UserDefaults.standard
    var lastRunDate = defaults.object(forKey: "lastCumResetDate") as? Date
    let pastSunday = cal.nextDate(after: now, matching: .init(weekday: 1), matchingPolicy: .nextTime, direction: .backward) ?? Date.distantPast
    
    if lastRunDate == nil {
        lastRunDate = pastSunday
        UserDefaults.standard.set(pastSunday, forKey: "lastCumResetDate")
    }
    
    if lastRunDate! < pastSunday {
        UserDefaults.standard.set(pastSunday, forKey: "lastCumResetDate")
        if let myWalk = try? viewContext.fetch(My_Walk.fetchRequest()).first {
            myWalk.cum_walked = 0
        } else {
            let myWalk = My_Walk(context: viewContext)
            myWalk.cum_walked = 0
        }
        
        do {
            try viewContext.save()
        } catch {
            // Replace this implementation with code to handle the error appropriately.
            // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return
    }
    
    Task (priority: .high) {
        await HKRequestAuth()
        let pointStats = try? await cumPointQuery()
        
        if let pointStats {
            if let feverTimes = try? viewContext.fetch(Fever_Times.fetchRequest()), !feverTimes.isEmpty {
                var score = 0
                var dateTimes : [Date] = [startDate, endDate]
                
                // Example : "15:20-16:20"
                for row in feverTimes {
                    if let times = row.times {
                        for timeStr in times.split(separator: "-") {
                            let timeEle = timeStr.split(separator: ":", maxSplits: 1)
                            if let dt = cal.date(bySettingHour: Int(timeEle[0]) ?? -1, minute: Int(timeEle[1]) ?? -1, second: 0, of: startDate) {
                                dateTimes.append(dt)
                            }
                        }
                    }
                }
                dateTimes = dateTimes.sorted()
                // Enumerate over all the statistics objects between the start and end dates.
                for i in 0..<dateTimes.count-1 {
                    pointStats.enumerateStatistics(from: dateTimes[i], to: dateTimes[i+1])
                    { (statistics, stop) in
                        if let quantity = statistics.sumQuantity() {
                            let value = quantity.doubleValue(for: .count())
                            if i%2==1 {
                                score += lround(value) * FEVERMULTI
                            } else {
                                score += lround(value)
                            }
                        }
                    }
                }
                if let myWalk = try? viewContext.fetch(My_Walk.fetchRequest()).first {
                    myWalk.cum_walked += Int64(score * STEPSTOPOINTS)
                } else {
                    let myWalk = My_Walk(context: viewContext)
                    myWalk.cum_walked = Int64(score * STEPSTOPOINTS)
                }
            } else {
                var score = 0
                pointStats.enumerateStatistics(from: startDate, to: endDate)
                { (statistics, stop) in
                    if let quantity = statistics.sumQuantity() {
                        let value = quantity.doubleValue(for: .count())
                        score += lround(value)
                    }
                }
                if let myWalk = try? viewContext.fetch(My_Walk.fetchRequest()).first {
                    myWalk.cum_walked += Int64(score * STEPSTOPOINTS)
                } else {
                    let myWalk = My_Walk(context: viewContext)
                    myWalk.cum_walked = Int64(score * STEPSTOPOINTS)
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
        }
    }
}
