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
        @State private var viewMode: ViewMode = .map2D
        @State private var isProcessing: Bool = false
        
        // 드라이브 시뮬레이션 제어 상태
        @State private var isDriving: Bool = false
        @State private var isChaseCam: Bool = true
        @State private var driveSpeed: Float = 1.0
        
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
                            } else {
                                Map2DView(photos: travelPhotos)
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
                        ProgressView("여행 궤적 및 3D 도로 정밀 재구성 중...")
                            .tint(.white)
                            .foregroundColor(.white)
                    }
                }
                .navigationBarHidden(true)
                .onChange(of: selectedItems) { newItems in
                    guard !newItems.isEmpty else { return }
                    processSelectedPhotos(newItems)
                }
            }
        }
        
        // 사진 파싱 및 초경량 다운샘플링
        private func processSelectedPhotos(_ items: [PhotosPickerItem]) {
            isProcessing = true
            Task {
                var extracted: [TravelPhoto] = []
                
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        // ⭐ [메모리 폭발 박멸]: 하드웨어 가속 800px 다운샘플링 + 회전 자동 보정!
                        if let thumbnail = createOptimizedThumbnail(from: data, maxDimension: 800),
                           let (coord, date) = extractEXIF(from: data) {
                            extracted.append(TravelPhoto(image: thumbnail, coordinate: coord, date: date))
                        }
                    }
                }
                
                extracted.sort(by: { $0.date < $1.date })
                let normalized = calculate3DCoordinates(for: extracted)
                
                await MainActor.run {
                    self.travelPhotos = normalized
                    self.isDriving = false
                    self.isProcessing = false
                }
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
                formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
                if let parsedDate = formatter.date(from: dateString) {
                    date = parsedDate
                }
            }
            
            guard let finalCoord = coordinate else { return nil }
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
            scnView.allowsCameraControl = true
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
            context.coordinator.isDriving = isDriving
            context.coordinator.isChaseCam = isChaseCam
            context.coordinator.driveSpeed = driveSpeed
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
            
            func setupWorld(with photos: [TravelPhoto]) {
                guard let scene = scene, !photos.isEmpty else { return }
                
                scene.rootNode.enumerateChildNodes { (node, _) in
                    if node != cameraNode && node.light == nil && !(node.geometry is SCNFloor) {
                        node.removeFromParentNode()
                    }
                }
                
                self.waypoints = photos.map { SCNVector3($0.local3DPosition.x, 0.05, $0.local3DPosition.z) }
                self.photoNodes.removeAll()
                
                var prevGroundPos: SCNVector3? = nil
                
                for (index, item) in photos.enumerated() {
                    let pos = item.local3DPosition
                    let groundPos = SCNVector3(pos.x, 0, pos.z)
                    
                    let cardNode = createBillboardThumbnailNode(image: item.image, index: index + 1)
                    cardNode.position = pos
                    scene.rootNode.addChildNode(cardNode)
                    photoNodes.append(cardNode)
                    
                    let ringGeo = SCNTorus(ringRadius: 0.45, pipeRadius: 0.025)
                    ringGeo.firstMaterial?.diffuse.contents = UIColor.cyan
                    ringGeo.firstMaterial?.emission.contents = UIColor.cyan.withAlphaComponent(0.6)
                    let ringNode = SCNNode(geometry: ringGeo)
                    ringNode.position = groundPos
                    scene.rootNode.addChildNode(ringNode)
                    
                    let pinLine = SCNCylinder(radius: 0.035, height: CGFloat(pos.y))
                    pinLine.firstMaterial?.diffuse.contents = UIColor.cyan.withAlphaComponent(0.8)
                    let pinNode = SCNNode(geometry: pinLine)
                    pinNode.position = SCNVector3(pos.x, pos.y / 2.0, pos.z)
                    scene.rootNode.addChildNode(pinNode)
                    
                    if let prev = prevGroundPos {
                        let routeLine = createRouteCylinder(from: prev, to: groundPos)
                        scene.rootNode.addChildNode(routeLine)
                    }
                    prevGroundPos = groundPos
                }
                
                let car = createCyberCarNode()
                if let first = waypoints.first {
                    car.position = first
                }
                scene.rootNode.addChildNode(car)
                self.carNode = car
                self.currentProgress = 0.0
                self.lastTime = 0
            }
            
            // 렌더링 프레임 루프 (60/120fps)
            func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
                guard isDriving, waypoints.count >= 2, let car = carNode, let camera = cameraNode else { return }
                
                if lastTime == 0 { lastTime = time }
                var dt = Float(time - lastTime)
                if dt > 0.1 { dt = 0.016 } // 일시정지 후 복귀 시 순간 튐 방지
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
                    
                    camera.position = SCNVector3(
                        camera.position.x + (targetCamPos.x - camera.position.x) * 0.12,
                        camera.position.y + (targetCamPos.y - camera.position.y) * 0.12,
                        camera.position.z + (targetCamPos.z - camera.position.z) * 0.12
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
                MapPolyline(coordinates: photos.map { $0.coordinate })
                    .stroke(Color.cyan, lineWidth: 3)
            }
            .mapStyle(.hybrid(elevation: .realistic))
        }
    }

    #Preview {
        ContentView()
    }
