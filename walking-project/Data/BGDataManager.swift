//
//  BGDataManager.swift
//  walking-project
//
//  Created by GMC on 2023/05/31.
//

import Foundation
import BackgroundTasks

func scheduleCumWalked() {
    let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date()))!
    let request = BGAppRefreshTaskRequest(identifier: "calc_cum")
    request.earliestBeginDate = tomorrow
    
    do {
        try BGTaskScheduler.shared.submit(request)
    } catch {
        print("Could not schedule app refresh: \(error)")
    }
}
