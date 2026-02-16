//
//  CTAService.swift
//  CTA Transit Assistant
//
//  CTA Train Tracker API integration.
//  Endpoints: ttarrivals.aspx, ttfollow.aspx
//

import Foundation

enum CTAServiceError: Error {
    case invalidURL
    case networkError(Error)
    case decodingError
}

final class CTAService {
    private let apiKey = "62027660192b4b53a20d7d370e903e27"
    private let baseURL = "https://lapi.transitchicago.com/api/1.0"
    private let session = URLSession.shared
    
    // MARK: - Arrivals
    
    func fetchArrivals(mapId: String) async throws -> [CTAArrival] {
        guard let url = URL(string: "\(baseURL)/ttarrivals.aspx?key=\(apiKey)&mapid=\(mapId)&outputType=JSON") else {
            throw CTAServiceError.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        return try parseArrivalsResponse(data)
    }
    
    private func parseArrivalsResponse(_ data: Data) throws -> [CTAArrival] {
        struct CTAAPIResponse: Decodable {
            let ctatt: CTAAtt
            struct CTAAtt: Decodable {
                let eta: [ETA]?
                struct ETA: Decodable {
                    let rt: String?
                    let destNm: String?
                    let arrT: String?
                    let prdt: String?
                    let prdctdn: String?  // CTA: predicted minutes
                    let rn: String?
                }
            }
        }
        
        let response = try JSONDecoder().decode(CTAAPIResponse.self, from: data)
        guard let etas = response.ctatt.eta else { return [] }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return etas.compactMap { eta -> CTAArrival? in
            guard let route = eta.rt, let dest = eta.destNm else { return nil }
            let minutes: Int
            if let prdctdn = eta.prdctdn, let m = Int(prdctdn) {
                minutes = m
            } else if let arrT = eta.arrT.flatMap({ formatter.date(from: $0) }),
                      let prdt = eta.prdt.flatMap({ formatter.date(from: $0) }) {
                minutes = max(0, Int(arrT.timeIntervalSince(prdt) / 60))
            } else {
                minutes = 1
            }
            return CTAArrival(
                route: route,
                destination: dest,
                predictionMinutes: minutes > 0 ? minutes : 1,
                runNumber: eta.rn
            )
        }
    }
    
    // MARK: - Follow This Train
    
    func fetchFollowThisTrain(runNumber: String) async throws -> [CTAFollowStop] {
        guard let url = URL(string: "\(baseURL)/ttfollow.aspx?key=\(apiKey)&runnumber=\(runNumber)&outputType=JSON") else {
            throw CTAServiceError.invalidURL
        }
        
        let (data, _) = try await session.data(from: url)
        return try parseFollowResponse(data)
    }
    
    private func parseFollowResponse(_ data: Data) throws -> [CTAFollowStop] {
        struct CTAFollowResponse: Decodable {
            let ctatt: CTAFollowAtt?
            struct CTAFollowAtt: Decodable {
                let route: [RouteStop]?
                struct RouteStop: Decodable {
                    let train: [TrainStop]?
                    struct TrainStop: Decodable {
                        let nextStaId: String?
                        let nextStaNm: String?
                        let arrT: String?
                    }
                }
            }
        }
        
        let response = try JSONDecoder().decode(CTAFollowResponse.self, from: data)
        guard let routes = response.ctatt?.route else { return [] }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        var stops: [CTAFollowStop] = []
        for route in routes {
            for train in route.train ?? [] {
                if let staId = train.nextStaId, let staNm = train.nextStaNm {
                    let arrT = train.arrT.flatMap { formatter.date(from: $0) }
                    stops.append(CTAFollowStop(stopId: staId, stopName: staNm, arrivalTime: arrT))
                }
            }
        }
        return stops
    }
}
