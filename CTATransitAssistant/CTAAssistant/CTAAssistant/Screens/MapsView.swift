//
//  MapsView.swift
//  CTA Transit Assistant
//
//  Map of CTA stations with always-visible glasses launch option
//

import SwiftUI
import MapKit
import UIKit

private let ctaBlue = Color(red: 0, green: 0.184, blue: 0.424)

private func ctaLineUIColor(_ route: String) -> UIColor {
    switch route.uppercased() {
    case "RED": return UIColor(red: 227/255, green: 25/255, blue: 55/255, alpha: 1)
    case "BLUE": return UIColor(red: 0/255, green: 157/255, blue: 220/255, alpha: 1)
    case "BROWN", "BRN": return UIColor(red: 118/255, green: 66/255, blue: 0/255, alpha: 1)
    case "GREEN": return UIColor(red: 0/255, green: 169/255, blue: 79/255, alpha: 1)
    case "ORANGE": return UIColor(red: 244/255, green: 120/255, blue: 54/255, alpha: 1)
    case "PINK": return UIColor(red: 243/255, green: 139/255, blue: 185/255, alpha: 1)
    case "PURPLE", "P": return UIColor(red: 73/255, green: 47/255, blue: 146/255, alpha: 1)
    case "YELLOW", "Y": return UIColor(red: 255/255, green: 232/255, blue: 0/255, alpha: 1)
    default: return UIColor.gray
    }
}

struct MapsView: View {
    @EnvironmentObject var appState: AppState
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.8781, longitude: -87.6298),
        span: MKCoordinateSpan(latitudeDelta: 0.15, longitudeDelta: 0.15)
    )
    @State private var selectedStation: CTAStation?
    @State private var stationArrivals: [CTAArrival] = []
    @State private var arrivalsLoading = false
    
    var body: some View {
        NavigationStack {
            CTAStationMapView(
                region: $region,
                selectedStation: $selectedStation
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(edges: .all)
            .overlay(alignment: .bottom) {
                glassesLaunchBar
            }
            .overlay(alignment: .topTrailing) {
                VStack(alignment: .trailing, spacing: 8) {
                    Button { centerOnUserLocation() } label: {
                        Image(systemName: "location.fill")
                            .font(.title2)
                            .foregroundStyle(ctaBlue)
                    }
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .cornerRadius(10)
                    zoomControls
                }
                .padding(.trailing, 16)
                .padding(.top, 8)
            }
            .navigationTitle("Map")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: selectedStation?.id) {
                await fetchStationArrivals()
            }
        }
    }
    
    private var zoomControls: some View {
        VStack(spacing: 0) {
            Button { zoomIn() } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(ctaBlue)
            }
            .padding(8)
            Button { zoomOut() } label: {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(ctaBlue)
            }
            .padding(8)
        }
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
    
    private func zoomIn() {
        withAnimation(.easeOut(duration: 0.25)) {
            let newSpan = MKCoordinateSpan(
                latitudeDelta: max(0.005, region.span.latitudeDelta / 1.5),
                longitudeDelta: max(0.005, region.span.longitudeDelta / 1.5)
            )
            region = MKCoordinateRegion(center: region.center, span: newSpan)
        }
    }
    
    private func zoomOut() {
        withAnimation(.easeOut(duration: 0.25)) {
            let newSpan = MKCoordinateSpan(
                latitudeDelta: min(0.5, region.span.latitudeDelta * 1.5),
                longitudeDelta: min(0.5, region.span.longitudeDelta * 1.5)
            )
            region = MKCoordinateRegion(center: region.center, span: newSpan)
        }
    }
    
    private func centerOnUserLocation() {
        appState.locationService.startUpdatingLocation()
        guard let loc = appState.locationService.lastLocation else { return }
        withAnimation(.easeOut(duration: 0.25)) {
            region = MKCoordinateRegion(
                center: loc.coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            )
        }
    }
    
    private var glassesLaunchBar: some View {
        VStack(spacing: 0) {
            if let station = selectedStation {
                stationCallout(station)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 12)
            }
            
            Button(action: launchMapOnGlasses) {
                HStack(spacing: 12) {
                    if UIImage(named: "GlassesIcon") != nil {
                        Image("GlassesIcon")
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "glasses")
                            .font(.title)
                            .foregroundColor(.white)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Launch on glasses")
                            .font(.headline)
                        Text("Hear arrivals & directions")
                            .font(.caption)
                            .opacity(0.9)
                    }
                    .foregroundColor(.white)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(ctaBlue)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
    }
    
    private func stationCallout(_ station: CTAStation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(station.stationName)
                .font(.headline)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(station.routes, id: \.self) { route in
                        CTALineBadge(route, compact: true)
                    }
                }
            }
            
            if arrivalsLoading {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading arrivals...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            } else if !stationArrivals.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Next arrivals")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                    ForEach(stationArrivals.prefix(4)) { arrival in
                        HStack(spacing: 8) {
                            CTALineBadge(arrival.route, compact: true)
                            Text("to \(arrival.destination)")
                                .font(.subheadline)
                                .lineLimit(1)
                            Spacer(minLength: 4)
                            Text("\(arrival.predictionMinutes) min")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(ctaBlue)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    private func fetchStationArrivals() async {
        guard let station = selectedStation else {
            stationArrivals = []
            return
        }
        arrivalsLoading = true
        stationArrivals = []
        do {
            stationArrivals = try await appState.ctaService.fetchArrivals(mapId: station.mapId)
        } catch {
            stationArrivals = []
        }
        arrivalsLoading = false
    }
    
    private func launchMapOnGlasses() {
        let station = selectedStation ?? appState.selectedStation ?? appState.locationService.nearestStation
        let message: String
        if let s = station {
            message = "Map centered near \(s.stationName). \(s.routes.joined(separator: ", ")) Line. Say a station name to hear arrivals."
        } else {
            message = "Map view ready. Select a station to hear arrivals and directions on your glasses."
        }
        appState.metaDATService.speakToGlasses(message)
    }
}

// MARK: - MKMapView wrapper (works on iOS 13+)

struct CTAStationMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    @Binding var selectedStation: CTAStation?
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.region = region
        mapView.mapType = .standard
        mapView.showsUserLocation = true
        
        let stations = CTAStationsRepository.shared.allStations
        for station in stations {
            let anno = StationAnnotation(station: station)
            mapView.addAnnotation(anno)
        }
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.region = region
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        let parent: CTAStationMapView
        
        init(_ parent: CTAStationMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation),
                  let anno = annotation as? StationAnnotation else { return nil }
            let reuseId = "station"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
                ?? MKAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            view.annotation = annotation
            view.canShowCallout = false
            
            let route = anno.station.routes.first ?? ""
            let size: CGFloat = 24
            view.subviews.forEach { $0.removeFromSuperview() }
            let circle = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
            circle.backgroundColor = ctaLineUIColor(route)
            circle.layer.cornerRadius = size / 2
            circle.layer.borderWidth = 2
            circle.layer.borderColor = UIColor.white.cgColor
            view.addSubview(circle)
            view.frame = CGRect(x: 0, y: 0, width: size, height: size)
            
            return view
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let anno = view.annotation as? StationAnnotation else { return }
            DispatchQueue.main.async {
                self.parent.selectedStation = anno.station
            }
        }
        
        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            DispatchQueue.main.async {
                self.parent.selectedStation = nil
            }
        }
    }
}

private class StationAnnotation: NSObject, MKAnnotation {
    let station: CTAStation
    
    var coordinate: CLLocationCoordinate2D { station.coordinate }
    var title: String? { station.stationName }
    
    init(station: CTAStation) {
        self.station = station
    }
}
