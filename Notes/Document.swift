//
//  Document.swift
//  Notes
//
//  Created by Francisco on 6/14/17.
//
//

import UIKit

class Document: UIDocument {
  
  //Mark: Properties
  var text = NSAttributedString.init(string: "") {
    didSet {
      self.updateChangeCount(UIDocumentChangeKind.done)
    }
  }
  
  var locationWrapper: FileWrapper?
  
  var documentFileWrapper = FileWrapper(directoryWithFileWrappers: [:])
  
  //Mark: Overriden Funcs
  override func contents(forType typeName: String) throws -> Any {
    let textRTFData = try self.text.data(
      from: NSRange(0..<self.text.length),
      documentAttributes:
       [NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType])
    
    if let oldTextFileWrapper = self.documentFileWrapper
      .fileWrappers?[NoteDocumentFileNames.TextFile.rawValue] {
      self.documentFileWrapper.removeFileWrapper(oldTextFileWrapper)
    }
    
    // checking if there is already a location saved
    let rawLocationVal = NoteDocumentFileNames.locationAttachment.rawValue
    
    if self.documentFileWrapper.fileWrappers?[rawLocationVal] == nil {
      // saving the location if there is one
      if let location = self.locationWrapper {
        self.documentFileWrapper.addFileWrapper(location)
      }
    }
    
    self.documentFileWrapper.addRegularFile(withContents: textRTFData,
      preferredFilename: NoteDocumentFileNames.TextFile.rawValue)
    
    return self.documentFileWrapper
  }
  
  override func load(fromContents contents: Any,
                     ofType typeName: String?) throws {
    
    // Ensure that we've been given a file wrapper
    guard let fileWrapper = contents as? FileWrapper else {
      throw err(.cannotLoadFileWrappers)
    }
    
    // Ensure that this is a file wrapper contains the text file,
    // and ensure that we can read it
    guard let textFileWrapper = fileWrapper
      .fileWrappers?[NoteDocumentFileNames.TextFile.rawValue],
      let textFileData = textFileWrapper.regularFileContents else {
        throw err(.cannotLoadText)
    }
    
    // Read in the RTF
    self.text = try NSAttributedString(data: textFileData,
      options: [NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType],
      documentAttributes: nil)
    
    // Keep a reference to the file wrapper
    self.documentFileWrapper = fileWrapper
    
    // Opening the location filewrapper
    let rawLocationVal = NoteDocumentFileNames.locationAttachment.rawValue
    self.locationWrapper = fileWrapper.fileWrappers?[rawLocationVal]
  }
}
