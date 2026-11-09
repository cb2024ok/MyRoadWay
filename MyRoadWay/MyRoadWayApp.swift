//
//  MyRoadWayApp.swift
//  MyRoadWay
//
//  Created by baby Enjhon on 11/6/26.
//

import SwiftUI
import SwiftData

@main
struct MyRoadWayApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: TravelSpot.self)
    }
}
