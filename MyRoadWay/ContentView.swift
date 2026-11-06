//
//  ContentView.swift
//  MyRoadWay
//
//  Created by baby Enjhon on 11/6/26.
//

import SwiftUI
import PhotosUI
import MapKit
import SceneKit
import ImageIO
import CoreLocation

// MARK: - 1. 여행 사진 데이터 모델
struct TravelPhoto: Identifiable {
        let id = UUID()
        let image: UIImage
        let coordinate: CLLocationCoordinate2D
        let date: Date
        var local3DPosition: SCNVector3 = SCNVector3Zero
}

// MARK: - 2. 메인 뷰 (My Road Way)
struct ContentView: View {
        @State private var selectedItems: [PhotosPickerItem] = []
        @State private var travelPhotos: [TravelPhoto] = []
        @State private var viewMode: ViewMode = .scene3D
        @State private var isProcessing: Bool = false
        
        enum ViewMode: String, CaseIterable {
            case map2D = "2D 지도"
            case scene3D = "3D 입체 맵"
        }
        
        var body: some View {
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    if travelPhotos.isEmpty {
                        // 최초 안내 화면
                        VStack(spacing: 20) {
                            Image(systemName: "map.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.cyan)
                            
                            Text("My Road Way")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("여행 사진 10장을 선택하면\n나만의 3D 입체 여행 지도가 펼쳐집니다.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                            
                            PhotosPicker(
                                selection: $selectedItems,
                                maxSelectionCount: 10,
                                matching: .images
                            ) {
                                Label("사진 10장 선택하기 📸", systemImage: "photo.stack")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 14)
                                    .background(Color.cyan, in: Capsule())
                            }
                        }
                        .padding()
                    } else {
                        // 메인 디스플레이 (2D / 3D 전환)
                        VStack(spacing: 0) {
                            if viewMode == .map2D {
                                Map2DView(photos: travelPhotos)
                            } else {
                                SceneKit3DView(photos: travelPhotos)
                            }
                        }
                        .ignoresSafeArea(edges: .bottom)
                        
                        // 상단 플로팅 컨트롤 바
                        VStack {
                            HStack {
                                Picker("모드", selection: $viewMode) {
                                    ForEach(ViewMode.allCases, id: \.self) { mode in
                                        Text(mode.rawValue).tag(mode)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .frame(width: 180)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                                
                                Spacer()
                                
                                PhotosPicker(selection: $selectedItems, maxSelectionCount: 10, matching: .images) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.cyan)
                                        .padding(8)
                                        .background(.ultraThinMaterial, in: Circle())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 10)
                            
                            Spacer()
                        }
                    }
                    
                    if isProcessing {
                        Color.black.opacity(0.6).ignoresSafeArea()
                        ProgressView("사진 EXIF 및 3D 공간 분석 중...")
                            .tint(.white)
                            .foregroundColor(.white)
                    }
                }
                .navigationBarHidden(true)
                .onChange(of: selectedItems) { oldValue, newItems in
                    processSelectedPhotos(newItems)
                }
            }
        }
        
        // 사진 데이터 파싱 및 EXIF 추출 로직
        private func processSelectedPhotos(_ items: [PhotosPickerItem]) {
            isProcessing = true
            Task {
                var extracted: [TravelPhoto] = []
                
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        
                        // EXIF에서 GPS 및 날짜 추출
                        if let (coord, date) = extractEXIF(from: data) {
                            extracted.append(TravelPhoto(image: uiImage, coordinate: coord, date: date))
                        }
                    }
                }
                
                // 시간 순서대로 정렬
                extracted.sort(by: { $0.date < $1.date })
                
                // 3D 로컬 좌표 계산 (중심점 기준 정규화)
                let normalized = calculate3DCoordinates(for: extracted)
                
                await MainActor.run {
                    self.travelPhotos = normalized
                    self.isProcessing = false
                }
            }
        }
        
        // ImageIO를 이용한 고속 EXIF 파서
        private func extractEXIF(from data: Data) -> (CLLocationCoordinate2D, Date)? {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
                return nil
            }
            
            var coordinate: CLLocationCoordinate2D? = nil
            var date: Date = Date()
            
            // 1. GPS 추출
            if let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
               let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
               let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String,
               let lon = gps[kCGImagePropertyGPSLongitude] as? Double,
               let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String {
                
                let finalLat = (latRef == "S") ? -lat : lat
                let finalLon = (lonRef == "W") ? -lon : lon
                coordinate = CLLocationCoordinate2D(latitude: finalLat, longitude: finalLon)
            }
            
            // 2. 촬영 날짜 추출
            if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
               let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                if let parsedDate = formatter.date(from: dateString) {
                    date = parsedDate
                }
            }
            
            guard let finalCoord = coordinate else { return nil }
            return (finalCoord, date)
        }
        
        // GPS 위경도를 3D 평면 좌표(X, Z)로 스케일 변환
        private func calculate3DCoordinates(for photos: [TravelPhoto]) -> [TravelPhoto] {
            guard !photos.isEmpty else { return [] }
            
            // 중심점 계산
            let avgLat = photos.map { $0.coordinate.latitude }.reduce(0, +) / Double(photos.count)
            let avgLon = photos.map { $0.coordinate.longitude }.reduce(0, +) / Double(photos.count)
            
            var result = photos
            let metersPerDegreeLat = 111320.0
            let metersPerDegreeLon = 111320.0 * cos(avgLat * .pi / 180.0)
            
            let scale: Float = 0.005 // 200m = 1.0 SceneKit 단위
            
            for i in 0..<result.count {
                let dLat = result[i].coordinate.latitude - avgLat
                let dLon = result[i].coordinate.longitude - avgLon
                
                let x = Float(dLon * metersPerDegreeLon) * scale
                let z = Float(-dLat * metersPerDegreeLat) * scale // 북쪽이 -Z
                let y: Float = 0.5 // 바닥에서 살짝 띄움
                
                result[i].local3DPosition = SCNVector3(x, y, z)
            }
            return result
        }
    }

    // MARK: - 3. SceneKit 3D 입체 지도 뷰 (UIViewRepresentable)
    struct SceneKit3DView: UIViewRepresentable {
        let photos: [TravelPhoto]
        
        func makeUIView(context: Context) -> SCNView {
            let scnView = SCNView()
            scnView.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.07, alpha: 1.0)
            scnView.allowsCameraControl = true // 손가락으로 360도 회전/줌 인/아웃 지원
            scnView.autoenablesDefaultLighting = false
            
            let scene = SCNScene()
            scnView.scene = scene
            
            // 1. 카메라 노드 설정
            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            cameraNode.position = SCNVector3(0, 15, 18)
            cameraNode.eulerAngles = SCNVector3(-0.65, 0, 0)
            scene.rootNode.addChildNode(cameraNode)
            
            // 2. 조명 시스템
            let lightNode = SCNNode()
            lightNode.light = SCNLight()
            lightNode.light?.type = .directional
            lightNode.light?.color = UIColor.white
            lightNode.light?.intensity = 1500
            lightNode.position = SCNVector3(10, 20, 10)
            lightNode.eulerAngles = SCNVector3(-0.8, 0.5, 0)
            scene.rootNode.addChildNode(lightNode)
            
            let ambientLight = SCNNode()
            ambientLight.light = SCNLight()
            ambientLight.light?.type = .ambient
            ambientLight.light?.color = UIColor(red: 0.2, green: 0.3, blue: 0.4, alpha: 1.0)
            scene.rootNode.addChildNode(ambientLight)
            
            // 3. 다크 스타일 3D 바닥 그리드 평면
            let floorGeo = SCNFloor()
            floorGeo.reflectivity = 0.15
            let floorMat = SCNMaterial()
            floorMat.diffuse.contents = UIColor(red: 0.08, green: 0.08, blue: 0.12, alpha: 1.0)
            floorGeo.materials = [floorMat]
            let floorNode = SCNNode(geometry: floorGeo)
            scene.rootNode.addChildNode(floorNode)
            
            // 4. 3D 사진 카드 및 경로 렌더링
            build3DRoute(in: scene)
            
            return scnView
        }
        
        func updateUIView(_ uiView: SCNView, context: Context) {}
        
        // 사진 카드 및 연결선 생성
        private func build3DRoute(in scene: SCNScene) {
            guard !photos.isEmpty else { return }
            
            var prevPos: SCNVector3? = nil
            
            for (index, item) in photos.enumerated() {
                let pos = item.local3DPosition
                
                // A. 사진 카드 생성 (폴라로이드 스타일 프레임)
                let cardNode = createPhotoCardNode(image: item.image, index: index + 1)
                cardNode.position = pos
                scene.rootNode.addChildNode(cardNode)
                
                // 바닥에 위치를 가리키는 지지대 기둥
                let pinLine = SCNCylinder(radius: 0.02, height: CGFloat(pos.y))
                pinLine.firstMaterial?.diffuse.contents = UIColor.cyan.withAlphaComponent(0.6)
                let pinNode = SCNNode(geometry: pinLine)
                pinNode.position = SCNVector3(pos.x, pos.y / 2.0, pos.z)
                scene.rootNode.addChildNode(pinNode)
                
                // B. 이전 장소와 현재 장소를 잇는 3D 네온 경로 선
                if let p = prevPos {
                    let routeLine = createRouteCylinder(from: p, to: pos)
                    scene.rootNode.addChildNode(routeLine)
                }
                prevPos = pos
            }
        }
        
        // 3D 폴라로이드 사진 카드 노드
        private func createPhotoCardNode(image: UIImage, index: Int) -> SCNNode {
            let cardWidth: CGFloat = 1.4
            let cardHeight: CGFloat = 1.8
            
            // 카드 백판
            let box = SCNBox(width: cardWidth, height: cardHeight, length: 0.04, chamferRadius: 0.06)
            let whiteMat = SCNMaterial()
            whiteMat.diffuse.contents = UIColor.white
            
            // 사진 전면 머티리얼
            let photoMat = SCNMaterial()
            photoMat.diffuse.contents = image
            
            box.materials = [photoMat, whiteMat, whiteMat, whiteMat, whiteMat, whiteMat]
            let cardNode = SCNNode(geometry: box)
            
            // 위아래로 둥실둥실 떠 있는 애니메이션
            let hoverUp = SCNAction.moveBy(x: 0, y: 0.15, z: 0, duration: 1.2)
            hoverUp.timingMode = .easeInEaseOut
            let hoverDown = hoverUp.reversed()
            cardNode.runAction(SCNAction.repeatForever(SCNAction.sequence([hoverUp, hoverDown])))
            
            return cardNode
        }
        
        // 두 점 사이를 잇는 3D 원통 라인
        private func createRouteCylinder(from start: SCNVector3, to end: SCNVector3) -> SCNNode {
            let vector = SCNVector3(end.x - start.x, end.y - start.y, end.z - start.z)
            let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
            
            let cylinder = SCNCylinder(radius: 0.035, height: CGFloat(distance))
            let mat = SCNMaterial()
            mat.diffuse.contents = UIColor.cyan
            mat.emission.contents = UIColor.cyan.withAlphaComponent(0.8) // 발광 효과
            cylinder.materials = [mat]
            
            let node = SCNNode(geometry: cylinder)
            node.position = SCNVector3((start.x + end.x) / 2.0, (start.y + end.y) / 2.0, (start.z + end.z) / 2.0)
            
            // 회전 벡터 연산
            let axis = SCNVector3(vector.z, 0, -vector.x)
            let angle = acos(vector.y / distance)
            node.rotation = SCNVector4(axis.x, axis.y, axis.z, -angle)
            
            return node
        }
    }

    // MARK: - 4. MapKit 2D 지도 뷰 (비교용)
    struct Map2DView: View {
        let photos: [TravelPhoto]
        @State private var position: MapCameraPosition = .automatic
        
        var body: some View {
            Map(position: $position) {
                ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                    Annotation("스팟 \(index + 1)", coordinate: photo.coordinate) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white)
                                .frame(width: 44, height: 50)
                                .shadow(radius: 4)
                            
                            Image(uiImage: photo.image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 38, height: 38)
                                .clipped()
                                .cornerRadius(6)
                                .offset(y: -3)
                        }
                    }
                }
                
                // 2D 폴리라인 연결선
                MapPolyline(coordinates: photos.map { $0.coordinate })
                    .stroke(Color.cyan, lineWidth: 3)
            }
            .mapStyle(.standard(elevation: .realistic))
        }
    }

    #Preview {
        ContentView()
    }
