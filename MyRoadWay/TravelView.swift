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

    // 저장된 여행 목록을 Load..
    @Query(sort: \Travel.createdAt, order: .reverse) private var travels: [Travel]
    
    var body: some View {
        
        NavigationStack {
            
            List {
                // 새 여행의 시작버튼
                Button(action: createNewTravel) {
                    Label("새 여행 시작하기", systemImage: "plus.circle.fill")
                        .foregroundColor(.cyan)
                }
                
                // 저장된 여행목록..
                ForEach(travels) { travel in
                    NavigationLink {
                        ContentView(currentTravel: travel)
                    } label: {
                        VStack(alignment: .leading) {
                            Text(travel.title)
                                .font(.headline)
                            
                            Text("\(travel.travelSpots.count)개의 스팟")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            .onAppear(perform: {
                cleanupEmptyTravels()
            })
            .navigationTitle("My Road Way")
        
        }
    }
    
    // 스팟이 없는 빈 여행 데이터를 정리처리
    private func cleanupEmptyTravels() {
        for travel in travels {
            if travel.travelSpots.isEmpty {
                context.delete(travel)
            }
        }
        try? context.save()
    }
    
    
    private func createNewTravel() {
        let travel = Travel(
            id: UUID(),
            title: "새 여행 \(Date().formatted(date: .abbreviated, time: .omitted))",
            createdAt: Date(),
            coverImageName: ""
        )
        context.insert(travel)
        currentTravel = travel
    }


    //
    // MARK: saveTravel 
    //
   func saveTravel() {
    guard let travel = currentTravel else { return }

        for photo in photos {
            
            // 이미지 파일저장 처리
            let fileName = UUID().uuidString + ".jpg"
            try? ImageFileManager.saveImage(photo.image, fileName: fileName)
            
            let spot = TravelSpot(
                createdAt: Date(),
                latitude: photo.coordinate.latitude,
                longitude: photo.coordinate.longitude,
                takenAt: photo.date,
                memo: photo.memo,
                imageFileName: fileName
            )
            context.insert(spot)
            travel.travelSpots.append(spot)
        }

        do {
            try context.save()
            print("저장 성공")
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
    
    func imageToBase64(_ image: UIImage) -> String? {
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            return imageData.base64EncodedString()
        }
        return nil
    }

}
