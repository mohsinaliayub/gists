//
//  ViewController.swift
//  Gists
//
//  Created by Mohsin Ali Ayub on 01.05.22.
//

import UIKit

class ViewController: UITableViewController {

    private let cellIdentifier = "gistItem"
    var gists = [Gist]() {
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
        loadGists()
    }

    // MARK: - Actions
    
    @IBAction func insertNewObject(_ sender: Any) {
        let alertController = UIAlertController(title: "Not Implemented", message: "Can't create new gists yet, will implement later", preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
    
    // MARK: - Data Loading
    
    func loadGists() {
        GitHubAPIManager.sharedInstance.getPublicGists { result in
            switch result {
            case .success(let gists):
                self.gists = gists
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
        
        var configuration = cell.defaultContentConfiguration()
        configuration.text = gist.description
        configuration.secondaryText = gist.owner?.login
        // TODO: set configuration.image to display image at gist.owner.avatarURL
        
        
        cell.contentConfiguration = configuration
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

