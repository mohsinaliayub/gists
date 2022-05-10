//
//  ViewController.swift
//  Gists
//
//  Created by Mohsin Ali Ayub on 01.05.22.
//

import UIKit
import PINRemoteImage
import SafariServices

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
    private var safariViewController: SFSafariViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.navigationItem.leftBarButtonItem = self.editButtonItem
        let gistCellNib = UINib(nibName: "GistInfoCell", bundle: .main)
        tableView.register(gistCellNib, forCellReuseIdentifier: cellIdentifier)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // add refresh control for pull-to-refresh
        if refreshControl == nil {
            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(refresh(sender:)), for: .valueChanged)
        }
        
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadGists(withURLString: nextPageURLString)
        
        if !GitHubAPIManager.sharedInstance.isLoadingOAuthToken {
            loadInitialData()
        }
    }
    
    func loadInitialData() {
        isLoading = true
        GitHubAPIManager.sharedInstance.oAuthTokenCompletionHandler = { error in
            guard error == nil else {
                print(error!)
                self.isLoading = false
                // TODO: handle error
                // something went wrong, try again
                self.showOAuthLoginView()
                return
            }
            
            if let _ = self.safariViewController {
                self.dismiss(animated: false)
            }
            self.loadGists(withURLString: nil)
        }
        
        if !GitHubAPIManager.sharedInstance.hasOAuthToken() {
            showOAuthLoginView()
            return
        }
        
        loadGists(withURLString: nil)
    }

    // MARK: - Actions
    
    @IBAction func insertNewObject(_ sender: Any) {
        let alertController = UIAlertController(title: "Not Implemented", message: "Can't create new gists yet, will implement later", preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "OK", style: .default))
        present(alertController, animated: true)
    }
    
    @objc func refresh(sender: Any) {
        GitHubAPIManager.sharedInstance.isLoadingOAuthToken = false
        nextPageURLString = nil // So, it does not try to append the results
        loadGists(withURLString: nil)
    }
    
    // MARK: - Data Loading
    
    func loadGists(withURLString urlToLoad: String?) {
        self.isLoading = true
        GitHubAPIManager.sharedInstance.fetchMyStarredGists(pageToLoad: urlToLoad) { result, nextPageURLString  in
            self.nextPageURLString = nextPageURLString
            self.isLoading = false
            
            // tell refresh control to stop showing up
            if self.refreshControl != nil && self.refreshControl!.isRefreshing {
                self.refreshControl?.endRefreshing()
            }
            
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
                self.handleLoadGistsError(error)
            }
        }
    }
    
    func handleLoadGistsError(_ error: Error) {
        print(error)
        nextPageURLString = nil
        isLoading = false
        
        switch error {
        case BackendError.authLost:
            self.showOAuthLoginView()
            return
        default:
            break
        }
    }
    
    private func showOAuthLoginView() {
        let storyboard = UIStoryboard(name: "Main", bundle: .main)
        if let loginVC = storyboard.instantiateViewController(withIdentifier: "LoginViewController") as? LoginViewController {
            loginVC.delegate = self
            present(loginVC, animated: true)
        }
    }
}

// MARK: - Table View Data Source & Delegates

extension ViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        gists.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! GistInfoCell
        
        let gist = gists[indexPath.row]
        cell.show(with: gist)
        
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

// MARK: - Login View Controller Delegate
extension ViewController: LoginViewControllerDelegate {
    
    func didTapLoginButton() {
        dismiss(animated: true)
        GitHubAPIManager.sharedInstance.isLoadingOAuthToken = true
        
        guard let authURL = GitHubAPIManager.sharedInstance.urlToStartOAuth2Login() else {
            let error = BackendError.authCouldNot(reason: "Could not obtain an OAuth token")
            GitHubAPIManager.sharedInstance.oAuthTokenCompletionHandler?(error)
            return
        }
        
        safariViewController = SFSafariViewController(url: authURL)
        safariViewController?.delegate = self
        present(safariViewController!, animated: true)
    }
}

// MARK: - Safari View Controller Delegate

extension ViewController: SFSafariViewControllerDelegate {
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        // Detect not being able to load the OAuth URL
        if !didLoadSuccessfully {
            controller.dismiss(animated: true)
            GitHubAPIManager.sharedInstance.isLoadingOAuthToken = false
            let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: [NSLocalizedDescriptionKey: "No Internet connection", NSLocalizedRecoverySuggestionErrorKey: "Please try again."])
            GitHubAPIManager.sharedInstance.oAuthTokenCompletionHandler?(error)
        }
        
        
    }
}
