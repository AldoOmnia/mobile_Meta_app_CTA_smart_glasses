//
//  CTAService.swift
//  CTA Transit Assistant
//
//  CTA Train Tracker API integration.
//  Endpoints: ttarrivals.aspx, ttfollow.aspx
//

import Foundation

enum CTAServiceError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Could not build request URL. Please check your connection and try again."
        case .networkError(let error):
            return error.localizedDescription
        case .decodingError:
            return "Could not parse the response. The service may be temporarily unavailable."
        }
    }
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
        do {
            let (data, _) = try await session.data(from: url)
            return try parseArrivalsResponse(data)
        } catch _ as DecodingError {
            throw CTAServiceError.decodingError
        } catch {
            throw CTAServiceError.networkError(error)
        }
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
    
    // MARK: - Active Run Numbers (from arrivals at busy stations)
    
    /// Fetches arrivals from busy stations to get run numbers of trains currently in service.
    func fetchActiveRunNumbers() async throws -> [(run: String, route: String)] {
        let stationIds = ["40170", "41820", "40570"]  // Clark/Lake, Jackson, O'Hare
        var seen = Set<String>()
        var result: [(run: String, route: String)] = []
        for mapId in stationIds {
            do {
                let arrivals = try await fetchArrivals(mapId: mapId)
                for a in arrivals {
                    guard let rn = a.runNumber, !rn.isEmpty, !seen.contains(rn) else { continue }
                    seen.insert(rn)
                    result.append((run: rn, route: a.route))
                }
            } catch {
                continue  // Skip failed station
            }
        }
        return result
    }
    
    // MARK: - Follow This Train
    
    func fetchFollowThisTrain(runNumber: String) async throws -> [CTAFollowStop] {
        let runEncoded = runNumber.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? runNumber
        guard let url = URL(string: "\(baseURL)/ttfollow.aspx?key=\(apiKey)&runnumber=\(runEncoded)&outputType=JSON") else {
            throw CTAServiceError.invalidURL
        }
        do {
            let (data, _) = try await session.data(from: url)
            return try parseFollowResponse(data)
        } catch _ as DecodingError {
            throw CTAServiceError.decodingError
        } catch {
            throw CTAServiceError.networkError(error)
        }
    }
    
    private func parseFollowResponse(_ data: Data) throws -> [CTAFollowStop] {
        struct CTAFollowResponse: Decodable {
            let ctatt: CTAFollowAtt?
            struct CTAFollowAtt: Decodable {
                let eta: [ETA]?
                let errCd: String?
                let errNm: String?
                struct ETA: Decodable {
                    let staId: String?
                    let staNm: String?
                    let arrT: String?
                }
            }
        }
        
        let response = try JSONDecoder().decode(CTAFollowResponse.self, from: data)
        guard let ctatt = response.ctatt else { return [] }
        
        // Surface API errors (e.g. "No trains with runnumber X were found")
        if let errCd = ctatt.errCd, errCd != "0", !errCd.isEmpty,
           let errNm = ctatt.errNm, !errNm.isEmpty {
            throw CTAServiceError.networkError(NSError(domain: "CTA", code: Int(errCd) ?? -1, userInfo: [NSLocalizedDescriptionKey: errNm]))
        }
        
        guard let etas = ctatt.eta else { return [] }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return etas.compactMap { eta -> CTAFollowStop? in
            guard let staId = eta.staId, let staNm = eta.staNm else { return nil }
            let arrT = eta.arrT.flatMap { formatter.date(from: $0) }
            return CTAFollowStop(stopId: staId, stopName: staNm, arrivalTime: arrT)
        }
    }
}
