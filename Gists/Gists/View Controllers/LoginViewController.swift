//
//  LoginViewController.swift
//  Gists
//
//  Created by Mohsin Ali Ayub on 09.05.22.
//

import UIKit

protocol LoginViewControllerDelegate: AnyObject {
    func didTapLoginButton()
}

class LoginViewController: UIViewController {
    
    weak var delegate: LoginViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func tappedLoginButton() {
        delegate?.didTapLoginButton()
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
