//
//  ViewController.swift
//  Gists
//
//  Created by Mohsin Ali Ayub on 01.05.22.
//

import UIKit
import PINRemoteImage

class ViewController: UITableViewController {
    
    private let placeholderImage = UIImage(named: "placeholder")
    private let cellIdentifier = "gistItem"
    private var nextPageURLString: String?
    private var isLoading = false
    private var gists = [Gist]() {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.navigationItem.leftBarButtonItem = self.editButtonItem
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadGists(withURLString: nextPageURLString)
    }

    // MARK: - Actions
    
    @IBAction func insertNewObject(_ sender: Any) {
        let alertController = UIAlertController(title: "Not Implemented", message: "Can't create new gists yet, will implement later", preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
    
    // MARK: - Data Loading
    
    func loadGists(withURLString urlToLoad: String?) {
        self.isLoading = true
        GitHubAPIManager.sharedInstance.fetchPublicGists(pageToLoad: urlToLoad) { result, nextPageURLString  in
            self.nextPageURLString = nextPageURLString
            self.isLoading = false
            
            switch result {
            case .success(let gists):
                if urlToLoad != nil {
                    self.gists += gists
                } else {
                    self.gists = gists
                }
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print(error)
                // TODO: display error
            }
        }
    }
}

// MARK: - Table View Data Source & Delegates

extension ViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        gists.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath)
        
        let gist = gists[indexPath.row]
        
        cell.textLabel?.text = gist.description
        cell.detailTextLabel?.text = gist.owner?.login
        
        if let avatarURL = gist.owner?.avatarURL {
            cell.imageView?.pin_setImage(from: avatarURL, placeholderImage: placeholderImage) { _ in
                if let cellToUpdate = tableView.cellForRow(at: indexPath) {
                    cellToUpdate.setNeedsLayout()
                }
            }
        } else {
            cell.imageView?.image = placeholderImage
        }
        
        // Check if we need to load more gists
        let rowsToLoadFromBottom = 5
        let totalRows = gists.count
        if let nextPage = nextPageURLString {
            if !isLoading && (indexPath.row >= (totalRows - rowsToLoadFromBottom)) {
                loadGists(withURLString: nextPage)
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            gists.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the Gist struct, insert it into the array,
            // and add a new row to the table view.
        }
    }
    
}

