//
//  FileCollectionViewCell.swift
//  Notes
//
//  Created by Francisco on 6/14/17.
//
//

import UIKit

class FileCollectionViewCell: UICollectionViewCell {
  
  ///MARK: Properties
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var fileNameLabel: UILabel!
  @IBOutlet weak var deleteButton: UIButton!
  
  var renameHander: ((Void) -> Void)?
  
  var deletionHander: ((Void) -> Void)?
  
  
  //MARK: Actions
  @IBAction func deleteTapped(_ sender: UIButton) {
    deletionHander?()
  }
  
  @IBAction func renameTapped() {
    renameHander?()
  }
  
  //MARK: Funcs
  
  // This method simply changes the opacity of the cell's deleteButton. 
  // When it is called, it recieves two parameters: first, whether the button 
  // should be visible of not, and second whether the change in opacity should
  // be animated or not.
  func setEditing(_ editing: Bool, animated: Bool) {
    let alpha: CGFloat = editing ? 1.0 : 0.0
    if animated {
      UIView.animate(withDuration: 0.25, animations: {() -> Void in
        self.deleteButton?.alpha = alpha
      })
    } else {
      self.deleteButton?.alpha = alpha
    }
  }
  
}
