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
    import simd
    import SwiftData

    // MARK: - 1. 여행 사진 데이터 모델
    struct TravelPhoto: Identifiable {
        let id: UUID
        let image: UIImage
        let coordinate: CLLocationCoordinate2D
        let date: Date
        var local3DPosition: SCNVector3 = SCNVector3Zero
        var memo: String = ""
        
        init(
            id: UUID = UUID(),
            image: UIImage,
            coordinate: CLLocationCoordinate2D,
            date: Date,
            local3DPosition: SCNVector3 = SCNVector3Zero,
            memo: String = ""
        ) {
            self.id = id
            self.image = image
            self.coordinate = coordinate
            self.date = date
            self.local3DPosition = local3DPosition
            self.memo = memo
        }
    }

    // MARK: - 2. 메인 뷰 (My Road Way)
    struct ContentView: View {
        @Environment(\.modelContext) private var modelContext
        
        @State private var selectedItems: [PhotosPickerItem] = []
        @State private var travelPhotos: [TravelPhoto] = []
        @State private var viewMode: ViewMode = .map2D
        @State private var isProcessing: Bool = false
        
        // 드라이브 시뮬레이션 제어 상태
        @State private var isDriving: Bool = false
        @State private var isChaseCam: Bool = true
        @State private var driveSpeed: Float = 1.0
        @State private var processingID = UUID()
        
        enum ViewMode: String, CaseIterable {
            case map2D = "2D 지도"
            case scene3D = "3D 입체 맵"
        }
        
        var body: some View {
            NavigationStack {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    if travelPhotos.isEmpty {
                        // 최초 진입 화면
                        VStack(spacing: 20) {
                            Image(systemName: "car.side.fill")
                                .font(.system(size: 64))
                                .foregroundColor(.cyan)
                            
                            Text("My Road Way")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("여행 사진을 선택하면\n내 여행 코스를 질주하는 3D 드라이브가 시작됩니다.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.gray)
                            
                            PhotosPicker(
                                selection: $selectedItems,
                                maxSelectionCount: 10,
                                matching: .images
                            ) {
                                Label("사진 선택하기 📸", systemImage: "photo.stack")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 14)
                                    .background(Color.cyan, in: Capsule())
                            }
                        }
                        .padding()
                    } else {
                        // 메인 디스플레이
                        VStack(spacing: 0) {
                            if viewMode == .scene3D {
                                SceneKit3DView(
                                    photos: travelPhotos,
                                    isDriving: $isDriving,
                                    isChaseCam: $isChaseCam,
                                    driveSpeed: driveSpeed
                                )
                                .id(travelPhotos.map(\.id))
                            } else {
                                Map2DView(photos: $travelPhotos)
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
                                .frame(width: 190)
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
                            
                            // 하단 드라이브 제어 패널 (3D 모드 전용)
                            if viewMode == .scene3D {
                                HStack(spacing: 16) {
                                    Button(action: {
                                        isDriving.toggle()
                                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                                    }) {
                                        HStack(spacing: 8) {
                                            Image(systemName: isDriving ? "pause.fill" : "play.fill")
                                            Text(isDriving ? "주행 중" : "드라이브 출발 🚗")
                                        }
                                        .font(.headline)
                                        .foregroundColor(isDriving ? .black : .white)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 12)
                                        .background(isDriving ? Color.cyan : Color.white.opacity(0.18), in: Capsule())
                                    }
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        isChaseCam.toggle()
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }) {
                                        Label(
                                            isChaseCam ? "추적 시점 🎥" : "자유 시점 🌐",
                                            systemImage: isChaseCam ? "video.fill" : "globe"
                                        )
                                        .font(.caption).bold()
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(Color.white.opacity(0.18), in: Capsule())
                                    }
                                    
                                    Button(action: {
                                        driveSpeed = (driveSpeed == 1.0) ? 2.0 : 1.0
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }) {
                                        Text("\(Int(driveSpeed))x")
                                            .font(.caption).bold()
                                            .foregroundColor(.cyan)
                                            .frame(width: 38, height: 38)
                                            .background(Color.white.opacity(0.18), in: Circle())
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                                .overlay(RoundedRectangle(cornerRadius: 24).stroke(Color.cyan.opacity(0.4), lineWidth: 1))
                                .padding(.horizontal, 20)
                                .padding(.bottom, 24)
                            }
                        }
                    }
                    
                    if isProcessing {
                        Color.black.opacity(0.6).ignoresSafeArea()
                        ProgressView("사진 위치를 분석하고 여행 경로를 만드는 중...")
                            .tint(.white)
                            .foregroundColor(.white)
                    }
                }
                .navigationBarHidden(true)
                // ios 17대응 FIX..
                .onChange(of: selectedItems) {
                    processSelectedPhotos(selectedItems)
                }
                .onChange(of: viewMode) { _, newMode in
                    if newMode == .map2D {
                        isDriving = false
                    }
                }
                .task {
                    loadSavedSpots()
                }
            }
        }
        
        // MARK: - 저장된 여행 데이터 불러오기 (앱 시작 시 자동 로드)
        @MainActor
        private func loadSavedSpots() {
            guard travelPhotos.isEmpty, !isProcessing else { return }
            
            let descriptor = FetchDescriptor<TravelSpot>(
                sortBy: [SortDescriptor(\.takenAt, order: .forward)]
            )
            guard let savedSpots = try? modelContext.fetch(descriptor), !savedSpots.isEmpty else { return }
            
            var loaded: [TravelPhoto] = []
            for spot in savedSpots {
                if let image = ImageFileManager.loadImage(fileName: spot.imageFileName) {
                    loaded.append(
                        TravelPhoto(
                            id: spot.id,
                            image: image,
                            coordinate: spot.coordinate,
                            date: spot.takenAt,
                            memo: spot.memo
                        )
                    )
                }
            }
            
            if !loaded.isEmpty {
                travelPhotos = calculate3DCoordinates(for: loaded)
            }
        }
        
        // 사진 파싱 및 초경량 다운샘플링 + 로컬 저장 및 SwiftData 엔티티 생성
        @MainActor
        private func processSelectedPhotos(_ items: [PhotosPickerItem]) {
            guard !items.isEmpty else { return }
            
            let requestID = UUID()
            processingID = requestID
            isProcessing = true
            isDriving = false

            Task { @MainActor in
                var extracted: [TravelPhoto] = []
                var spotsToInsert: [TravelSpot] = []

                for item in items {
                    guard processingID == requestID else { return }

                    do {
                        guard let data = try await item.loadTransferable(
                            type: Data.self
                        ) else {
                            continue
                        }

                        guard processingID == requestID else { return }

                        // GPS가 없는 사진은 제외
                        guard let (coordinate, date) = extractEXIF(from: data),
                              let thumbnail = createOptimizedThumbnail(
                                from: data,
                                maxDimension: 800
                              ) else {
                            continue
                        }

                        let spotID = UUID()
                        let fileName = "\(spotID.uuidString).jpg"

                        // 1. 디스크에 썸네일 이미지 파일 저장
                        try ImageFileManager.saveImage(thumbnail, fileName: fileName)

                        // 2. SwiftData TravelSpot 모델 준비
                        let spot = TravelSpot(
                            id: spotID,
                            createdAt: Date(),
                            latitude: coordinate.latitude,
                            longitude: coordinate.longitude,
                            takenAt: date,
                            memo: "",
                            imageFileName: fileName
                        )
                        spotsToInsert.append(spot)

                        // 3. UI 표시용 TravelPhoto 모델 준비 (동일한 spotID 사용)
                        extracted.append(
                            TravelPhoto(
                                id: spotID,
                                image: thumbnail,
                                coordinate: coordinate,
                                date: date,
                                memo: ""
                            )
                        )
                    } catch {
                        // 개별 사진 저장 실패 시 스킵
                        continue
                    }
                }

                guard processingID == requestID else { return }

                if !spotsToInsert.isEmpty {
                    // 이전 스팟 및 이미지 정리 (새 여행 코스로 대체)
                    let oldSpots = (try? modelContext.fetch(FetchDescriptor<TravelSpot>())) ?? []
                    for oldSpot in oldSpots {
                        ImageFileManager.deleteImage(fileName: oldSpot.imageFileName)
                        modelContext.delete(oldSpot)
                    }

                    // 새 스팟 저장
                    for spot in spotsToInsert {
                        modelContext.insert(spot)
                    }
                    try? modelContext.save()
                }

                extracted.sort { $0.date < $1.date }
                travelPhotos = calculate3DCoordinates(for: extracted)
                isProcessing = false
            }
        }
        
        // ⭐ [핵심 메서드]: 메모리 99% 절감 + EXIF 회전 100% 자동 직립
        private func createOptimizedThumbnail(from data: Data, maxDimension: CGFloat) -> UIImage? {
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true, // ⭐ 세로 사진 똑바로 세우기
                kCGImageSourceThumbnailMaxPixelSize: maxDimension,
                kCGImageSourceShouldCacheImmediately: true
            ]
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
                return nil
            }
            return UIImage(cgImage: cgImage)
        }
        
        // EXIF 파서
        private func extractEXIF(from data: Data) -> (CLLocationCoordinate2D, Date)? {
            guard let source = CGImageSourceCreateWithData(data as CFData, nil),
                  let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
                return nil
            }
            
            var coordinate: CLLocationCoordinate2D? = nil
            var date: Date = Date()
            
            if let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any],
               let lat = gps[kCGImagePropertyGPSLatitude] as? Double,
               let latRef = gps[kCGImagePropertyGPSLatitudeRef] as? String,
               let lon = gps[kCGImagePropertyGPSLongitude] as? Double,
               let lonRef = gps[kCGImagePropertyGPSLongitudeRef] as? String {
                
                let finalLat = (latRef == "S") ? -lat : lat
                let finalLon = (lonRef == "W") ? -lon : lon
                coordinate = CLLocationCoordinate2D(latitude: finalLat, longitude: finalLon)
            }
            
            if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
               let dateString = exif[kCGImagePropertyExifDateTimeOriginal] as? String {
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                if let parsedDate = formatter.date(from: dateString) {
                    date = parsedDate
                }
            }
            
            guard let finalCoord = coordinate,
                  CLLocationCoordinate2DIsValid(finalCoord) else {
                return nil
            }
            return (finalCoord, date)
        }
        
        private func calculate3DCoordinates(for photos: [TravelPhoto]) -> [TravelPhoto] {
            guard !photos.isEmpty else { return [] }
            
            let avgLat = photos.map { $0.coordinate.latitude }.reduce(0, +) / Double(photos.count)
            let avgLon = photos.map { $0.coordinate.longitude }.reduce(0, +) / Double(photos.count)
            
            let metersPerDegreeLat = 111320.0
            let metersPerDegreeLon = 111320.0 * cos(avgLat * .pi / 180.0)
            
            var rawMeters: [(x: Float, z: Float)] = []
            var maxDistance: Float = 0.0
            
            for p in photos {
                let dLat = p.coordinate.latitude - avgLat
                let dLon = p.coordinate.longitude - avgLon
                
                let mx = Float(dLon * metersPerDegreeLon)
                let mz = Float(-dLat * metersPerDegreeLat)
                rawMeters.append((mx, mz))
                
                let dist = sqrt(mx * mx + mz * mz)
                if dist > maxDistance { maxDistance = dist }
            }
            
            let targetRadius: Float = 6.0
            let finalScale: Float = (maxDistance > 1.0) ? (targetRadius / maxDistance) : 1.0
            
            var result = photos
            for i in 0..<result.count {
                let x = rawMeters[i].x * finalScale
                let z = rawMeters[i].z * finalScale
                let y: Float = 2.2
                
                result[i].local3DPosition = SCNVector3(x, y, z)
            }
            return result
        }
    }

    // MARK: - 3. SceneKit 3D 뷰 (미니카 & 추적 카메라 탑재)
    struct SceneKit3DView: UIViewRepresentable {
        let photos: [TravelPhoto]
        @Binding var isDriving: Bool
        @Binding var isChaseCam: Bool
        var driveSpeed: Float
        
        func makeUIView(context: Context) -> SCNView {
            let scnView = SCNView()
            scnView.backgroundColor = UIColor(red: 0.04, green: 0.04, blue: 0.08, alpha: 1.0)
            scnView.allowsCameraControl = !isChaseCam
            scnView.autoenablesDefaultLighting = false
            scnView.delegate = context.coordinator
            
            let scene = SCNScene()
            scnView.scene = scene
            context.coordinator.scnView = scnView
            context.coordinator.scene = scene
            
            // 카메라 노드
            let cameraNode = SCNNode()
            cameraNode.camera = SCNCamera()
            cameraNode.camera?.fieldOfView = 55
            cameraNode.position = SCNVector3(0, 11, 14)
            cameraNode.eulerAngles = SCNVector3(-0.65, 0, 0)
            scene.rootNode.addChildNode(cameraNode)
            context.coordinator.cameraNode = cameraNode
            scnView.pointOfView = cameraNode
            
            // 조명 시스템
            let lightNode = SCNNode()
            lightNode.light = SCNLight()
            lightNode.light?.type = .directional
            lightNode.light?.color = UIColor.white
            lightNode.light?.intensity = 2000
            lightNode.position = SCNVector3(5, 20, 10)
            scene.rootNode.addChildNode(lightNode)
            
            let ambientLight = SCNNode()
            ambientLight.light = SCNLight()
            ambientLight.light?.type = .ambient
            ambientLight.light?.color = UIColor(white: 0.5, alpha: 1.0)
            scene.rootNode.addChildNode(ambientLight)
            
            // 바닥 평면
            let floorGeo = SCNFloor()
            floorGeo.reflectivity = 0.25
            let floorMat = SCNMaterial()
            floorMat.diffuse.contents = UIColor(red: 0.06, green: 0.07, blue: 0.11, alpha: 1.0)
            floorGeo.materials = [floorMat]
            let floorNode = SCNNode(geometry: floorGeo)
            scene.rootNode.addChildNode(floorNode)
            
            context.coordinator.setupWorld(with: photos)
            return scnView
        }
        
        func updateUIView(_ uiView: SCNView, context: Context) {
            let coordinator = context.coordinator

            coordinator.isDriving = isDriving
            coordinator.isChaseCam = isChaseCam
            coordinator.driveSpeed = driveSpeed

            uiView.allowsCameraControl = !isChaseCam

            if isChaseCam,
               let camera = coordinator.cameraNode,
               uiView.pointOfView !== camera {
                uiView.pointOfView = camera
            }
        }
        
        func makeCoordinator() -> Coordinator {
            Coordinator()
        }
        
        // MARK: - 4. Coordinator
        class Coordinator: NSObject, SCNSceneRendererDelegate {
            weak var scnView: SCNView?
            weak var scene: SCNScene?
            var cameraNode: SCNNode?
            var carNode: SCNNode?
            
            var waypoints: [SCNVector3] = []
            var photoNodes: [SCNNode] = []
            
            var isDriving: Bool = false
            var isChaseCam: Bool = true
            var driveSpeed: Float = 1.0
            
            var currentProgress: Float = 0.0
            private var lastTime: TimeInterval = 0
            // 삭제노드 별도관리..
            private let worldRoot = SCNNode()
            
            func setupWorld(with photos: [TravelPhoto]) {
                guard let scene = scene else { return }

                // 여행 콘텐츠 전용 부모 노드 연결
                if worldRoot.parent == nil {
                    scene.rootNode.addChildNode(worldRoot)
                }

                // 이전 여행 콘텐츠만 제거
                for child in worldRoot.childNodes {
                    child.removeFromParentNode()
                }

                // 이전 상태 초기화
                waypoints.removeAll()
                photoNodes.removeAll()
                carNode = nil
                currentProgress = 0
                lastTime = 0

                guard !photos.isEmpty else { return }

                /*waypoints = photos.map {
                    SCNVector3(
                        $0.local3DPosition.x,
                        0.05,
                        $0.local3DPosition.z
                    )
                }*/
                for photo in photos {
                    let point = SCNVector3(
                        photo.local3DPosition.x,
                        0.05,
                        photo.local3DPosition.z
                    )

                    if let previous = waypoints.last {
                        let dx = point.x - previous.x
                        let dz = point.z - previous.z

                        if dx * dx + dz * dz <= 0.0001 * 0.0001 {
                            continue
                        }
                    }

                    waypoints.append(point)
                }

                var prevGroundPos: SCNVector3?

                for (index, item) in photos.enumerated() {
                    let pos = item.local3DPosition
                    let groundPos = SCNVector3(pos.x, 0, pos.z)

                    // 사진 카드
                    let cardNode = createBillboardThumbnailNode(
                        image: item.image,
                        index: index + 1
                    )
                    cardNode.position = pos
                    worldRoot.addChildNode(cardNode)
                    photoNodes.append(cardNode)

                    // 위치 링
                    let ringGeo = SCNTorus(
                        ringRadius: 0.45,
                        pipeRadius: 0.025
                    )
                    ringGeo.firstMaterial?.diffuse.contents = UIColor.cyan
                    ringGeo.firstMaterial?.emission.contents =
                        UIColor.cyan.withAlphaComponent(0.6)

                    let ringNode = SCNNode(geometry: ringGeo)
                    ringNode.position = groundPos
                    worldRoot.addChildNode(ringNode)

                    // 사진과 지면을 연결하는 기둥
                    let pinLine = SCNCylinder(
                        radius: 0.035,
                        height: CGFloat(pos.y)
                    )
                    pinLine.firstMaterial?.diffuse.contents =
                        UIColor.cyan.withAlphaComponent(0.8)

                    let pinNode = SCNNode(geometry: pinLine)
                    pinNode.position = SCNVector3(
                        pos.x,
                        pos.y / 2,
                        pos.z
                    )
                    worldRoot.addChildNode(pinNode)

                    // 같은 좌표의 구간은 도로 생성을 생략
                    if let prev = prevGroundPos {
                        let dx = groundPos.x - prev.x
                        let dz = groundPos.z - prev.z
                        let distanceSquared = dx * dx + dz * dz

                        if distanceSquared > 0.0001 * 0.0001 {
                            let routeLine = createRouteCylinder(
                                from: prev,
                                to: groundPos
                            )
                            worldRoot.addChildNode(routeLine)
                        }
                    }

                    prevGroundPos = groundPos
                }

                // 차량
                let car = createCyberCarNode()

                if let first = waypoints.first {
                    car.position = SCNVector3(first.x, 0.12, first.z)
                }

                worldRoot.addChildNode(car)
                carNode = car
            }
            
            // 렌더링 프레임 루프 (60/120fps)
            func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
                guard isDriving,
                      waypoints.count >= 2,
                      let car = carNode,
                      let camera = cameraNode else {
                    lastTime = 0
                    return
                }

                guard lastTime != 0 else {
                    lastTime = time
                    return
                }

                let dt = Float(min(max(time - lastTime, 0), 0.1))
                lastTime = time
                
                let totalSegments = Float(waypoints.count - 1)
                let baseStepPerSecond: Float = 0.45 * driveSpeed
                currentProgress += baseStepPerSecond * dt
                
                if currentProgress >= totalSegments {
                    currentProgress = 0.0
                }
                
                let segIndex = Int(floor(currentProgress))
                let nextIndex = min(segIndex + 1, waypoints.count - 1)
                let segFraction = currentProgress - Float(segIndex)
                
                let p0 = waypoints[segIndex]
                let p1 = waypoints[nextIndex]
                
                // 1. 차량 위치 보간
                let carX = p0.x + (p1.x - p0.x) * segFraction
                let carY: Float = 0.12
                let carZ = p0.z + (p1.z - p0.z) * segFraction
                car.position = SCNVector3(carX, carY, carZ)
                
                // 2. 조향 회전
                let dx = p1.x - p0.x
                let dz = p1.z - p0.z
                let heading = atan2(dx, dz)
                car.eulerAngles = SCNVector3(0, heading, 0)
                
                // 3. 체이스캠 추종
                if isChaseCam {
                    let followDistance: Float = 3.2
                    let followHeight: Float = 1.8
                    
                    let targetCamX = carX - sin(heading) * followDistance
                    let targetCamZ = carZ - cos(heading) * followDistance
                    let targetCamY = carY + followHeight
                    
                    let targetCamPos = SCNVector3(targetCamX, targetCamY, targetCamZ)
                    let alpha: Float = 1 - exp(-8 * dt)
                    
                    camera.position = SCNVector3(
                        camera.position.x + (targetCamPos.x - camera.position.x) * alpha,
                        camera.position.y + (targetCamPos.y - camera.position.y) * alpha,
                        camera.position.z + (targetCamPos.z - camera.position.z) * alpha
                    )
                    
                    let lookTarget = SCNVector3(carX + sin(heading) * 1.5, carY + 0.6, carZ + cos(heading) * 1.5)
                    camera.look(at: lookTarget)
                }
            }
            
            private func createCyberCarNode() -> SCNNode {
                let carRoot = SCNNode()
                
                let bodyGeo = SCNBox(width: 0.44, height: 0.16, length: 0.85, chamferRadius: 0.05)
                let bodyMat = SCNMaterial()
                bodyMat.diffuse.contents = UIColor.systemCyan
                bodyMat.metalness.contents = 0.9
                bodyMat.roughness.contents = 0.2
                bodyGeo.materials = [bodyMat]
                let bodyNode = SCNNode(geometry: bodyGeo)
                bodyNode.position = SCNVector3(0, 0.08, 0)
                carRoot.addChildNode(bodyNode)
                
                let cabinGeo = SCNBox(width: 0.36, height: 0.14, length: 0.42, chamferRadius: 0.04)
                let cabinMat = SCNMaterial()
                cabinMat.diffuse.contents = UIColor.black
                cabinGeo.materials = [cabinMat]
                let cabinNode = SCNNode(geometry: cabinGeo)
                cabinNode.position = SCNVector3(0, 0.21, -0.05)
                carRoot.addChildNode(cabinNode)
                
                let headLightGeo = SCNCylinder(radius: 0.045, height: 0.02)
                headLightGeo.firstMaterial?.diffuse.contents = UIColor.white
                headLightGeo.firstMaterial?.emission.contents = UIColor.white
                
                let lightL = SCNNode(geometry: headLightGeo)
                lightL.position = SCNVector3(-0.15, 0.1, 0.43)
                lightL.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
                carRoot.addChildNode(lightL)
                
                let lightR = SCNNode(geometry: headLightGeo)
                lightR.position = SCNVector3(0.15, 0.1, 0.43)
                lightR.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
                carRoot.addChildNode(lightR)
                
                let tailLightGeo = SCNBox(width: 0.36, height: 0.03, length: 0.02, chamferRadius: 0.01)
                tailLightGeo.firstMaterial?.diffuse.contents = UIColor.red
                tailLightGeo.firstMaterial?.emission.contents = UIColor.red
                let tailNode = SCNNode(geometry: tailLightGeo)
                tailNode.position = SCNVector3(0, 0.1, -0.43)
                carRoot.addChildNode(tailNode)
                
                return carRoot
            }
            
            private func createBillboardThumbnailNode(image: UIImage, index: Int) -> SCNNode {
                let parentNode = SCNNode()
                let billboard = SCNBillboardConstraint()
                billboard.freeAxes = .all
                parentNode.constraints = [billboard]
                
                let frameWidth: CGFloat = 2.2
                let frameHeight: CGFloat = 2.6
                let frameGeo = SCNPlane(width: frameWidth, height: frameHeight)
                frameGeo.cornerRadius = 0.15
                frameGeo.firstMaterial?.diffuse.contents = UIColor.white
                frameGeo.firstMaterial?.lightingModel = .constant
                let frameNode = SCNNode(geometry: frameGeo)
                parentNode.addChildNode(frameNode)
                
                let photoWidth: CGFloat = 1.9
                let photoHeight: CGFloat = 1.9
                let photoGeo = SCNPlane(width: photoWidth, height: photoHeight)
                photoGeo.cornerRadius = 0.08
                photoGeo.firstMaterial?.diffuse.contents = image
                photoGeo.firstMaterial?.lightingModel = .constant
                let photoNode = SCNNode(geometry: photoGeo)
                photoNode.position = SCNVector3(0, 0.2, 0.01)
                parentNode.addChildNode(photoNode)
                
                let badgeGeo = SCNCylinder(radius: 0.28, height: 0.02)
                badgeGeo.firstMaterial?.diffuse.contents = UIColor.systemCyan
                let badgeNode = SCNNode(geometry: badgeGeo)
                badgeNode.position = SCNVector3(-frameWidth / 2.0 + 0.1, frameHeight / 2.0 - 0.1, 0.02)
                badgeNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
                parentNode.addChildNode(badgeNode)
                
                let hoverUp = SCNAction.moveBy(x: 0, y: 0.2, z: 0, duration: 1.0 + Double(index) * 0.1)
                hoverUp.timingMode = .easeInEaseOut
                let hoverDown = hoverUp.reversed()
                parentNode.runAction(SCNAction.repeatForever(SCNAction.sequence([hoverUp, hoverDown])))
                
                return parentNode
            }
            
            private func createRouteCylinder(from start: SCNVector3, to end: SCNVector3) -> SCNNode {
                let vector = SCNVector3(end.x - start.x, end.y - start.y, end.z - start.z)
                let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)
                
                let cylinder = SCNCylinder(radius: 0.08, height: CGFloat(distance))
                let mat = SCNMaterial()
                mat.diffuse.contents = UIColor.cyan
                mat.emission.contents = UIColor.cyan.withAlphaComponent(0.9)
                cylinder.materials = [mat]
                
                let node = SCNNode(geometry: cylinder)
                node.position = SCNVector3((start.x + end.x) / 2.0, 0.04, (start.z + end.z) / 2.0)
                
                let axis = SCNVector3(vector.z, 0, -vector.x)
                let angle = acos(vector.y / distance)
                node.rotation = SCNVector4(axis.x, axis.y, axis.z, -angle)
                
                return node
            }
        }
    }

    // MARK: - 4. 2D MapKit 뷰
    struct Map2DView: View {
        @Environment(\.modelContext) private var modelContext
        
        @Binding var photos: [TravelPhoto]
        @State private var position: MapCameraPosition = .automatic
        
        // 현재 어떤 마커가 선택되었나 구분
        @State private var selectedPhotoID: UUID? = nil
        
        // 여행메모 제어를 위한 변수 선언..
        @State private var editingSpot: TravelSpot? = nil
        
        var body: some View {
            Map(position: $position) {
                ForEach(Array(photos.enumerated()), id: \.element.id) {
 index,
 photo in
                    Annotation("스팟 \(index + 1)", coordinate: photo.coordinate) {
                        
                        VStack(spacing: 8) {
                            
                            if selectedPhotoID == photo.id {
                                    Button {
                                        print("\(index + 1)번 메모 입력창 열기")
                                        
                                        let targetID = photo.id
                                        
                                        // 1. 고유 UUID로 일치하는 TravelSpot 찾기 (동일한 초에 찍힌 사진도 완벽 분리)
                                        let fetchDescriptor = FetchDescriptor<TravelSpot>(
                                            predicate: #Predicate {
                                                $0.id == targetID
                                            }
                                        )
                                        
                                        if let spot = try? modelContext.fetch(fetchDescriptor).first {
                                            editingSpot = spot
                                        } else {
                                            let newSpot = TravelSpot(
                                                id: photo.id,
                                                createdAt: Date(),
                                                latitude: photo.coordinate.latitude,
                                                longitude: photo.coordinate.longitude,
                                                takenAt: photo.date,
                                                memo: photo.memo,
                                                imageFileName: "\(photo.id.uuidString).jpg"
                                            )
                                            modelContext.insert(newSpot)
                                            editingSpot = newSpot
                                        }
                                        
                                    } label: {
                                        Text("여행메모 📝")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                            .shadow(radius: 3)
                                    }
                            }
                            
                            ZStack
                            {
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
                            }.onTapGesture {
                                // MARK: 여행메모 기능추가..
                                withAnimation(.spring()) {
                                    if selectedPhotoID == photo.id {
                                        selectedPhotoID = nil
                                    } else {
                                        selectedPhotoID = photo.id
                                    }
                                }
                                
                            }
                        }
                    }
                }
                MapPolyline(coordinates: photos.map { $0.coordinate })
                    .stroke(Color.cyan, lineWidth: 3)
            }
            .mapStyle(.hybrid(elevation: .realistic))
            .sheet(item: $editingSpot) { spot in
                MemoEditorView(spot: spot) { updatedText in
                    // TravelPhoto 배열의 메모도 동기화
                    if let idx = photos.firstIndex(where: { $0.id == spot.id }) {
                        photos[idx].memo = updatedText
                    }
                    editingSpot = nil
                }
            }
        }
    }

    
    // MARK: - 5. 여행 메모 입력뷰
    struct MemoEditorView: View {
        @Environment(\.dismiss) private var dismiss
        @Environment(\.modelContext) private var modelContext
        
        let spot: TravelSpot

        @State private var memoText: String = ""
        @State private var showErrorAlert: Bool = false
        @State private var errorMessage: String = ""
        
        // 부모뷰에게 성공 전달할 Closure
        var onSave: (String) -> Void
        
        var body: some View {
            NavigationStack {
                VStack(spacing: 20) {
                    Text("스팟 정보: \(spot.takenAt.formatted())에 촬영됨")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    // 에디터 구현 부분
                    TextEditor(text: $memoText)
                        .frame(height: 150)
                        .padding(8)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        }
                    
                    // 저장기능 구현
                    Button {
                        saveMemo()
                    } label: {
                        Text("저장하기")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    Spacer()
                }
                .padding()
                .navigationTitle(spot.memo.isEmpty ? "여행메모 작성" : "여행메모 수정")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("닫기") {
                            dismiss()
                        }
                    }
                }
                .onAppear {
                    memoText = spot.memo
                }
                .alert("메모 저장 실패", isPresented: $showErrorAlert) {
                    Button("확인", role: .cancel) { }
                } message: {
                    Text(errorMessage.isEmpty ? "메모를 저장하지 못했습니다. 입력하신 내용은 유지되니 다시 시도해 주세요." : errorMessage)
                }
            }
        }
        
        private func saveMemo() {
            spot.memo = memoText
            do {
                try modelContext.save()
                onSave(memoText)
                dismiss()
            } catch {
                errorMessage = "저장 중 오류가 발생했습니다: \(error.localizedDescription)\n입력하신 내용은 유지됩니다."
                showErrorAlert = true
                // 실패 시 dismiss()하지 않고 입력 내용(memoText) 유지
            }
        }
    }


    #Preview {
        ContentView()
    }
