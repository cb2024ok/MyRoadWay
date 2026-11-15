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
    var id: UUID { representativePhoto.id }

    let representativePhoto: TravelPhoto
    var coordinate: CLLocationCoordinate2D {
        representativePhoto.coordinate
    }

    private(set) var photos: [TravelPhoto]

    init(firstPhoto: TravelPhoto) {
        representativePhoto = firstPhoto
        photos = [firstPhoto]
    }

    mutating func append(_ photo: TravelPhoto) {
        photos.append(photo)
    }
}

func clusterPhotos(_ photos: [TravelPhoto], span: MKCoordinateSpan) -> [PhotoCluster] {
    var clusters: [PhotoCluster] = []
    
    // 지도의 확대 정도에 따라 기준 거리(미터)를 동적으로 계산
    // span.latitudeDelta가 작을수록(확대될수록) 기준 거리가 짧아짐
    let baseDistance = span.latitudeDelta * 111_000.0 * 0.10
    let thresholdDistance = max(20.0, min(5_000.0, baseDistance))
    
    for photo in photos {
        var addedToCluster = false
        
        for i in 0..<clusters.count {
            let clusterLocation = CLLocation(latitude: clusters[i].coordinate.latitude, longitude: clusters[i].coordinate.longitude)
            let photoLocation = CLLocation(latitude: photo.coordinate.latitude, longitude: photo.coordinate.longitude)
            
            // 동적으로 계산된 거리 기준 적용
            if photoLocation.distance(from: clusterLocation) < thresholdDistance {
                //var currentPhotos = clusters[i].photos
                //currentPhotos.append(photo)
                //clusters[i] = PhotoCluster(coordinate: clusters[i].coordinate, photos: currentPhotos)
                clusters[i].append(photo)
                addedToCluster = true
                break
            }
        }
        
        if !addedToCluster {
            clusters.append(PhotoCluster(firstPhoto: photo))
            //clusters.append(PhotoCluster(coordinate: photo.coordinate, photos: [photo]))
        }
    }
    return clusters
}
