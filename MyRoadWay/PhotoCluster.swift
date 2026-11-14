//
//  PhotoCluster.swift
//  MyRoadWay
//
//  Created by baby Enjhon on 11/14/26.
//

import Foundation
import SwiftUI

struct PhotoCluster: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let photos: [TravelPhoto]
    var representativePhoto: TravelPhoto { photos.first! }
}

func clusterPhotos(_ photos: [TravelPhoto]) -> [PhotoCluster] {
    var clusters: [PhotoCluster] = []
    
    for photo in photos {
        var addedToCluster = false
        
        for i in 0..<clusters.count {
            let clusterLocation = CLLocation(latitude: clusters[i].coordinate.latitude, longitude: clusters[i].coordinate.longitude)
            
            let photoLocation = CLLocation(latitude: photo.coordinate.latitude, longitude: photo.coordinate.longitude)
            
            // 5km 이내인 경우 기존 클러스터에 추가..
            if photoLocation.distance(from: clusterLocation) < 5000 {
                var currentPhotos = clusters[i].photos
                currentPhotos.append(photo)
                
                // 중심점 재계산..
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

