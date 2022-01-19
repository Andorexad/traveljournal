//
//  MapViewController.swift
//  Mooskine
//
//  Created by Andi Xu on 12/12/21.
//  Copyright © 2021 Udacity. All rights reserved.
//
import UIKit
import MapKit
import CoreData
import CoreLocation

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, NSFetchedResultsControllerDelegate{
    
    
    @IBOutlet weak var isEditingSwitch: UISwitch!
    @IBOutlet weak var mapView: MKMapView!
    
    // ----------------------
    
    var pins:[Place]?
    var dataController:DataController!
    var geocoder = CLGeocoder()
    var fetchedResultsController:NSFetchedResultsController<Place>!
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Place> = Place.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "places")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    
    
    
    let locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.requestWhenInUseAuthorization()
        return manager
    }()
    
    func setUpMapView() {
        self.mapView.delegate = self
        self.mapView.isZoomEnabled = true
        self.mapView.isScrollEnabled = true
        title = "Travel Locations Map"
        
        mapView.showsCompass = true
        mapView.showsScale = true
        currentLocation()
        setupFetchedResultsController()
    }
    
    func currentLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        try? locationManager.showsBackgroundLocationIndicator = true
        locationManager.startUpdatingLocation()
    }
    
    func fetchPins(){
        do {
            self.pins=fetchedResultsController.fetchedObjects
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
    }
    
    
    
    
    func setUpPins() {
        
        var annotations = [MKPointAnnotation]()
        
        for dictionary in fetchedResultsController.fetchedObjects ?? [] {
            let lat = CLLocationDegrees((dictionary.value(forKeyPath: "latitude") as? Double) ?? 0.0 )
            let long = CLLocationDegrees((dictionary.value(forKeyPath: "longitude") as? Double) ?? 0.0 )
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            annotations.append(annotation)
        }
        self.mapView.addAnnotations(annotations)
    }
    
    func refresh(){
        self.mapView.removeAnnotations(mapView.annotations)
        self.setUpPins()
    }

    
    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpMapView()
        navigationItem.title = "Map"
        
        let uiLPGR = UILongPressGestureRecognizer(target: self, action: #selector(addPin(longGesture:)))
        self.mapView.addGestureRecognizer(uiLPGR)
        
        fetchPins()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        self.refresh()
    }
    
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    
    // MARK: Pin Operation
    
    @objc func addPin(longGesture: UIGestureRecognizer) {
        
        if longGesture.state == .began {
            // add a PIN to the map
            let touchedPoint = longGesture.location(in: mapView)
            let newCoords = mapView.convert(touchedPoint, toCoordinateFrom: mapView)
            let pressedLocation = CLLocation(latitude: newCoords.latitude, longitude: newCoords.longitude)
            var placename = ""
            geocoder.reverseGeocodeLocation(pressedLocation) { (placemarks, err) in
                if err == nil {
                    placename = placemarks?[0].name ?? "No place name available"
                    print(placename)
                    let newPin=Place(context: self.dataController.viewContext)
                    newPin.latitude = Float(pressedLocation.coordinate.latitude)
                    newPin.longitude = Float(pressedLocation.coordinate.longitude)
                    newPin.name = placename
                    do {
                        try self.dataController.viewContext.save()
                    } catch {
                        print ("cannot save new pin to core data")
                    }
                    self.fetchPins()
                    self.refresh()
                }
                else {
                    print("can't find place name")
                }
            }
            
        }
    }
    
    func tapOnPin(of: MKAnnotation, editMode: Bool) {
        let coord = of.coordinate
        for pin in pins! {
            if pin.latitude == Float(coord.latitude) && pin.longitude == Float(coord.longitude) {
                if (editMode){
                    do {
                        dataController.viewContext.delete(pin)
                        try? dataController.viewContext.save()
                        
                    } catch {
                        print("delete pin failed")
                    }
                    break
                } else {
                    performSegue(withIdentifier: "mapToNotebook", sender: pin)
                }
                
            }
        }
        self.fetchPins()
        self.refresh()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If this is a NotesListViewController, we'll configure its `Notebook`
        if let vc = segue.destination as? NotebooksListViewController {
            guard let passedPin = sender as? Place else {
                return
            }
            vc.place = passedPin
            vc.dataController = dataController
        }
    }
    
    // MARK: MapDelegate
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else {
            return
        }
        tapOnPin(of: annotation, editMode: isEditingSwitch.isOn)
    
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView

        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        let defaults = UserDefaults.standard
        let locationData = ["lat": mapView.centerCoordinate.latitude
            , "long": mapView.centerCoordinate.longitude
            , "latDelta": mapView.region.span.latitudeDelta
            , "longDelta": mapView.region.span.longitudeDelta]
        defaults.set(locationData, forKey: "userMapRegion")
    }
    
    // MARK: CLLocationManager
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if let userCoordinate = UserDefaults.standard.dictionary(forKey: "userMapRegion") {
            let center = CLLocationCoordinate2D(latitude: userCoordinate["lat"] as! Double, longitude: userCoordinate["long"] as! Double)
            let span = MKCoordinateSpan(latitudeDelta: userCoordinate["latDelta"] as! Double, longitudeDelta: userCoordinate["longDelta"] as! Double)
            let userRegion = MKCoordinateRegion(center: center, span: span)
            mapView.setRegion(userRegion, animated: true)
        } else {
            let location = locations.last! as CLLocation
            let currentLocation = location.coordinate
            let coordinateRegion = MKCoordinateRegion(center: currentLocation, latitudinalMeters: 100000, longitudinalMeters: 100000)
            mapView.setRegion(coordinateRegion, animated: true)
        }
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
       print(error.localizedDescription)
    }
    
   

}

