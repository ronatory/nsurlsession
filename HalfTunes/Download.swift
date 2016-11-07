//
//  Download.swift
//  HalfTunes
//
//  Created by ronatory on 07.11.16.
//  Copyright © 2016 ronatory. All rights reserved.
//

import Foundation

class Download: NSObject {
  
  /// the URL of the file to download. This also acts as a unique identifier for a Download
  var url: String
  /// wheter the download is ongoing or paused
  var isDownloading = false
  /// the fractional progress of the download; a float between 0.0 and 1.0
  var progress: Float = 0.0
  /// the URLSessionDownloadTask that downloads the file
  var downloadTask: URLSessionDownloadTask?
  /// stores the NSDta produces when you pause a download task. If the host server supports it, you can use this to resume a paused download in the future
  var resumeData: NSData?
  
  init(url: String) {
    self.url = url
  }
}
