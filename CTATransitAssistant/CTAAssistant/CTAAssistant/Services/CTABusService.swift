//
//  CTABusService.swift
//  CTA Transit Assistant
//
//  CTA Bus Tracker API v2. Get a key at transitchicago.com/developers/bustracker
//

import Foundation

enum CTABusServiceError: LocalizedError {
    case noApiKey
    case invalidURL
    case networkError(Error)
    case noPredictions
    
    var errorDescription: String? {
        switch self {
        case .noApiKey:
            return "Bus tracking requires a CTA Bus Tracker API key. Sign up at transitchicago.com/developers/bustracker"
        case .invalidURL:
            return "Invalid request"
        case .networkError(let err):
            return err.localizedDescription
        case .noPredictions:
            return "No bus arrivals found for this stop"
        }
    }
}

final class CTABusService {
    /// CTA Bus Tracker API key. Sign up at transitchicago.com/developers/bustracker
    private let apiKey: String?
    private let baseURL = "https://www.ctabustracker.com/bustime/api/v2"
    private let session = URLSession.shared
    
    init(apiKey: String? = nil) {
        self.apiKey = apiKey ?? Self.defaultKey
    }
    
    /// Set your key here or add to Info.plist. Get one at transitchicago.com/developers/bustracker
    private static var defaultKey: String? {
        Bundle.main.object(forInfoDictionaryKey: "CTABusTrackerAPIKey") as? String
    }
    
    func fetchPredictions(stopId: String, route: String? = nil) async throws -> [CTABusArrival] {
        guard let key = apiKey, !key.isEmpty else {
            throw CTABusServiceError.noApiKey
        }
        var urlString = "\(baseURL)/getpredictions?key=\(key)&stpid=\(stopId)&format=json"
        if let rt = route, !rt.isEmpty {
            urlString += "&rt=\(rt)"
        }
        guard let url = URL(string: urlString) else {
            throw CTABusServiceError.invalidURL
        }
        let (data, _) = try await session.data(from: url)
        return try parsePredictionsResponse(data)
    }
    
    private func parsePredictionsResponse(_ data: Data) throws -> [CTABusArrival] {
        struct BusResponse: Decodable {
            let bustime_response: BustimeResponse?
            struct BustimeResponse: Decodable {
                let prd: [Prd]?
                let error: [Err]?
                struct Prd: Decodable {
                    let rt: String?
                    let rtdir: String?
                    let destNm: String?
                    let prdctdn: String?
                    let stpnm: String?
                }
                struct Err: Decodable {
                    let msg: String?
                }
            }
        }
        let response = try JSONDecoder().decode(BusResponse.self, from: data)
        guard let bustime = response.bustime_response else { return [] }
        if let errs = bustime.error, let first = errs.first, let msg = first.msg {
            throw CTABusServiceError.networkError(NSError(domain: "CTABus", code: -1, userInfo: [NSLocalizedDescriptionKey: msg]))
        }
        guard let prds = bustime.prd else { return [] }
        return prds.compactMap { p -> CTABusArrival? in
            guard let route = p.rt, let dest = p.destNm else { return nil }
            let prdctdn = p.prdctdn ?? "0"
            let minutes: Int
            if prdctdn.uppercased() == "DUE" || prdctdn == "0" {
                minutes = 1
            } else {
                minutes = max(1, Int(prdctdn) ?? 1)
            }
            return CTABusArrival(
                route: route,
                destination: dest,
                predictionMinutes: minutes,
                stopName: p.stpnm
            )
        }
    }
}
