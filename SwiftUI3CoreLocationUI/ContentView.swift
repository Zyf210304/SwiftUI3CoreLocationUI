//
//  ContentView.swift
//  SwiftUI3CoreLocationUI
//
//  Created by 张亚飞 on 2021/6/12.
//

import SwiftUI

//New CoreLocation Button For Location Accsss
import CoreLocationUI
import CoreLocation
import MapKit


struct ContentView: View {
    
    //create State Object...
    @StateObject var locationManager = LocationManager()
    
    var body: some View {
        
    
        ZStack(alignment: .bottomTrailing) {
            
            Map(coordinateRegion: $locationManager.region, showsUserLocation: true, annotationItems: locationManager.coffeeShops, annotationContent: { shop in
                
                MapMarker(coordinate: shop.mapItem.placemark.coordinate, tint: .purple)
            })
                .ignoresSafeArea()
            
            LocationButton(.currentLocation) {
                
                locationManager.manager.requestLocation()
            }
            .frame(width: 210, height: 50)
            .symbolVariant(.fill)
            .foregroundColor(.white)
            .tint(.purple)
            .clipShape(Capsule())
            .padding()
        }
        .overlay(
            Text("Coffee Shop")
                .font(.title.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(.ultraThinMaterial)
            
            ,alignment: .top
        )
        
        // basically in swiftUI 3.0 overlay or background
        // will automatically fill safe area alse....
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


// location Manager...
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    
    @Published var manager = CLLocationManager()
    
    @Published var region : MKCoordinateRegion = .init()
    
    @Published var coffeeShops : [Shop] = []
    // setting delegate
    override init() {
        
        super.init()
        manager.delegate = self
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
        print(error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        guard let location = locations.last?.coordinate else {
            return
        }
        
        region = MKCoordinateRegion(center: location, latitudinalMeters: 1000, longitudinalMeters: 1000)
        
        //calling Task...
        async {
            await fetchCoffeeShops()
        }
    }
    
    //sample location search Aync task...
    func fetchCoffeeShops() async {
        
        do {
            
            let request = MKLocalSearch.Request()
            request.region = region
            request.naturalLanguageQuery = "Shop"
            
            let query = MKLocalSearch(request: request)
            
            let response = try await query.start()
            
            //Mapping Map items
            // you can alse use dispathqueen
            await MainActor.run {
               
                self.coffeeShops = response.mapItems.compactMap { item in
                    
                    return Shop(mapItem: item)
                }
                
            }
            
        }
        catch {
            // do something here
        }
    }
}

// sample model for map pins
struct Shop: Identifiable {
    
    var id = UUID().uuidString
    var mapItem: MKMapItem
}
