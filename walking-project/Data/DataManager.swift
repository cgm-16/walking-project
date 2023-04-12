//
//  DataManager.swift
//  walking-project
//
//  Created by GMC on 2023/01/25.
//

import CoreData
import HealthKit
import KakaoSDKTalk
import KakaoSDKUser
import FirebaseFirestore

struct DataManager {
    static let shared = DataManager()

    // MARK: - Remove in production - Placeholder only !!!!
    static var preview: DataManager = {
        let result = DataManager(inMemory: true)
        let viewContext = result.container.viewContext
        
        let Names: [String] = ["J.J.Won", "CWK", "J.H.Seong", "S.M.Kim", "C.W.Kim", "G.M.Choi"]
        let UUIDs: [String] = ["AAAAA", "AAAAB", "AAAAC", "AAAAD", "AAAAE", "AAAAF", "AAAAG"]
        let scores: [Int64] = [576100, 700000, 710800, 759500, 963200, 1274000]
        
        let couponNames: [String] = ["빙고 앤 샐러드", "꿀꿀이와 닭갈비"]
        let couponDatas: [Data] = [Data(), Data()]
        let myWalk = My_Walk(context: viewContext)
        
        myWalk.my_id = "AAAAA"
        myWalk.calories = 237
        myWalk.total_walk = 12303
        myWalk.distance = 13.8
        myWalk.current_point = 160300
        
        for i in 0..<2 {
            let couponInfo = Coupon_Info(context: viewContext)
            couponInfo.coupon_id = Int16(i+1)
            couponInfo.coupon_name = "빙고 앤 샐러드"
            couponInfo.coupon_discount = "1000원 할인"
            couponInfo.coupon_url = "https://storage.googleapis.com/walking-img/coupon1"
        }
        
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
        print ("########### starting data manager")
        let result = DataManager()
        let viewContext = DataManager.shared.viewContext
        let healthStore = HKHealthStore()
        let dataTypes = Set([HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
                            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
                             HKObjectType.quantityType(forIdentifier: .stepCount)!])
        if HKHealthStore.isHealthDataAvailable() {
            healthStore.requestAuthorization(toShare: [], read: dataTypes) { (success, error) in
                if !success {
                    fatalError("Unresolved error \(error.debugDescription)")
                }
            }
            let FEVERMULTI = 2
            let STEPSTOPOINTS = 100
            let CALORIEPERSTEPMULTI = 0.0053
            let energyBurned = HKSampleType.quantityType(forIdentifier: .activeEnergyBurned)!
            let stepCount = HKSampleType.quantityType(forIdentifier: .stepCount)!
            let totalDistance = HKSampleType.quantityType(forIdentifier: .distanceWalkingRunning)!
            let calendar = NSCalendar.current
            let now = Date()
            let startDate = calendar.startOfDay(for: now)
            let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)!
            let today = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
            let auto = NSPredicate(format: "metadata.%K != YES", HKMetadataKeyWasUserEntered)
            let autoAndToday = NSCompoundPredicate(type: .and, subpredicates: [today, auto])
            let interval = DateComponents(minute: 5)
            
            let stepEnergyQuery = HKStatisticsQuery(quantityType: stepCount, quantitySamplePredicate: today, options: .cumulativeSum) { (query, statisticsOrNil, errorOrNil) in
                
                guard let statistics = statisticsOrNil else {
                    // Handle any errors here.
                    return
                }
                
                let sum = statistics.sumQuantity() ?? .init(unit: .count(), doubleValue: .zero)
                let myInfo = try? viewContext.fetch(My_Info.fetchRequest()).first
                let weight = Double(myInfo?.weight ?? 0)
                if let myWalk = try? viewContext.fetch(My_Walk.fetchRequest()).first {
                    myWalk.total_walk = Int64(lround(sum.doubleValue(for: .count())))
                    myWalk.calories = sum.doubleValue(for: .count()) * weight * CALORIEPERSTEPMULTI
                } else {
                    let myWalk = My_Walk(context: viewContext)
                    myWalk.total_walk = Int64(lround(sum.doubleValue(for: .count())))
                    myWalk.calories = sum.doubleValue(for: .count()) * weight * CALORIEPERSTEPMULTI
                }
                
                do {
                    try viewContext.save()
                } catch {
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            }
            
            
            
            let distQuery = HKStatisticsQuery(quantityType: totalDistance, quantitySamplePredicate: autoAndToday, options: .cumulativeSum) { (query, statisticsOrNil, errorOrNil) in
                
                guard let statistics = statisticsOrNil else {
                    // Handle any errors here.
                    return
                }
                
                let sum = statistics.sumQuantity() ?? .init(unit: .meterUnit(with: .kilo), doubleValue: .zero)
                if let myWalk = try? viewContext.fetch(My_Walk.fetchRequest()).first {
                    myWalk.distance = sum.doubleValue(for: .meterUnit(with: .kilo))
                } else {
                    let myWalk = My_Walk(context: viewContext)
                    myWalk.distance = sum.doubleValue(for: .meterUnit(with: .kilo))
                }
                
                do {
                    try viewContext.save()
                } catch {
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            }
            
            
            
            let pointQuery = HKStatisticsCollectionQuery(quantityType: stepCount, quantitySamplePredicate: today, anchorDate: startDate, intervalComponents: interval)
            
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
                do {
                    let feverTimes = try viewContext.fetch(timeFetchReq)
                    if feverTimes.isEmpty {
                        var score = 0
                        statsCollection.enumerateStatistics(from: startDate, to: now)
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
                    } else {
                        var score = 0
                        var dateTimes : [Date] = [startDate]
                        let cal = Calendar.current
                        var st = 0
                        var ed = 1
                        var isFever = false
                        
                        // Example : "15:20-16:20"
                        for row in feverTimes {
                            if let times = row.times {
                                for timeStr in times.split(separator: "-") {
                                    let timeEle = timeStr.split(separator: ":", maxSplits: 1)
                                    let dateTime = DateComponents(hour: Int(timeEle[0]), minute: Int(timeEle[1]))
                                    if let dt = cal.date(from: dateTime) {
                                        dateTimes.append(dt)
                                    }
                                }
                            }
                        }
                        dateTimes.append(now)
                        // Enumerate over all the statistics objects between the start and end dates.
                        for i in 0..<dateTimes.count-1 {
                            statsCollection.enumerateStatistics(from: dateTimes[i], to: dateTimes[i+1])
                            { (statistics, stop) in
                                if let quantity = statistics.sumQuantity() {
                                    let value = quantity.doubleValue(for: .count())
                                    if isFever {
                                        score += lround(value) * FEVERMULTI
                                        isFever = false
                                    } else {
                                        score += lround(value)
                                        isFever = true
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
                        
                        do {
                            try viewContext.save()
                        } catch {
                            let nsError = error as NSError
                            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                        }
                    }
                    
                } catch {
                    let nsError = error as NSError
                    fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
                }
            }

            healthStore.execute(stepEnergyQuery)
            healthStore.execute(distQuery)
            healthStore.execute(pointQuery)
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
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
}

public func firstTimeSetup() {
    let db = Firestore.firestore()
    let viewContext = DataManager.shared.viewContext
    
    UserApi.shared.me() { (user, error) in
        if let error = error {
            print(error)
        }
        else {
            print("me() success.")
            
            if let uid = user?.id {
                if let myWalk = try? viewContext.fetch(My_Walk.fetchRequest()).first {
                    myWalk.my_id = String(uid)
                } else {
                    let entityDescription = NSEntityDescription.entity(forEntityName: "My_Walk", in: viewContext)!
                    let myWalk = My_Walk(entity: entityDescription, insertInto: viewContext)
                    myWalk.my_id = String(uid)
                }
                kkoDataWriteToFirebase(uid: String(uid))
                
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
    
    func kkoDataWriteToFirebase(uid : String) {
        TalkApi.shared.friends {(friends, error) in
            if let error = error {
                print(error)
            }
            else {
                //do something
                let frPfps = friends?.elements
                
                var fUuids: [String] = [uid]
                
                if let _frPfps = frPfps {
                    for i in _frPfps {
                        fUuids.append(String(i.id ?? 0))
                    }
                }
                
                db.collection("friendlist").document(uid).setData([
                    "friend-uuids": fUuids,
                    "uuid": uid
                ]) { err in
                    if let err = err {
                        print("Error writing document: \(err)")
                    } else {
                        print("kkoDataWriteToFirebase Document successfully written!")
                    }
                }
            }
        }
    }
}

public func scoreSync() {
    let db = Firestore.firestore()
    let viewContext = DataManager.shared.viewContext
    
    var name : String = ""
    var score : Int = 0
    
    if let myInfo = try? viewContext.fetch(My_Info.fetchRequest()).first {
        name = myInfo.name ?? ""
    }
    
    if let myWalk = try? viewContext.fetch(My_Walk.fetchRequest()).first {
        score = Int(myWalk.current_point)
    }
    
    UserApi.shared.me() { (user, error) in
        if let error = error {
            print(error)
        }
        else {
            print("me() success.")
            
            if let userInfo = user, let uid = userInfo.id, let profile = user?.kakaoAccount?.profile?.thumbnailImageUrl?.absoluteString {
                let uuid = String(uid)
                db.collection("scoreboard").document(uuid).setData([
                    "score": score,
                    "name": name,
                    "uuid": uuid,
                    "imgURL": profile
                ], merge: true) { err in
                    if let err = err {
                        print("Error writing document: \(err)")
                    } else {
                        print("scoreboard Document successfully written!")
                        readScoreboard(uuid: uuid)
                    }
                }
            }
        }
    }
    
    func readScoreboard(uuid: String) {
        print("readScoreboard start")
        db.collection("friendlist").document(uuid).getDocument { (document, error) in
            if let document = document, document.exists {
                print("friendlist document exists!")
                if let friendUuids: [String] = document.get("friend-uuids") as? [String] {
                    print("friends document exists!")
                    print("friends:", friendUuids)
                    db.collection("scoreboard")
                        .whereField("uuid", in: friendUuids)
                        .order(by: "score", descending: true)
                        .limit(to: 20)
                        .getDocuments() { (querySnapshot, err) in
                            if let err = err {
                                print("Error getting documents: \(err)")
                            } else {
                                var rank: Int16 = 1
                                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Walk_Info")
                                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                                try! viewContext.executeAndMergeChanges(using: deleteRequest)
                                viewContext.reset()
                                
                                for document in querySnapshot!.documents {
                                    let dat = document.data()
                                    let entityDescription = NSEntityDescription.entity(forEntityName: "Walk_Info", in: viewContext)!
                                    let walkInfo = Walk_Info(entity: entityDescription, insertInto: viewContext)
                                    walkInfo.setValue(rank, forKey: "rank")
                                    walkInfo.setValue(dat["score"] as? Int64 ?? 0, forKey: "score")
                                    walkInfo.setValue(dat["name"] as? String ?? "", forKey: "name")
                                    walkInfo.setValue(dat["uuid"] as? String ?? "", forKey: "id")
                                    walkInfo.setValue(dat["imgURL"] as? String ?? "", forKey: "imgURL")
                                    rank += 1
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
                else {
                    print("friend-uuids does not exist")
                }
            } else {
                print("Document does not exist")
            }
        }
    }
}

func loadFeverAndCoupon() {
    let db = Firestore.firestore()
    let viewContext = DataManager.shared.viewContext
    
    db.collection("fever-times").document("fevertimes").getDocument { (document, error) in
        if let document = document, document.exists, let data = document.data(), let dat = data["times"] as? [String] {
            let feverDel = NSBatchDeleteRequest(fetchRequest: Fever_Times.fetchRequest())
            try! viewContext.executeAndMergeChanges(using: feverDel)
            
            for i in dat {
                let entityDescription = NSEntityDescription.entity(forEntityName: "Fever_Times", in: viewContext)!
                let feverTimes = Fever_Times(entity: entityDescription, insertInto: viewContext)
                feverTimes.times = i
            }
            
            do {
                try viewContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        } else {
            print("fevertimes Document does not exist")
        }
    }
    
    db.collection("coupondata")
        .getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                let couDel = NSBatchDeleteRequest(fetchRequest: Coupon_Info.fetchRequest())
                try! viewContext.executeAndMergeChanges(using: couDel)
                var id: Int16 = 0
                
                for document in querySnapshot!.documents {
                    let dat = document.data()
                    let entityDescription = NSEntityDescription.entity(forEntityName: "Coupon_Info", in: viewContext)!
                    let couponInfo = Coupon_Info(entity: entityDescription, insertInto: viewContext)
                    couponInfo.coupon_id = id
                    couponInfo.coupon_discount = dat["coupon-discount"] as? String ?? ""
                    couponInfo.coupon_url = dat["coupon-url"] as? String ?? ""
                    couponInfo.coupon_name = dat["coupon-name"] as? String ?? ""
                    id += 1
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

public func runOnceADay() {
    let defaults = UserDefaults.standard
    let lastRunDate = defaults.object(forKey: "lastRunDate") as? Date ?? Date.distantPast
    
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let lastRunDay = calendar.startOfDay(for: lastRunDate)
    
    if today > lastRunDay {
        loadFeverAndCoupon()
        
        defaults.set(today, forKey: "lastRunDate")
    }
}

public func runOnceEveryFiveMin() {
    let timer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
        DispatchQueue.global().async {
            scoreSync()
        }
    }
    RunLoop.current.add(timer, forMode: .common)
}

public func checkCoupon() -> Bool {
    let defaults = UserDefaults.standard
    let lastRunDate = defaults.object(forKey: "lastCouponDate") as? Date ?? Date.distantPast
    
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let lastRunDay = calendar.startOfDay(for: lastRunDate)
    
    if today > lastRunDay {
        return true
    } else {
        return false
    }
}

extension NSManagedObjectContext {
    
    /// Executes the given `NSBatchDeleteRequest` and directly merges the changes to bring the given managed object context up to date.
    ///
    /// - Parameter batchDeleteRequest: The `NSBatchDeleteRequest` to execute.
    /// - Throws: An error if anything went wrong executing the batch deletion.
    public func executeAndMergeChanges(using batchDeleteRequest: NSBatchDeleteRequest) throws {
        batchDeleteRequest.resultType = .resultTypeObjectIDs
        let result = try execute(batchDeleteRequest) as? NSBatchDeleteResult
        let changes: [AnyHashable: Any] = [NSDeletedObjectsKey: result?.result as? [NSManagedObjectID] ?? []]
        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self])
    }
}
