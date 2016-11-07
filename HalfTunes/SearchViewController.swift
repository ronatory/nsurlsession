//
//  SearchViewController.swift
//  HalfTunes
//
//  Created by Ken Toh on 13/7/15.
//  Copyright (c) 2015 Ken Toh. All rights reserved.
//

import UIKit
import MediaPlayer

class SearchViewController: UIViewController {

  @IBOutlet weak var tableView: UITableView!
  @IBOutlet weak var searchBar: UISearchBar!

  var searchResults = [Track]()
  
  // create and initialize URLSession with a default session configuration
  let defaultSession = URLSession(configuration: URLSessionConfiguration.default)
  // declare a URLSessionDataTask which you'll use to make an HTTP GET request to the iTunes Seach web service
  // when the user performs a search. Will be re-initialized and reused each time the user creates a new query
  var dataTask: URLSessionDataTask?
  
  // maintains a mapping between URLs and their active Download, if any
  var activeDownloads = [String: Download]()
  
  lazy var tapRecognizer: UITapGestureRecognizer = {
    var recognizer = UITapGestureRecognizer(target:self, action: #selector(SearchViewController.dismissKeyboard))
    return recognizer
  }()
  
  // you initialize a separate session with a default configuration to handle all your download tasks
  // you also specify a delegate, which lets you receive URLSession events via delegate calls
  // this is useful for tracking not just when a task is complete, but also the progress of the task
  // setting the delegate to nil causes the session to create a serial operation queue, by default, to perform
  // all calls to the delegate methods and completion handlers
  // NOTE: the lazy creation of downloadsSession: this lets you delay the creation of the session until it's needed
  // most importantly, it lets you pass self as the delegate parameter to the initializer - even if self isn't initialized
  lazy var downloadsSession: URLSession = {
    let configuration = URLSessionConfiguration.default
    let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
    return session
  }()
  
  // MARK: View controller methods
  
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.tableFooterView = UIView()
  }
  
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
  }
  
  // MARK: Handling Search Results
  
  // This helper method helps parse response JSON NSData into an array of Track objects.
  func updateSearchResults(_ data: Data?) {
    searchResults.removeAll()
    do {
      if let data = data, let response = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions(rawValue:0)) as? [String: AnyObject] {
        
        // Get the results array
        if let array: AnyObject = response["results"] {
          for trackDictonary in array as! [AnyObject] {
            if let trackDictonary = trackDictonary as? [String: AnyObject], let previewUrl = trackDictonary["previewUrl"] as? String {
              // Parse the search result
              let name = trackDictonary["trackName"] as? String
              let artist = trackDictonary["artistName"] as? String
              searchResults.append(Track(name: name, artist: artist, previewUrl: previewUrl))
            } else {
              print("Not a dictionary")
            }
          }
        } else {
          print("Results key not found in dictionary")
        }
      } else {
        print("JSON Error")
      }
    } catch let error as NSError {
      print("Error parsing results: \(error.localizedDescription)")
    }
    
    DispatchQueue.main.async {
      self.tableView.reloadData()
      self.tableView.setContentOffset(CGPoint.zero, animated: false)
    }
  }
  
  // MARK: Keyboard dismissal
  
  func dismissKeyboard() {
    searchBar.resignFirstResponder()
  }
  
  // MARK: Download methods
  
  // Called when the Download button for a track is tapped
  func startDownload(_ track: Track) {
    if let urlString = track.previewUrl, let url = URL(string: urlString) {
      // initialize a Download with the preview URL of the track
      let download = Download(url: urlString)
      // using your new session object, you create a URLSessionDownloadTask with the preview URL and set it to the downloadTask property of the Download
      download.downloadTask = downloadsSession.downloadTask(with: url)
      // start the download task by calling resume() on it
      download.downloadTask!.resume()
      // indicate that the download is in progress
      download.isDownloading = true
      // finally map the download URL to its Download in the activeDownloads dictionary
      activeDownloads[download.url] = download
    }
  }
  
  // Called when the Pause button for a track is tapped
  func pauseDownload(_ track: Track) {
    // TODO
  }
  
  // Called when the Cancel button for a track is tapped
  func cancelDownload(_ track: Track) {
    // TODO
  }
  
  // Called when the Resume button for a track is tapped
  func resumeDownload(_ track: Track) {
    // TODO
  }
  
   // This method attempts to play the local file (if it exists) when the cell is tapped
  func playDownload(_ track: Track) {
    if let urlString = track.previewUrl, let url = localFilePathForUrl(urlString) {
      let moviePlayer:MPMoviePlayerViewController! = MPMoviePlayerViewController(contentURL: url)
      presentMoviePlayerViewControllerAnimated(moviePlayer)
    }
  }
  
  // MARK: Download helper methods
  
  // This method generates a permanent local file path to save a track to by appending
  // the lastPathComponent of the URL (i.e. the file name and extension of the file)
  // to the path of the app’s Documents directory.
  func localFilePathForUrl(_ previewUrl: String) -> URL? {
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as NSString
    if let url = URL(string: previewUrl) {
//      , let lastPathComponent = url.lastPathComponent
        let fullPath = documentsPath.appendingPathComponent(url.lastPathComponent)
        return URL(fileURLWithPath:fullPath)
    }
    return nil
  }
  
  // This method checks if the local file exists at the path generated by localFilePathForUrl(_:)
  func localFileExistsForTrack(_ track: Track) -> Bool {
    if let urlString = track.previewUrl, let localUrl = localFilePathForUrl(urlString) {
      var isDir : ObjCBool = false
//      if let path = localUrl.path {
        return FileManager.default.fileExists(atPath: localUrl.path, isDirectory: &isDir)
//      }
    }
    return false
  }
}

// MARK: - UISearchBarDelegate

extension SearchViewController: UISearchBarDelegate {
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    // Dimiss the keyboard
    dismissKeyboard()
    
    if !searchBar.text!.isEmpty {
      // check if data task is already initialized. 
      // If so, you can cancel the task as you want to reuse the data task object for the latest query
      if dataTask != nil {
        dataTask?.cancel()
      }
      // enable the network indicator on the status bar to indicate to the user that a network process is running
      UIApplication.shared.isNetworkActivityIndicatorVisible = true
      // before passing the user's search string as a parameter to the query URL, you call addingPercentEncoding on the string to ensure that it's properly escaped
      let expectedCharSet = NSCharacterSet.urlQueryAllowed
      let searchTerm = searchBar.text!.addingPercentEncoding(withAllowedCharacters: expectedCharSet)!
      // construct a URL by appending the escaped search string as a GET parameter to the iTunes Search API base url
      let url = URL(string: "https://itunes.apple.com/search?media=music&entity=song&term=\(searchTerm)")
      // from the session you created, you initialize a URLSessionDataTask to handle the HTTP GET request.
      // the constructor of URLSessionDataTask takes in the URL that you constructed along with a completion handler to be called when the data task completed
      dataTask = defaultSession.dataTask(with: url!) {
        data, response, error in
        // invoke the UI update in the main thread and hide the activity indicator to show that the task is completed
        DispatchQueue.main.async {
          UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
        // if HTTP request is successful you call updateSearchResults(_:) which parses the response NSData into Tracks and updates the table view
        if let error = error {
          print(error.localizedDescription)
        } else if let httpResponse = response as? HTTPURLResponse {
          if httpResponse.statusCode == 200 {
            self.updateSearchResults(data)
          }
        }
      }
      // all tasks start in a suspended state by default, calling resume() starts the data task
      dataTask?.resume()
    }
  }
    
  func position(for bar: UIBarPositioning) -> UIBarPosition {
    return .topAttached
  }
    
  func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    view.addGestureRecognizer(tapRecognizer)
  }
    
  func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    view.removeGestureRecognizer(tapRecognizer)
  }
}

// MARK: TrackCellDelegate

extension SearchViewController: TrackCellDelegate {
  func pauseTapped(_ cell: TrackCell) {
    if let indexPath = tableView.indexPath(for: cell) {
      let track = searchResults[indexPath.row]
      pauseDownload(track)
      tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .none)
    }
  }
  
  func resumeTapped(_ cell: TrackCell) {
    if let indexPath = tableView.indexPath(for: cell) {
      let track = searchResults[indexPath.row]
      resumeDownload(track)
      tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .none)
    }
  }
  
  func cancelTapped(_ cell: TrackCell) {
    if let indexPath = tableView.indexPath(for: cell) {
      let track = searchResults[indexPath.row]
      cancelDownload(track)
      tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .none)
    }
  }
  
  func downloadTapped(_ cell: TrackCell) {
    if let indexPath = tableView.indexPath(for: cell) {
      let track = searchResults[indexPath.row]
      startDownload(track)
      tableView.reloadRows(at: [IndexPath(row: indexPath.row, section: 0)], with: .none)
    }
  }
}

// MARK: UITableViewDataSource

extension SearchViewController: UITableViewDataSource {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return searchResults.count
  }
  
  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "TrackCell", for: indexPath) as!TrackCell
    
    // Delegate cell button tap events to this view controller
    cell.delegate = self
    
    let track = searchResults[indexPath.row]
    
    // Configure title and artist labels
    cell.titleLabel.text = track.name
    cell.artistLabel.text = track.artist

    // If the track is already downloaded, enable cell selection and hide the Download button
    let downloaded = localFileExistsForTrack(track)
    cell.selectionStyle = downloaded ? UITableViewCellSelectionStyle.gray : UITableViewCellSelectionStyle.none
    cell.downloadButton.isHidden = downloaded
    
    return cell
  }
}

// MARK: UITableViewDelegate

extension SearchViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
    return 62.0
  }
  
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let track = searchResults[indexPath.row]
    if localFileExistsForTrack(track) {
      playDownload(track)
    }
    tableView.deselectRow(at: indexPath, animated: true)
  }
}

// MARK: URLSessionDownloadDelegate

extension SearchViewController: URLSessionDownloadDelegate {
  func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
    print("Finished downloading.")
  }
}

