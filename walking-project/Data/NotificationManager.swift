//
//  NotificationManager.swift
//  walking-project
//
//  Created by GMC on 1/19/24.
//

import UserNotifications
import FirebaseFunctions

/*
enum PushTextString {
    case FirstMorning
    case FirstEvening
    case SameMorning
    case SameEvening
    case DiffPreMorning
    case DiffPreEvening
    case DiffSufHigher
    case DiffSufLower
    case InitText
    
    var text: String {
        switch self {
        case .FirstMorning:
            return "1등을 유지 중이네요 굿~~"
        case .FirstEvening:
            return "여전히 1등을 유지 중이네요 굿~~"
        case .SameMorning:
            return "같은 순위를 유지중이네요! 오늘도 화이팅!"
        case .SameEvening:
            return "같은 순위를 유지중이네요! 오늘도 화이팅!"
        case .DiffPreMorning:
            return "어제보다 순위가"
        case .DiffPreEvening:
            return "아침보다 순위가"
        case .DiffSufHigher:
            return "계단 상승했어요! 굿~~"
        case .DiffSufLower:
            return "계단 하락했어요! ㅠㅠ 분발하세여"
        case .InitText:
            return "내일부터 점심 직전과 저녁에 알림이 올거에요!!"
        }
    }
}
*/

public enum EmoteType {
    case hearteyes
    case tauntface
    case wowface
    
    var text: String {
        switch self {
        case .hearteyes:
            return "HEARTEYES"
        case .tauntface:
            return "TAUNTFACE"
        case .wowface:
            return "WOWFACE"
        }
    }
}

@MainActor
public func requestUNPerms() async throws -> Bool {
    let center = UNUserNotificationCenter.current()
    do {
        let granted = try await center.requestAuthorization(options: [.alert, .sound])
        return granted
    } catch {
        throw error
    }
}

public func getUNPerms() async -> UNNotificationSettings {
    return await UNUserNotificationCenter.current().notificationSettings()
}

public func sendEmote(emoteType : EmoteType, from: String, to: String) {
    lazy var functions = Functions.functions(region: "asia-northeast3")
    functions.httpsCallable("sendemote").call(["uuid": from, "emote": emoteType.text, "target": to]) { result, error in
        if let error = error as NSError? {
            if error.domain == FunctionsErrorDomain {
                let code = FunctionsErrorCode(rawValue: error.code)
                let message = error.localizedDescription
                print(code!, message)
                return
            }
        }
    }
}

/*
public func pushMorningNotif() {
    let content = UNMutableNotificationContent()
    content.title = "아침 랭킹"
    content.sound = UNNotificationSound.default
    
    Task { @MainActor in
        let perms = await getUNPerms()
        guard perms.authorizationStatus == .authorized else { return }
        let viewContext = DataManager.shared.viewContext
        guard let pastRank = try? viewContext.fetch(Past_Rank.fetchRequest()).first else { return }
        
        if pastRank.yesterday_evening == 0 {
            content.body = PushTextString.InitText.text
        } else if pastRank.current < pastRank.yesterday_evening {
            content.body = "\(PushTextString.DiffPreMorning.text) \(pastRank.yesterday_evening-pastRank.current)\(PushTextString.DiffSufHigher.text)"
        } else if pastRank.current > pastRank.yesterday_evening {
            content.body = "\(PushTextString.DiffPreMorning.text) \(pastRank.current-pastRank.yesterday_evening)\(PushTextString.DiffSufLower.text)"
        } else if pastRank.current == pastRank.yesterday_evening && pastRank.current == 1 {
            content.body = PushTextString.FirstMorning.text
        } else {
            content.body = PushTextString.SameMorning.text
        }
        
        let request = UNNotificationRequest(identifier: "Morning", content: content, trigger: nil)
        let center = UNUserNotificationCenter.current()
        pastRank.morning = pastRank.current
        do {
            try await center.add(request)
            try viewContext.save()
        } catch {
            print(error)
        }
    }
}

public func pushEveningNotif() {
    let content = UNMutableNotificationContent()
    content.title = "저녁 랭킹"
    content.sound = UNNotificationSound.default
    
    Task { @MainActor in
        let perms = await getUNPerms()
        print("perms are \(perms.authorizationStatus.rawValue.description)")
        guard perms.authorizationStatus == .authorized else { return }
        let viewContext = DataManager.shared.viewContext
        guard let pastRank = try? viewContext.fetch(Past_Rank.fetchRequest()).first else {
            print("cant find pastRank. Sorry!")
            return
        }
        
        if pastRank.morning == 0 {
            content.body = PushTextString.InitText.text
        } else if pastRank.current < pastRank.morning {
            content.body = "\(PushTextString.DiffPreEvening.text) \(pastRank.morning-pastRank.current)\(PushTextString.DiffSufHigher.text)"
        } else if pastRank.current > pastRank.morning {
            content.body = "\(PushTextString.DiffPreEvening.text) \(pastRank.current-pastRank.morning)\(PushTextString.DiffSufLower.text)"
        } else if pastRank.current == pastRank.morning && pastRank.current == 1 {
            content.body = PushTextString.FirstEvening.text
        } else {
            content.body = PushTextString.FirstEvening.text
        }
        
        let request = UNNotificationRequest(identifier: "Morning", content: content, trigger: nil)
        let center = UNUserNotificationCenter.current()
        pastRank.yesterday_evening = pastRank.current
        do {
            try await center.add(request)
            try viewContext.save()
        } catch {
            print(error)
        }
    }
}
*/
