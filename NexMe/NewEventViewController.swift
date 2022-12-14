//
//  NewEventViewController.swift
//  NexMe
//
//  Created by Vinicius Nadin on 21/10/17.
//  Copyright © 2017 Vinicius Nadin. All rights reserved.
//

import UIKit
import GooglePlaces
import GoogleMaps
import PopupDialog
import FontAwesome_swift
import SkyFloatingLabelTextField
import DateTimePicker
import NVActivityIndicatorView

class NewEventViewController: UIViewController, NVActivityIndicatorViewable {
    
    // MARK: - Properties
    let viewModel: NewEventViewModel
    var googleMapsView : GMSMapView!
    let imagePicker = ImagePicker()
    
    // MARK: - OUTLETS
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextView!
    @IBOutlet weak var mapView: UIView!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var locationTextField: UILabel!
    @IBOutlet weak var descriptionIcon: UIImageView!
    @IBOutlet weak var dateButton: UIButton!
    @IBOutlet weak var dateIcon: UIImageView!
    @IBOutlet weak var categorieButton: UIButton!
    @IBOutlet weak var categorieIcon: UIImageView!
    @IBOutlet weak var mapIcon: UIImageView!
    @IBOutlet weak var pickButton: UIButton!
    @IBOutlet weak var eventImage: UIImageView!
    @IBOutlet weak var nameIcon: UIImageView!
    
    // MARK: - VIEW LIFE CYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        self.viewModel.viewDidLoad()
        self.nameTextField.delegate = self
        self.configurebinds()
        let tapOnView: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(NewEventViewController.dismissKeyboard))
        self.view.addGestureRecognizer(tapOnView)
        
        let overcastBlueColor = UIColor(red: 82/255, green: 205/255, blue: 171/255, alpha: 1.0)
        self.nameIcon.image = UIImage.fontAwesomeIcon(code: "fa-wpforms", textColor: overcastBlueColor, size: CGSize(width: 30, height: 30))
        self.descriptionIcon.image = UIImage.fontAwesomeIcon(code: "fa-newspaper-o", textColor: overcastBlueColor, size: CGSize(width: 30, height: 30))
        self.dateIcon.image = UIImage.fontAwesomeIcon(code: "fa-calendar", textColor: overcastBlueColor, size: CGSize(width: 30, height: 30))
        self.categorieIcon.image = UIImage.fontAwesomeIcon(code: "fa-bookmark", textColor: overcastBlueColor, size: CGSize(width: 30, height: 30))
        self.mapIcon.image = UIImage.fontAwesomeIcon(code: "fa-map-marker", textColor: overcastBlueColor, size: CGSize(width: 30, height: 30))
        self.isEditAction()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.setupGoogleMapsView()
    }
    
    init(viewModel: NewEventViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle{
        return .lightContent
    }
    
    func configurebinds() {
        self.backButton.rx.tap.subscribe(onNext: {
            self.viewModel.close()
        }).disposed(by: self.viewModel.disposeBag)
        
        self.locationButton.rx.tap.subscribe(onNext: {
            let autocompleteController = GMSAutocompleteViewController()
            autocompleteController.delegate = self
            self.present(autocompleteController, animated: true, completion: nil)
        }).disposed(by: self.viewModel.disposeBag)
        
        self.dateButton.rx.tap.subscribe(onNext: {
            self.showDatePicker()
        }).disposed(by: self.viewModel.disposeBag)
        
        self.viewModel.eventLocationName.asObservable().subscribe(onNext: { name in
            self.locationTextField.text = name
        }).disposed(by: self.viewModel.disposeBag)
        
        self.nameTextField.rx.text.orEmpty.map({$0})
            .bind(to: self.viewModel.eventName)
            .disposed(by: self.viewModel.disposeBag)
        
        self.descriptionTextField.rx.text.orEmpty.map({$0})
            .bind(to: self.viewModel.eventDescription)
            .disposed(by: self.viewModel.disposeBag)
        
        self.saveButton.rx.tap.subscribe(onNext: {
            NVActivityIndicatorView.DEFAULT_TYPE = .ballPulseSync
            self.startAnimating()
            self.viewModel.save()
        }).disposed(by: self.viewModel.disposeBag)
        
        self.pickButton.rx.tap.subscribe(onNext: {
            self.imagePicker.pickImageFromViewController(viewController: self) { result in
                do {
                    let image = try result.getValue()
                    self.viewModel.eventImage = image
                    self.eventImage.image = image
                } catch {
                    print(error)
                }
            }
        }).disposed(by: self.viewModel.disposeBag)
        
        self.categorieButton.rx.tap.subscribe({_ in
            self.showCategoriePicker()
        }).disposed(by: self.viewModel.disposeBag)
        
        viewModel.errorMessage.asObservable().filter({!$0.isEmpty})
            .subscribe(onNext: { message in
                self.stopAnimating()
                PopUpDialog.present(title: "Ops!", message: message, viewController: self)
            }).disposed(by: viewModel.disposeBag)
        
        viewModel.successMessage.asObservable().filter({!$0.isEmpty})
            .subscribe(onNext: { message in
                self.stopAnimating()
                let pop2 = PopupDialog(title: "Sucesso!!", message: message, image: nil, buttonAlignment: UILayoutConstraintAxis.horizontal, transitionStyle: PopupDialogTransitionStyle.fadeIn, gestureDismissal: true, completion: {
                    self.viewModel.successCreation.value = true
                })
                self.present(pop2, animated: true, completion: nil)
            }).disposed(by: viewModel.disposeBag)
        
        self.viewModel.successCreation.asObservable().bind { (verify) in
            if verify{self.viewModel.close()}
            }.disposed(by: self.viewModel.disposeBag)
    }
    
    func isEditAction() {
        if self.viewModel.event != nil {
            let event = self.viewModel.event
            self.nameTextField.text = event!.title.capitalized
            self.descriptionTextField.text = event!.description
            self.locationTextField.text = event!.locationName
            self.viewModel.eventLocationName.value = event!.locationName
            self.viewModel.eventName.value = event!.title
            self.categorieButton.setTitle(event?.categorie.name, for: .normal)
            let date = event!.date
            let calendar = Calendar.current
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            let year = calendar.component(.year, from: date)
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            self.dateButton.setTitle("\(hour):\(minute)  \(day)/\(month)/\(year)", for: .normal)
            self.eventImage.kf.setImage(with: event!.image)
        }
    }
    
    func showCategoriePicker() {
        let picker = TCPickerView()
        picker.title = "Categorias"
        let values = self.viewModel.categories.value.map { TCPickerView.Value(title: $0.name) }
        picker.values = values
        picker.completion = { (selected) in
            self.viewModel.categorie = self.viewModel.categories.value[selected]
            self.categorieButton.setTitle(self.viewModel.categorie.name, for: .normal)
        }
        picker.show()
    }
    
    func showDatePicker() {
        let picker = DateTimePicker.show(selected: Date().add(minutes: 6), minimumDate: Date().add(minutes: 5), maximumDate: nil)
        picker.highlightColor = UIColor(red: 255.0/255.0, green: 138.0/255.0, blue: 138.0/255.0, alpha: 1)
        picker.isDatePickerOnly = false
        picker.doneButtonTitle = "Concluido"
        picker.todayButtonTitle = "Agora"
        picker.cancelButtonTitle = "Cancelar"
        picker.timeZone = TimeZone.current
        picker.completionHandler = { date in
            self.viewModel.date.value = date
            let calendar = Calendar.current
            let month = calendar.component(.month, from: date)
            let day = calendar.component(.day, from: date)
            let year = calendar.component(.year, from: date)
            let hour = calendar.component(.hour, from: date)
            let minute = calendar.component(.minute, from: date)
            self.dateButton.setTitle("\(hour):\(minute)  \(day)/\(month)/\(year)", for: .normal)
        }
    }

    func dismissKeyboard() {
        self.view.endEditing(true)
    }
    
    func setupGoogleMapsView(){
        if self.googleMapsView == nil {
            self.googleMapsView = GMSMapView(frame: CGRect(x: 0, y: 0, width: self.mapView.frame.width, height: self.mapView.frame.height))
            self.mapView.addSubview(self.googleMapsView)
        }
        if self.viewModel.event != nil {
            let event = self.viewModel.event
            let position = event!.coordinate
            let camera = GMSCameraPosition.camera(withLatitude: position.latitude, longitude: position.longitude, zoom: 18)
            self.googleMapsView.camera = camera
            let marker = GMSMarker(position: position)
            marker.title = event?.locationName
            marker.map = self.googleMapsView
        }
    }
}

extension NewEventViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.nameTextField {
            self.dismissKeyboard()
        }
        return false
    }
}

extension NewEventViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        self.viewModel.city = ""
        self.locationTextField.text = place.name
        let position = place.coordinate
        let camera = GMSCameraPosition.camera(withLatitude: position.latitude, longitude: position.longitude, zoom: 18)
        self.googleMapsView.camera = camera
        let fullAddress = place.addressComponents
        for address in fullAddress! {
            if (address.type == "administrative_area_level_2"){
                self.viewModel.city = address.name
            }
        }
        let marker = GMSMarker(position: position)
        marker.title = place.name
        marker.map = self.googleMapsView
        self.viewModel.eventLocation = position
        self.viewModel.eventLocationName.value = place.formattedAddress!
        viewController.dismiss(animated: true, completion: nil)
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
}

extension Date {
    func add(minutes: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .minute, value: minutes, to: self)!
    }
}
