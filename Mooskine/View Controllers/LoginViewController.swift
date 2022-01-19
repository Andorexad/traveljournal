//
//  LoginViewController.swift
//  OnTheMap
//
//  Created by Andi Xu on 7/25/21.
//

import UIKit

class LoginViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        
    }
    
    @IBAction func signUpButtonTapped(_ sender: Any) {
        
    }
    
   
    
    
    func setupTextField(_ textField: UITextField, text: String) {
        textField.delegate = self
        textField.text=text
    }
    
    // ---------VC setup---------
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupTextField(emailTextField, text: "Email")
        setupTextField(passwordTextField, text: "Password")
        setLoggingIn(false)
        subscribeToKeyboardNotifications()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activityIndicator.isHidden = true
        activityIndicator.hidesWhenStopped = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    // ---------keyboard---------
    func getKeyboardHeight(_ notification:Notification) -> CGFloat {
        let userInfo = notification.userInfo
        let keyboardSize = userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue // of CGRect
        return keyboardSize.cgRectValue.height
    }
    
    @objc func keyboardWillShow(_ notification:Notification) {
        if passwordTextField.isFirstResponder {
           view.frame.origin.y = -getKeyboardHeight(notification)
        }
    }
    @objc func keyboardWillHide(_ notification:Notification) {
        view.frame.origin.y = 0
    }

    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    
    
    
    // ---------others---------
    func showLoginFailure(message: String) {
        let alertVC = UIAlertController(title: "Login Failed", message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        show(alertVC, sender: nil)
    }
    
    func setLoggingIn(_ loggingIn: Bool) {
        if loggingIn {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        emailTextField.isEnabled = !loggingIn
        passwordTextField.isEnabled = !loggingIn
        loginButton.isEnabled = !loggingIn
        signUpButton.isEnabled = !loggingIn
       
    }
    
   
//    func handleLoginResponse(status: Bool, error: Error?) {
//        setLoggingIn(false)
//        if !status {
//            var title = ""
//            if error!.localizedDescription == "cannot parse response" {
//                title="The Internet connection is offline"
//            }else {
//                title="The credentials are incorrect"
//            }
//            showAlert(message: "Login Failed", title: title)
//        }else{
//            
//            Client.getUserData { (success, err) in
//                if !success{
//                    self.showAlert(message: err?.localizedDescription ?? "", title: "Can't get user data")
//                }else{
//                    Client.getStudentLocation(limit: 1, skip: nil, order: nil, uniqueKey: Client.Endpoints.Auth.accountKey) { (response, err) in
//                        if response.count == 1
//                         {Client.Endpoints.Auth.objectID = response[0].objectId ?? ""}
//                    }
//                }
//            }
//            
//            let vc=storyboard?.instantiateViewController(withIdentifier: "tabBarController") as! UITabBarController
//            present(vc, animated: true, completion: nil)
//        }
//    }
//    
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.text = ""
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
