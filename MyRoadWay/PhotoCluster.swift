//
//  PhotoCluster.swift
//  MyRoadWay
//
//  Created by baby Enjhon on 11/14/26.
//

import Foundation
import SwiftUI
import MapKit

struct PhotoCluster: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let photos: [TravelPhoto]
    var representativePhoto: TravelPhoto { photos.first! }
}

func clusterPhotos(_ photos: [TravelPhoto], span: MKCoordinateSpan) -> [PhotoCluster] {
    var clusters: [PhotoCluster] = []
    
    // 지도의 확대 정도에 따라 기준 거리(미터)를 동적으로 계산
    // span.latitudeDelta가 작을수록(확대될수록) 기준 거리가 짧아짐
    let baseDistance = span.latitudeDelta * 100000.0
    let thresholdDistance = max(100.0, min(5000.0, baseDistance)) // 최소 100m ~ 최대 5km
    
    for photo in photos {
        var addedToCluster = false
        
        for i in 0..<clusters.count {
            let clusterLocation = CLLocation(latitude: clusters[i].coordinate.latitude, longitude: clusters[i].coordinate.longitude)
            let photoLocation = CLLocation(latitude: photo.coordinate.latitude, longitude: photo.coordinate.longitude)
            
            // 동적으로 계산된 거리 기준 적용
            if photoLocation.distance(from: clusterLocation) < thresholdDistance {
                var currentPhotos = clusters[i].photos
                currentPhotos.append(photo)
                clusters[i] = PhotoCluster(coordinate: clusters[i].coordinate, photos: currentPhotos)
                addedToCluster = true
                break
            }
        }
        
        if !addedToCluster {
            clusters.append(PhotoCluster(coordinate: photo.coordinate, photos: [photo]))
        }
    }
    return clusters
}
