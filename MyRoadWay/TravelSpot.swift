//
//  TravelSpot.swift
//  MyRoadWay
//
//  Created by baby Enjhon on 11/9/26.
//

import SwiftData
import CoreLocation

///
///  * Travel
///   ------+
///         |      
///         +---> TravelSpot #1
///         +---> TravelSpot #2
///         +---> TravelSpot #3
///
@Model
final class Travel {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var coverImageName: String

    @Relationship(deleteRule: .cascade, inverse: \TravelSpot.travel)
    var travelSpots: [TravelSpot] = []

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = Date(),
        coverImageName: String,
        travelSpots: [TravelSpot] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.coverImageName = coverImageName
        self.travelSpots = travelSpots
    }
}


@Model
final class TravelSpot {
    @Attribute(.unique) var id: UUID
    var createdAt: Date
    var latitude: Double
    var longitude: Double
    var takenAt: Date
    var memo: String
    var imageFileName: String

    var travel: Travel?
    
    init(
        id: UUID = UUID(),
        createdAt: Date,
        latitude: Double,
        longitude: Double,
        takenAt: Date,
        memo: String,
        imageFileName: String,
        travel: Travel? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.latitude = latitude
        self.longitude = longitude
        self.takenAt = takenAt
        self.memo = memo
        self.imageFileName = imageFileName
        self.travel = travel
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
}
