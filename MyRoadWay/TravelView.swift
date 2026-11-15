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

    // 저장된 여행 목록을 Load..
    @Query(sort: \Travel.createdAt, order: .reverse) private var travels: [Travel]
    
    // 제목수정을 위한 변수추가
    @State private var editingTravel: Travel? = nil
    @State private var newTitle: String = ""
    @State private var titleSaveError: String?
    
    private var trimmedTitle: String {
        newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
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
                    
                    // 제목수정처리..
                    Button {
                            editingTravel = travel
                            newTitle = travel.title
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.borderless)
                        .accessibilityLabel("여행제목 수정")
                        
                }
                .onDelete { deleteIdx in
                    deleteTravels(at: deleteIdx)
                }
            }
            .navigationDestination(item: $currentTravel, destination: { travel in
                ContentView(currentTravel: travel)
            })
            .navigationTitle("My Road Way")
            // 제목수정 Alert
            .alert("여행 제목 수정", isPresented: Binding(
                get: { editingTravel != nil },
                set: { if !$0 { editingTravel = nil}}
            )) {
                TextField("새로운 제목",text: $newTitle)
                Button("취소",role: .cancel) {}
                Button("저장") {
                    guard let travel = editingTravel else { return }
                    
                    let title = trimmedTitle
                    guard !title.isEmpty else { return }
            
                   do {
                        travel.title = title
                        try context.save()
                        titleSaveError = nil
                   } catch {
                       titleSaveError = "제목을 저장하지 못했습니다. 다시 시도해 주세요"
                   }
                }.disabled(trimmedTitle.isEmpty)
            } message: {
                Text("이 여행의 새로운 제목을 입력해 주세요")
            }
            .alert(
                "저장 실패",
                isPresented: Binding(
                    get: { titleSaveError != nil },
                    set: { if !$0 { titleSaveError = nil } }
                )
            ) {
                Button("확인", role: .cancel) {}
            } message: {
                Text(titleSaveError ?? "제목을 저장하지 못했습니다.")
            }
        }
    }
    
    private func deleteTravels(at offsets: IndexSet) {
        for index in offsets {
            let travel = travels[index]
            context.delete(travel)
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
