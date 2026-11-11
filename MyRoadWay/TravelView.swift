    //
    //  TravelView.swift
    //  MyRoadWay
    //
    //  Created by baby Enjhon on 11/10/26.
    //

import SwiftUI
import SwiftData

// [[String]] 대신 타입 안전한 struct 사용
struct SpotInput {
    let latitude: Double
    let longitude: Double
    let takenAt: Date
    let memo: String
    let imageFileName: String
}

struct TravelView: View {
    @Environment(\.modelContext) private var context 
    @State private var currentTravel: Travel?
    @State private var photos: [TravelPhoto] = []

    var body: some View {

        VStack {
            Map2DView(photos: $photos, currentTravel: $currentTravel)
            Button("여행 저장") {
                saveTravel()
            }
        }
        .onAppear {
            // Travel 설정.
            let travel = Travel (
                id: UUID(),
                title: "새 여행",
                createdAt: Date(),
                coverImageName: "",
            )
            context.insert(travel)
            currentTravel = travel
        }

    }


    //
    // MARK: saveTravel 
    //
   func saveTravel() {
    guard let travel = currentTravel else { return }

        for photo in photos {
            let spot = TravelSpot(
                createdAt: Date(),
                latitude: photo.latitude,
                longitude: photo.longitude,
                takenAt: photo.takenAt,
                memo: photo.memo,
                imageFileName: photo.imageFileName
            )
            context.insert(spot)
            travel.travelSpots.append(spot)
        }

        do {
            try context.save()
        } catch {
            print("저장 실패: \(error.localizedDescription)")
        }
    }

    func fetchTravels() -> [Travel] {
        let descriptor = FetchDescriptor<Travel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            return try context.fetch(descriptor)
        } catch {
            print("Failed to fetch travels: \(error.localizedDescription)")
            return []
        }
    }

}