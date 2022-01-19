//
//  imageCollectionViewController.swift
//  Mooskine
//
//  Created by Andi Xu on 12/12/21.
//  Copyright © 2021 Udacity. All rights reserved.
//

import UIKit
import CoreData

class imageCollectionViewController: UICollectionViewController {
    
   
    var blockOperation = BlockOperation()
    
    // MARK: DATA
    var place: Place!
    
    var dataController:DataController!
    
    var fetchedResultsController:NSFetchedResultsController<Meme>!

    /// A date formatter for date text in note cells
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()

    fileprivate func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Meme> = Meme.fetchRequest()
        let predicate = NSPredicate(format: "places == %@", place)
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "top", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(place)-memes")
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    var memes:[Meme]?
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        editFlowlayout()
        navigationItem.title = "Album"
        setupFetchedResultsController()
        memes=fetchedResultsController.fetchedObjects!
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        memes=fetchedResultsController.fetchedObjects!
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        self.collectionView.reloadData()
    }
 
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        fetchedResultsController.sections?.count ?? 1
    }

    


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let meme = fetchedResultsController.object(at: indexPath)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CollectionViewCell", for: indexPath) as! CollectionViewCell
        
        cell.topLabel.text = meme.top
        cell.bottomLabel.text = meme.bottom
        cell.picture?.image = UIImage(data: meme.edited!)
        
   
            
        return cell
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath:IndexPath) {

        // Grab the DetailVC from Storyboard
        let detailController = self.storyboard!.instantiateViewController(withIdentifier: "detailViewController") as! detailViewController

        //Populate view controller with data from the selected item
        detailController.m = memes![(indexPath as NSIndexPath).row]

        // Present the view controller using navigation
        navigationController!.pushViewController(detailController, animated: true)

    }

    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If this is a NotesListViewController, we'll configure its `Notebook`
        if let vc = segue.destination as? addImageViewController {
            vc.dataController = dataController
            vc.place=place
        }
    }
    func editFlowlayout() {
        

        let space:CGFloat = 3.0
        let dimension = (view.frame.size.width - (2 * space)) / 4.0

        flowLayout.minimumInteritemSpacing = space
        flowLayout.minimumLineSpacing = space
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
    }
    
}

extension imageCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        //photoCollectionView.beginInteractiveMovementForItem(at: indexPath!)
        
        
        switch type {
            case .insert:
                guard let newIndexPath = newIndexPath else {break}
                blockOperation.addExecutionBlock {
                    self.collectionView.insertItems(at: [newIndexPath])
                }
            case .delete:
                guard let indexPath = indexPath else {break}
                blockOperation.addExecutionBlock {
                    self.collectionView.deleteItems(at: [indexPath])
                }
            case .update:
                guard let indexPath = indexPath else {break}
                blockOperation.addExecutionBlock {
                    DispatchQueue.main.async {
                    self.collectionView.reloadItems(at: [indexPath])
                    }
                }
            case .move:
                guard let newIndexPath = newIndexPath else {break}
                blockOperation.addExecutionBlock {
                    DispatchQueue.main.async {
                    self.collectionView.moveItem(at: indexPath!, to: newIndexPath)
                    }
                }
        
            @unknown default:
                fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert/delete/move/update should be possible.")
        }
        
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperation = BlockOperation()
        
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.collectionView?.performBatchUpdates({self.blockOperation.start()}, completion: nil)
    }
}

