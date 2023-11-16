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
import KakaoSDKAuth
import FirebaseFirestore
import FirebaseFunctions

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
        
        let myInfo = My_Info(context: viewContext)
        myInfo.my_id = "AAAAA"
        
        let myWalk = My_Walk(context: viewContext)
        myWalk.calories = 1237
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
            let nsError = error as NSError
            print("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentContainer
    let healthstore: HKHealthStore
    
    init(inMemory: Bool = false) {
        healthstore = HKHealthStore()
        container = NSPersistentContainer(name: "walking_project")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Unresolved error \(error), \(error.userInfo)")
                return
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    var viewContext: NSManagedObjectContext {
        return container.viewContext
    }
}

struct KakaoUserResult {
    var uid : String
    var thumb : String
}

struct KakaoFriendResult {
    var FUids : [String]
    var FThumbs : [String]
}

private func findUidThumb() async throws -> (KakaoUserResult) {
    return try await withCheckedThrowingContinuation { continuation in
        UserApi.shared.me() { (user, error) in
            if let error = error {
                continuation.resume(throwing: error)
            }
            if let uid = user?.id, let link = user?.kakaoAccount?.profile?.thumbnailImageUrl?.absoluteString {
                let res = KakaoUserResult(uid: String(uid), thumb: link)
                continuation.resume(returning: res)
            }
        }
    }
}

private func findFriendInfo() async throws -> (KakaoFriendResult) {
    return try await withCheckedThrowingContinuation { continuation in
        TalkApi.shared.friends { (friends, error) in
            if let error = error {
                continuation.resume(throwing: error)
            }
            if let frPfps = friends?.elements {
                var fUuids: [String] = []
                var fPfpUrls: [String] = []
                
                for i in frPfps {
                    fUuids.append(String(i.id ?? 0))
                    fPfpUrls.append(i.profileThumbnailImage?.absoluteString ?? "")
                }
                let res = KakaoFriendResult(FUids: fUuids, FThumbs: fPfpUrls)
                continuation.resume(returning: res)
            }
        }
    }
}

private func friendSync(_ viewContext: NSManagedObjectContext, _ db: Firestore) {
    Task { @MainActor in
        let uRes = try? await findUidThumb()
        let fRes = try? await findFriendInfo()
        
        if let uInfo = uRes, let fInfo = fRes {
            let uids = [uInfo.uid] + fInfo.FUids
            let thumbs = [uInfo.thumb] + fInfo.FThumbs
            try await db.collection("friendlist").document(uInfo.uid).setData([
                "friend-uuids": uids,
                "friend-thumbs": thumbs,
                "uuid": uInfo.uid
            ])
        }
        
        if let uInfo = uRes {
            if let myInfo = try? viewContext.fetch(My_Info.fetchRequest()).first {
                myInfo.my_id = uInfo.uid
                myInfo.my_thumb = uInfo.thumb
            } else {
                let myInfo = My_Info(context: viewContext)
                myInfo.my_id = uInfo.uid
                myInfo.my_thumb = uInfo.thumb
            }
        }
        
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
                return
            }
        }
    }
}

public func firstTimeSetup() {
    let viewContext = DataManager.shared.viewContext
    
    let cal = Calendar.current
    let now = Date()
    let pastSunday = cal.nextDate(after: now, matching: .init(weekday: 1), matchingPolicy: .nextTime, direction: .backward) ?? Date.distantPast
    UserDefaults.standard.set(pastSunday, forKey: "lastCumResetDate")
    
    Task { @MainActor in
        if let myInfo = try? viewContext.fetch(My_Info.fetchRequest()).first, let uid = myInfo.my_id, let name = myInfo.name {
            await setName(uid: uid, name: name)
        }
    }
}

@MainActor
func scoreSync() {
    let db = Firestore.firestore()
    let viewContext = DataManager.shared.viewContext
    lazy var functions = Functions.functions(region: "asia-northeast3")
    
    var score : Int = 0
    
    guard let uid = try? viewContext.fetch(My_Info.fetchRequest()).first?.my_id else {
        return
    }
    
    if let myWalk = try? viewContext.fetch(My_Walk.fetchRequest()).first {
        score = Int(myWalk.current_point+myWalk.cum_walked)
    }
    
    let docRef = db.collection("scoreboard").document(uid)
    let newValue = score
    
    db.runTransaction({ (transaction, errorPointer) -> Any? in
        let documentSnapshot: DocumentSnapshot
        do {
            try documentSnapshot = transaction.getDocument(docRef)
        } catch let fetchError as NSError {
            errorPointer?.pointee = fetchError
            return nil
        }
        
        if documentSnapshot.exists {
            guard let currentValue = documentSnapshot.data()?["score"] as? Int else {
                errorPointer?.pointee = NSError(domain: "MyDomain", code: -1, userInfo: ["message": "Document snapshot does not contain a value"])
                return nil
            }
            
            if currentValue >= newValue {
                // The current value is equal to or greater than the new value, so do not update
                return nil
            } else {
                // The current value is less than the new value, so update to the new value
                transaction.updateData(["score": newValue], forDocument: docRef)
                return nil
            }
        } else {
            // The document does not exist, so create a new one with the specified data
            transaction.setData([
                "score": score,
                "uuid": uid
            ], forDocument: docRef, merge: true)
            return nil
        }
    }) { (result, error) in
        if let error = error {
            // Handle error
            print("Transaction failed with error: \(error.localizedDescription)")
        } else {
            // Transaction was successful
            readScoreboard(uuid: uid)
            functions.httpsCallable("showrankingpercentage").call(["uuid": uid]) { result, error in
                if let error = error as NSError? {
                    if error.domain == FunctionsErrorDomain {
                        let code = FunctionsErrorCode(rawValue: error.code)
                        let message = error.localizedDescription
                        print(code!, message)
                        return
                    }
                }
                if let data = result?.data as? [String: Any], let perc = data["perc"] as? Int16 , let avg = data["avg"] as? Int64{
                    if let rankInfo = try? viewContext.fetch(Rank_Info.fetchRequest()).first {
                        rankInfo.top_percent = perc
                        rankInfo.avg = avg
                    } else {
                        let rankInfo = Rank_Info(context: viewContext)
                        rankInfo.top_percent = perc
                        rankInfo.avg = avg
                    }
                }
            }
        }
    }
    
    func readScoreboard(uuid: String) {
        Task { @MainActor in
            let friendRes = try? await db.collection("friendlist").document(uuid).getDocument()
            guard let friendDocs = friendRes, friendDocs.exists,
                  let friendUuids = friendDocs.get("friend-uuids") as? [String],
                  let friendThumbs = friendDocs.get("friend-thumbs") as? [String] else {
                return
            }
            
            let friendDict : Dictionary<String, String> = Dictionary(uniqueKeysWithValues: zip(friendUuids, friendThumbs))
            
            let scoreRes = try? await db.collection("scoreboard")
                .whereField("uuid", in: friendUuids)
                .order(by: "score", descending: true)
                .limit(to: 20)
                .getDocuments()
            
            let nameRes = try? await db.collection("namelist")
                .whereField("uuid", in: friendUuids)
                .getDocuments()
            
            if let scoreSnap = scoreRes, let nameSnap = nameRes {
                let nameDict : Dictionary<String, String> = Dictionary(uniqueKeysWithValues: nameSnap.documents.map({ e in
                    let dat = e.data()
                    return (dat["uuid"] as? String ?? "", dat["name"] as? String ?? "")
                }))
                
                var rank: Int16 = 1
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Walk_Info")
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try! viewContext.executeAndMergeChanges(using: deleteRequest)
                var uuids : Set<String> = Set()
                viewContext.reset()
                
                for document in scoreSnap.documents {
                    let dat = document.data()
                    let score = dat["score"] as? Int64 ?? 0
                    let uId = dat["uuid"] as? String ?? ""
                    let name = nameDict[uId]
                    let uThumb = friendDict[uId]
                    uuids.insert(uId)
                    
                    let entityDescription = NSEntityDescription.entity(forEntityName: "Walk_Info", in: viewContext)!
                    let walkInfo = Walk_Info(entity: entityDescription, insertInto: viewContext)
                    walkInfo.setValue(rank, forKey: "rank")
                    walkInfo.setValue(score, forKey: "score")
                    walkInfo.setValue(name, forKey: "name")
                    walkInfo.setValue(uId, forKey: "id")
                    walkInfo.setValue(uThumb, forKey: "imgURL")
                    rank += 1
                }
                
                let rest = Set(friendUuids).subtracting(uuids).sorted()
                for _id in rest {
                    let entityDescription = NSEntityDescription.entity(forEntityName: "Walk_Info", in: viewContext)!
                    let walkInfo = Walk_Info(entity: entityDescription, insertInto: viewContext)
                    walkInfo.setValue(rank, forKey: "rank")
                    walkInfo.setValue(0, forKey: "score")
                    walkInfo.setValue(nameDict[_id], forKey: "name")
                    walkInfo.setValue(_id, forKey: "id")
                    walkInfo.setValue(friendDict[_id], forKey: "imgURL")
                    rank += 1
                }
                
                if viewContext.hasChanges {
                    do {
                        try viewContext.save()
                    } catch {
                        let nsError = error as NSError
                        print("Unresolved error \(nsError), \(nsError.userInfo)")
                        return
                    }
                }
            }
        }
    }
}

func loadFeverAndCoupon() {
    let db = Firestore.firestore()
    let viewContext = DataManager.shared.viewContext
    
    friendSync(viewContext, db)
    
    Task { @MainActor in
        let feverRes = try? await db.collection("fever-times").document("fevertimes").getDocument()
        let couponRes = try? await db.collection("coupondata").getDocuments()
        
        if let feverDocs = feverRes, feverDocs.exists, let data = feverDocs.data(), let dat = data["times"] as? [String] {
            let feverDel = NSBatchDeleteRequest(fetchRequest: Fever_Times.fetchRequest())
            try! viewContext.executeAndMergeChanges(using: feverDel)
            
            for i in dat {
                let entityDescription = NSEntityDescription.entity(forEntityName: "Fever_Times", in: viewContext)!
                let feverTimes = Fever_Times(entity: entityDescription, insertInto: viewContext)
                feverTimes.times = i
            }
        }
        
        if let couponDocs = couponRes {
            let couDel = NSBatchDeleteRequest(fetchRequest: Coupon_Info.fetchRequest())
            try! viewContext.executeAndMergeChanges(using: couDel)
            var id: Int16 = 0
            
            for document in couponDocs.documents {
                let dat = document.data()
                let entityDescription = NSEntityDescription.entity(forEntityName: "Coupon_Info", in: viewContext)!
                let couponInfo = Coupon_Info(entity: entityDescription, insertInto: viewContext)
                couponInfo.coupon_id = id
                couponInfo.coupon_discount = dat["coupon-discount"] as? String ?? ""
                couponInfo.coupon_url = dat["coupon-url"] as? String ?? ""
                couponInfo.coupon_name = dat["coupon-name"] as? String ?? ""
                id += 1
            }
        }
        
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                let nsError = error as NSError
                print("Unresolved error \(nsError), \(nsError.userInfo)")
                return
            }
        }
    }
}

@MainActor
func setName(uid: String, name: String) async {
    let db = Firestore.firestore()
    do {
        try await db.collection("namelist").document(uid).setData([
            "name" : name,
            "uuid" : uid
        ])
    } catch {
        print(error)
    }
}

func runOnceEvery10Sec() {
    healthDataSync()
    let timer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
        Task {
            healthDataSync()
        }
    }
    RunLoop.current.add(timer, forMode: .common)
}

func runOnceEveryOneMin() {
    Task {
        await scoreSync()
    }
    let timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
        Task {
            await scoreSync()
        }
    }
    RunLoop.current.add(timer, forMode: .common)
}

func runOnlyOnceADay() {
    let defaults = UserDefaults.standard
    let lastRunDate = defaults.object(forKey: "lastCalcCumRunDate") as? Date ?? Date.distantPast
    
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    let lastRunDay = calendar.startOfDay(for: lastRunDate)
    
    if today > lastRunDay {
        defaults.set(Date(), forKey: "lastCalcCumRunDate")
        calcCum()
    } else {
        return
    }
}

func checkCoupon() -> Bool {
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

func resetCoupon() {
    UserDefaults.standard.set(Date.distantPast, forKey: "lastCouponDate")
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
