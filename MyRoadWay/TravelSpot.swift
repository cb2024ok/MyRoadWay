//
//  TravelSpot.swift
//  MyRoadWay
//
//  Created by baby Enjhon on 11/9/26.
//

import SwiftData
import CoreLocation

@Model
final class TravelSpot {
    var id: UUID
    var createdAt: Date
    var latitude: Double
    var longitude: Double
    var takenAt: Date
    var memo: String
    var imageFileName: String
    
    init(
        id: UUID,
        createdAt: Date,
        latitude: Double,
        longitude: Double,
        takenAt: Date,
        memo: String,
        imageFileName: String
    ) {
        self.id = id
        self.createdAt = createdAt
        self.latitude = latitude
        self.longitude = longitude
        self.takenAt = takenAt
        self.memo = memo
        self.imageFileName = imageFileName
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
}
