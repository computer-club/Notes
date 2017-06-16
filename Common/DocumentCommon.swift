//
//  DocumentCommon.swift
//  Notes
//
//  Created by Francisco on 6/14/17.
//
//

import Foundation

// We can be throwing a lot of errors in this class, and they'll all
// be in the same error domain and using the same error codes from the same
// enum, so here's a little convenience func to save typing and space

let ErrorDomain = "NotesErrorDomain"

func err(_ code: ErrorCode,
         _ userInfo:[AnyHashable: Any]? = nil) -> NSError {
  // Generate an NSError object, using ErrorDomain, and using whatever
  // value we were passed.
  return NSError(domain: ErrorDomain, code: code.rawValue, userInfo: userInfo)
}

// Names of files/directories in the package
enum NoteDocumentFileNames: String {
  case TextFile = "Text.rtf"
  
  case AttachmentsDirectory = "Attachments"
  
  case QuickLookDirectory = "QuickLook"
  
  case QuickLookTextFile = "Preview.rtf"
  
  case QuickLookThumbnail = "Thumbnail.png"
  
  case locationAttachment = "location.json"
}

let NotesUseiCloudKey = "use_icloud"
let NotesHasPromptedForiCloudKey = "has_prompted_for_icloud"

/// Things that can go wrong
enum ErrorCode: Int {
  
  /// We couldn't find the document at all.
  case cannotAccessDocument
  
  /// We couldn't access any file wrappers inside this document.
  case cannotLoadFileWrappers
  
  /// We couldn't load the Text.rtf file
  case cannotLoadText
  
  /// We couldn't access the attachments folder/
  case cannotAccessAttachments
  
  /// We couldn't save the Text.rtf file.
  case cannotSaveText
  
  /// We couldn't save an attachment
  case cannotSaveAttachment
}
