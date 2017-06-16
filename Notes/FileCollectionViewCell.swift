//
//  FileCollectionViewCell.swift
//  Notes
//
//  Created by Francisco on 6/14/17.
//
//

import UIKit

class FileCollectionViewCell: UICollectionViewCell {
    
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var fileNameLabel: UILabel!
  
  var renameHander: ((Void) -> Void)?
  
  @IBAction func renameTapped() {
    renameHander?()
  }
  
}
