//
//  DocumentListViewController.swift
//  Notes
//
//  Created by Francisco on 6/14/17.
//
//

import UIKit

class DocumentListViewController: UICollectionViewController {
  
  //MARK: Properties
  var availableFiles: [URL] = []
  
  class var iCloudAvailable: Bool {
    if UserDefaults.standard.bool(forKey: NotesUseiCloudKey) == false {
      return false
    }
    
    return FileManager.default.ubiquityIdentityToken != nil
  }
  
  var queryDidFinishGatheringObserver: AnyObject?
  var queryDidUpdateObserver: AnyObject?
  
  // This composes a NSMetadataQuery query to look for files with
  // our Notes file extension by making its predicate search for filenames
  // ending in .note
  var metadataQuery: NSMetadataQuery = {
    let metadataQuery = NSMetadataQuery()
    
    metadataQuery.searchScopes = [NSMetadataQueryUbiquitousDocumentsScope]
    metadataQuery.predicate = NSPredicate(format: "%K LIKE '*.note'",
     NSMetadataItemFSNameKey)
    metadataQuery.sortDescriptors = [
      NSSortDescriptor(key: NSMetadataItemFSContentChangeDateKey,
                       ascending: false)
    ]
    
    return metadataQuery
  }()
  
  // This property gives us the floder in which to store our local documents.
  class var localDocumentsDirectoryURL: URL {
    return FileManager.default.urls(for: .documentDirectory,
                                    in: .userDomainMask).first!
  }
  
  // This property gives us the location of where to put documents in 
  // order for them to be stored in iCloud.
  class var ubiquitousDocumentsDirectoryURL: URL? {
    return FileManager.default.url(forUbiquityContainerIdentifier: nil)?
      .appendingPathComponent("Documents")
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    // Setup the observers which will be updated when the 
    // metatdata query discovers new files.
    
    // The NSMetadataQueryDidUpdateNotification is sent when any new files are
    // discovered after its initial search.
    self.queryDidUpdateObserver = NotificationCenter.default
      .addObserver(forName: NSNotification.Name.NSMetadataQueryDidUpdate,
                   object: metadataQuery,
                   queue: OperationQueue.main) { (notification) in
                    self.queryUpdated()
    }
    
    // The NSMetadataDidFinishGatheringNotification is sent when the 
    // metadata query finishes its initial search for content.
    self.queryDidFinishGatheringObserver = NotificationCenter.default
      .addObserver(
        forName: NSNotification.Name.NSMetadataQueryDidFinishGathering,
        object: metadataQuery,
        queue: OperationQueue.main) { (notification) in
         self.queryUpdated()
    }
    
    // Ask user if they want ot use iCloud.
    let hasPromptedForiCloud = UserDefaults.standard
      .bool(forKey: NotesHasPromptedForiCloudKey)
    
    if hasPromptedForiCloud == false {
      let alert = UIAlertController(title: "Use iCloud?",
       message: "Do you want to store your documents in iCloud, " +
       "or store them locally?",
       preferredStyle: UIAlertControllerStyle.alert)
      
      alert.addAction(
        UIAlertAction(title: "iCloud",
                      style: .default,
                      handler: { (action) in
                      UserDefaults.standard
                       .set(true, forKey: NotesUseiCloudKey)
                      self.metadataQuery.start()
        }))
      
      
      alert.addAction(
        UIAlertAction(title: "Local Only",
                      style: .default,
                      handler: { (action) in
                        UserDefaults.standard
                        .set(false, forKey: NotesUseiCloudKey)
                        
                        self.refreshLocalFilesList()
      }))
      
      self.present(alert, animated: true, completion: nil)
      
      UserDefaults.standard.set(true, forKey: NotesHasPromptedForiCloudKey)
    } else {
      // If already been asked then start searching iCloud or list
      // the collection of local files.
      metadataQuery.start()
      refreshLocalFilesList()
    }
    
    let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self,
      action: #selector(DocumentListViewController.createDocument))
    self.navigationItem.rightBarButtonItem = addButton
  }
  
  func refreshLocalFilesList() {
    // Look for files stored locally
    do {
      var localFiles = try FileManager.default
      .contentsOfDirectory(
        at: DocumentListViewController.localDocumentsDirectoryURL,
        includingPropertiesForKeys: [URLResourceKey.nameKey],
        options: [
         .skipsPackageDescendants,
         .skipsSubdirectoryDescendants
        ]
      )
      
      localFiles = localFiles.filter({ (url) in
        return url.pathExtension == "note"
      })
      
      // If local files were found and iCloud is available, then move these
      // files into iCloud for NSMetadataQuery to find.
      if(DocumentListViewController.iCloudAvailable) {
        // Move these files into iCloudAvailable
        for file in localFiles {
          if let ubiqitousDestinationURL =
          DocumentListViewController.ubiquitousDocumentsDirectoryURL?
            .appendingPathComponent(file.lastPathComponent) {
            do {
              try FileManager.default
              .setUbiquitous(true,
                            itemAt: file,
                            destinationURL: ubiqitousDestinationURL)
            } catch let error as NSError {
              NSLog("Failed to move file \(file) to iCloud: \(error)")
            }
          }
        }
      } else {
        // Add these files to the list of files we know about
        availableFiles.append(contentsOf: localFiles)
      }
    } catch let error as NSError {
      NSLog("Failed to list local documents: \(error)")
    }
  }

  func queryUpdated() {
    self.collectionView?.reloadData()
    
    // Ensure that metatdata query's results can be accessed
    guard let items = self.metadataQuery.results as? [NSMetadataItem] else
    {
      return
    }
    
    // Ensure that iCloud is available-if it's unavailable,
    // we shouldn't bother looking for files.
    guard DocumentListViewController.iCloudAvailable else {
      return
    }
    
    // Clear the list of files we know about.about
    availableFiles = []
    
    // Discover an local files, which don't need to be downloaded.about
    refreshLocalFilesList()
    
    for item in items {
      // Ensure that we can get to the file URL for this item
      guard let url =
        item.value(forAttribute: NSMetadataItemURLKey) as? URL else {
          // We need to have the URL to access it so move on
          // to the next file by breaking out of this loop
          continue
      }
      
      // Add it to the list of availableFiles
      availableFiles.append(url)
      
      // Check to see if we already have the latest verison downloaded
      if itemIsOpenable(url) {
        // We only need to download if itsn't already openable
        continue
      }
      
      // Ask the system to try and download it 
      do {
        try FileManager.default.startDownloadingUbiquitousItem(at: url)
      } catch let error as NSError {
        // We have a problem =(
        print("Error downloading item! \(error)")
      }
    }
  }
  
  func createDocument() {
    // Create a unique name for this new document by adding the date
    let documentName = "Document \(arc4random()).note"
//    let formatter = DocumentListViewController.documentNameDateFormatter
//    let documentDate = formatter.string(from: Date())
//    let documentName = "Document \(documentDate).note"
    
    // Workout where we're going to store it, temporarily
    let documentDestinationURL = DocumentListViewController
     .localDocumentsDirectoryURL
     .appendingPathComponent(documentName)
    
    // Create the document and try to save it locally
    let newDocument = Document(fileURL: documentDestinationURL)
    newDocument.save(to: documentDestinationURL,
     for: .forCreating) { (sucess) -> Void in
      
      if (DocumentListViewController.iCloudAvailable) {
        // If we have the ability to use iCloud...
        // If we sucessfully created it, attempt to move it to iCloud
        if sucess == true, let ubiqitousDestinationURL =
         DocumentListViewController.ubiquitousDocumentsDirectoryURL?
          .appendingPathComponent(documentName) {
           // Perform the move to iCloud in the background
          OperationQueue().addOperation{ () -> Void in
            do {
              try FileManager.default
                .setUbiquitous(true,
                               itemAt: documentDestinationURL,
                               destinationURL: ubiqitousDestinationURL)
              
              OperationQueue.main
                .addOperation { () -> Void in
                  
                  self.availableFiles.append(ubiqitousDestinationURL)
                  self.collectionView?.reloadData()
              }
            } catch let error as NSError {
              NSLog("Error storing document in iCloud!" +
              "\(error.localizedDescription)")
            }
          }
        }
      } else {
        // We can't save it to iCloud, so it stays in local storage
        self.availableFiles.append(documentDestinationURL)
        self.collectionView?.reloadData()
      }
    }
  }
  
  // Return true if the document can be opened right now
  func itemIsOpenable(_ url: URL?) -> Bool {
    
    // Return false if the item is nil
    guard let itemURL = url else {
      return false
    }
    
    // Return true if we don't have access to iCloud (which means
    // that it's not possible for it to be in conflict - we'll always have
    // the latest copy)
    if DocumentListViewController.iCloudAvailable == false {
      return true
    }
    
    // Ask the system for the download status 
    var resource: URLResourceValues
    do {
      resource = try itemURL.resourceValues(forKeys:
       [.ubiquitousItemDownloadingStatusKey])
    } catch let error as NSError {
      NSLog("Failed to get downloading status for \(itemURL): \(error)")
      // If we can't get that then we can't open itemURL
      return false
    }
    
    // Return true if this file is the most current verison
    if resource.ubiquitousItemDownloadingStatus ==
      URLUbiquitousItemDownloadingStatus.current {
      return true
    } else {
      return false
    }
    
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  /*
   // MARK: - Navigation
   
   // In a storyboard-based application, you will often want to do a little preparation before navigation
   override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
   // Get the new view controller using [segue destinationViewController].
   // Pass the selected object to the new view controller.
   }
   */
  
  // MARK: UICollectionViewDataSource
  
  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  
  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    // There are as many cells as there are items in iCloud
    return self.availableFiles.count
  }
  
  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    // Collection view cells are reused and should be dequeued using a cell identifier
    let cellIdentifier = "FileCell"
    
    let cell = collectionView
      .dequeueReusableCell(withReuseIdentifier: cellIdentifier,
                           for: indexPath) as! FileCollectionViewCell
    
    // Get this object from the list of known files
    let url = availableFiles[indexPath.row]
    
    // Get the display name
    var fileName: AnyObject?
    do {
      try (url as NSURL).getResourceValue(&fileName,
                                          forKey: URLResourceKey.nameKey)
      
      if let fileName = fileName as? String {
        cell.fileNameLabel!.text = fileName
      }
    } catch {
      cell.fileNameLabel!.text = "Loading..."
    }
    
    // If this cell is openable, make it fully visible, and
    // make the cell able to be touched
    if itemIsOpenable(url) {
      cell.alpha = 1.0
      cell.isUserInteractionEnabled = true
    } else {
      // But if it's not, make it semittransparent, and 
      // make the cell not respond to input
      cell.alpha = 0.5
      cell.isUserInteractionEnabled = false
    }
    
    return cell
  }
  
  // MARK: UICollectionViewDelegate
  
  /*
   // Uncomment this method to specify if the specified item should be highlighted during tracking
   override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
   return true
   }
   */
  
  /*
   // Uncomment this method to specify if the specified item should be selected
   override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
   return true
   }
   */
  
  /*
   // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
   override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
   return false
   }
   
   override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
   return false
   }
   
   override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
   
   }
   */

}

