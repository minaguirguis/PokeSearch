//
//  ViewController.swift
//  PokeSearch
//
//  Created by Mina Guirguis on 3/7/18.
//  Copyright © 2018 Mina Guirguis. All rights reserved.
//

import UIKit
import MapKit
import FirebaseDatabase

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    
    
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
    var mapHasCenteredOnce = false
    var geoFire: GeoFire!
    var geoFireRef: DatabaseReference!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        mapView.userTrackingMode = MKUserTrackingMode.follow
        
        geoFireRef = Database.database().reference()
        geoFire = GeoFire(firebaseRef: geoFireRef)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        locationAuthStatus()
    }
    
    func locationAuthStatus() {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            //only when in use so we do not drain the user's battery
            mapView.showsUserLocation = true
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, 2000, 2000)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        
        if let loc = userLocation.location {
            if !mapHasCenteredOnce {
                centerMapOnLocation(location: loc)
                mapHasCenteredOnce = true
            }
            
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let annoIdentifier = "Pokemon"
        var annotationView: MKAnnotationView?
        
        if annotation.isKind(of: MKUserLocation.self) {
            annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "User")
            annotationView?.image = UIImage(named: "ash")
        } else if let deqAnno = mapView.dequeueReusableAnnotationView(withIdentifier: annoIdentifier) {
            annotationView = deqAnno
            annotationView?.annotation = annotation
        } else {
            let av = MKAnnotationView(annotation: annotation, reuseIdentifier: annoIdentifier)
            av.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            annotationView = av
        }//we need this "else" statment here in case this deque fails, and we need to create a default annotation
        
        if let annotationView = annotationView, let anno = annotation as? PokeAnnotation{
            
            annotationView.canShowCallout = true//if you show a callout for an annotation you have to set the title
            annotationView.image = UIImage(named: "\(anno.pokemonNumber)")
            //this line above code works greate because our pokemon pics are named as numbers
            let btn = UIButton()
            btn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
            btn.setImage(UIImage(named: "map"), for: .normal)
            annotationView.rightCalloutAccessoryView = btn
            
        }
        //the if statment above is making sure that the annotation view is not nil
        //now if it is a default annotation we are going to go in and customize it
        //also this if statment is making sure we can successfully cast this annotation as a pokeAnnotation
        
        return annotationView
    }
    
    func createSighting(forLocation location: CLLocation, withPokemon pokeID: Int) {
        
        geoFire.setLocation(location, forKey: "\(pokeID)")
    }
    
    func showSightingsOnMap(location: CLLocation) {
        
        let circleQuery = geoFire!.query(at: location, withRadius: 2.5)
        
        _ = circleQuery.observe(GFEventType.keyEntered, with: { (key, location) in
 
            if key != nil, location != nil {
                let anno = PokeAnnotation(coordinate: location.coordinate, pokemonNumber: Int(key)!)
                self.mapView.addAnnotation(anno)
            }
        })
}
    
    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        showSightingsOnMap(location: loc)
    }
    //this function is in place if the user decides to zoom out or in on the mapview
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        if let anno = view.annotation as? PokeAnnotation {
            let place = MKPlacemark(coordinate: anno.coordinate)
            let destination = MKMapItem(placemark: place)
            destination.name = "PokemonSighting"
            let regionDistance: CLLocationDistance = 1000
            let regionSpan = MKCoordinateRegionMakeWithDistance(anno.coordinate, regionDistance, regionDistance)
            
            let options = [MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center), MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span), MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving] as [String : Any]
            //we want to be in the center of the region and span out, and to make sure we show driving directions
            
            MKMapItem.openMaps(with: [destination], launchOptions: options)
            //this should open up maps and pass the information
        }
    }
    //function above is configuring map before we open it
    

    @IBAction func spotRandomPokemon(_ sender: Any) {
        
        let loc = CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)
        //grabbing the center of whatever the user is looking at
        
        let rand = arc4random_uniform(151) + 1
        //we are using numbers because we are using pokemone IDs
        createSighting(forLocation: loc, withPokemon: Int(rand))
        //grab location of map and grab random pokemone to create a sighting
        
    }
}

