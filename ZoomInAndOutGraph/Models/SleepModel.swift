//
//  SleepModel.swift
//  ZoomInAndOutGraph
//
//  Created by Berke Turanlioglu on 26.12.2023.
//

import Foundation
import Charts

struct SleepData: Decodable {
    let event_type: String
    let version: Int
    let snore_count: Int
    let avg_db: Double
    let max_db: Double
    let start_snore_event_timestamp: String
    let max_snore_db: Double
    let avg_snore_db: Double
    let noise_level: Double
    let datetime: String
    let noise_increase_percentage: Double
    let category: String
    
    init(event_type: String, version: Int, snore_count: Int, avg_db: Double, max_db: Double, start_snore_event_timestamp: String, max_snore_db: Double, avg_snore_db: Double, noise_level: Double, datetime: String, noise_increase_percentage: Double, category: String) {
        self.event_type = event_type
        self.version = version
        self.snore_count = snore_count
        self.avg_db = avg_db
        self.max_db = max_db
        self.start_snore_event_timestamp = start_snore_event_timestamp
        self.max_snore_db = max_snore_db
        self.avg_snore_db = avg_snore_db
        self.noise_level = noise_level
        self.datetime = datetime
        self.noise_increase_percentage = noise_increase_percentage
        self.category = category
    }
}

struct SleepModel: Decodable {
    let max_snore_db: Double
    let datetime: Date
    let category: String
    
    init(max_snore_db: Double, datetime: Date, category: String) {
        self.max_snore_db = max_snore_db
        self.datetime = datetime
        self.category = category
    }
}

struct SleepNewModel: Decodable, Plottable {
    var primitivePlottable: String {
        return datetime
    }
    init?(primitivePlottable: String) {
        self.init(primitivePlottable: primitivePlottable)
    }
    
    let max_snore_db: Double
    let date: Date
    let datetime: String
    let category: String
    
    init(max_snore_db: Double, date: Date, datetime: String, category: String) {
        self.max_snore_db = max_snore_db
        self.date = date
        self.datetime = datetime
        self.category = category
    }
}
