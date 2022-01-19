//
//  PlaceViewController.swift
//  Mooskine
//
//  Created by Andi Xu on 12/12/21.
//  Copyright © 2021 Udacity. All rights reserved.
//

import UIKit
import CoreData
import MapKit
import CoreLocation

class PlaceViewController: UIViewController, UITableViewDataSource {
    /// A table view that displays a list of notebooks
    @IBOutlet weak var tableView: UITableView!
    
    var dataController:DataController!
    var geocoder = CLGeocoder()
    var latitude: Float = 0.0
    var longitude: Float = 0.0
    var keyboardIsVisible = false
    
    
    var fetchedResultsController:NSFetchedResultsController<Place>!
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Place> = Place.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "name", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.dataController.viewContext, sectionNameKeyPath: nil, cacheName: "places")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Places"
        navigationItem.rightBarButtonItem = editButtonItem

        setupFetchedResultsController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: false)
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }

    // -------------------------------------------------------------------------
    // MARK: - Actions

    @IBAction func addTapped(sender: Any) {
        presentNewPlaceAlert()
    }

    // -------------------------------------------------------------------------
    // MARK: - Editing

    /// Display an alert prompting the user to name a new notebook. Calls
    /// `addNotebook(name:)`.
    func presentNewPlaceAlert() {
        let alert = UIAlertController(title: "New Places", message: "Enter place name to search", preferredStyle: .alert)

        // Create actions
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let saveAction = UIAlertAction(title: "Search", style: .default) { [weak self] action in
            if let name = alert.textFields?.first?.text {
        
                self?.addPlace(name: name)
            }
        }
        saveAction.isEnabled = false

        // Add a text field
        alert.addTextField { textField in
            textField.placeholder = "Example: New York City, New York"
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: .main) { notif in
                if let text = textField.text, !text.isEmpty {
                    saveAction.isEnabled = true
                } else {
                    saveAction.isEnabled = false
                }
            }
        }

        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        present(alert, animated: true, completion: nil)
    }
    
    func showAlert(message: String, title: String) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertVC, animated: true)
    }

    /// Adds a new notebook to the end of the `notebooks` array
    func addPlace(name: String) {
        let place = Place(context: self.dataController.viewContext)
        place.name = name
        
        geocoder.geocodeAddressString(name) { placemarks, error in
            self.handlePlacemarkResponse(placemarks: placemarks, error: error, name: name, place: place)
        }
        
    }
    
    func handlePlacemarkResponse(placemarks: [CLPlacemark]?, error: Error?, name: String, place: Place) {
            if error != nil {
                showAlert(message: "Location cannot be found.", title: "Please try again.")
                return
            } else {
                if let placemarks = placemarks, placemarks.count > 0 {
                    let location = (placemarks.first?.location)! as CLLocation
                    place.latitude = Float(location.coordinate.latitude)
                    place.longitude = Float(location.coordinate.longitude)
                    try? self.dataController.viewContext.save()
                    print(fetchedResultsController.fetchedObjects)
                } else {
                    showAlert(message: "Location cannot be found.", title: "Please try again.")
                }
            }
        }

    /// Deletes the notebook at the specified index path
    func deletePlace(at indexPath: IndexPath) {
        let pToDelete = fetchedResultsController.object(at: indexPath)
        self.dataController.viewContext.delete(pToDelete)
        try? self.dataController.viewContext.save()
    }

    func updateEditButtonState() {
        if let sections = fetchedResultsController.sections {
            navigationItem.rightBarButtonItem?.isEnabled = sections[0].numberOfObjects > 0
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

    // -------------------------------------------------------------------------
    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let aPlace = fetchedResultsController.object(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: TableViewCell.defaultReuseIdentifier, for: indexPath) as! TableViewCell

        // Configure cell
        cell.nameLabel.text = aPlace.name
        
        if let count = aPlace.notebooks?.count {
            let pageString = count == 1 ? "notebook" : "notebooks"
            cell.countLabel.text = "\(count) \(pageString)"
        }
            
        return cell
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete: deletePlace(at: indexPath)
        default: () // Unsupported
        }
    }

    // -------------------------------------------------------------------------
    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If this is a NotesListViewController, we'll configure its `Notebook`
        if let vc = segue.destination as? NotebooksListViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                vc.place = fetchedResultsController.object(at: indexPath)
                vc.dataController = self.dataController
            }
        }
    }
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//        performSegue(withIdentifier: "tonotebooklist", sender: self)
//        let detailController = self.storyboard!.instantiateViewController(withIdentifier: "detailViewController") as! detailViewController
//
//
//        detailController.m = memes[(indexPath as NSIndexPath).row]
//        self.navigationController!.pushViewController(detailController, animated: true)
//    }

}
extension PlaceViewController:NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
            break
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
            break
        case .update:
            tableView.reloadRows(at: [indexPath!], with: .fade)
        case .move:
            tableView.moveRow(at: indexPath!, to: newIndexPath!)
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert: tableView.insertSections(indexSet, with: .fade)
        case .delete: tableView.deleteSections(indexSet, with: .fade)
        case .update, .move:
            fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
        }
    }

    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
}
