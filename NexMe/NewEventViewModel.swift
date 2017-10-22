//
//  NewEventViewModel.swift
//  NexMe
//
//  Created by Vinicius Nadin on 21/10/17.
//  Copyright © 2017 Vinicius Nadin. All rights reserved.
//

import RxSwift
import GooglePlaces
import GoogleMaps

class NewEventViewModel {
    var useCases: UseCases!
    var router: NewEventRouter!
    let disposeBag = DisposeBag()
    let categories = Variable<[EventCategorie]>([])
    
    let successMessage = Variable<String>("")
    let errorMessage = Variable<String>("")
    let loading = Variable<Bool>(false)
    
    let eventName = Variable<String>("")
    let date = Variable<Date>(Date())
    var eventLocation : CLLocationCoordinate2D!
    let eventLocationName = Variable<String>("")
    let eventDescription = Variable<String>("")
    var categorie: EventCategorie!
    let successCreation = Variable<Bool>(false)
    
    func viewDidLoad() {
        self.useCases.createAllCategories()
        self.useCases.findAllCategories(completion: { (categories) in
            let array = categories.value!
            self.categories.value.removeAll()
            self.categories.value.append(contentsOf: array)
        })
    }
    
    func close() {
        self.router.dismiss()
    }
    
    func save(){
        self.loading.value = true
        let event = Event(title: self.eventName.value, coordinate: self.eventLocation, locationName: self.eventLocationName.value, date: self.date.value, image: #imageLiteral(resourceName: "profileImage"), description: self.eventDescription.value, categorie: self.categorie, ownerId: self.useCases.getUserId())
        self.useCases.createEvent(event: event, completion: { (result) in
            do {
                self.loading.value = false
                try result.check()
                self.successMessage.value = "Evento criado com sucesso!! :)"
            } catch {
                self.errorMessage.value = handleError(error: error as NSError)
            }
        })
    }
    
    
}
