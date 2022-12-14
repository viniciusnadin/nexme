//
//  ProfileViewModel.swift
//  NexMe
//
//  Created by Vinicius Nadin on 11/09/17.
//  Copyright © 2017 Vinicius Nadin. All rights reserved.
//

import RxSwift

class ProfileViewModel {
    var useCases: UseCases!
    var router: ProfileRouter!
    var disposeBag = DisposeBag()
    let events = Variable<[Event]>([])
    let name = Variable<String>("")
    let email = Variable<String>("")
    let avatarImageURL = Variable<URL?>(nil)
    let followers = Variable<[UserKeys]>([])
    let following = Variable<[UserKeys]>([])
    
    func viewDidLoad() {
        useCases.fetchUser { (result) in
            if let user = self.useCases.getCurrentUser(){
                self.name.value = user.name!.capitalized
                self.email.value = user.email!
                self.followers.value = user.followers
                self.following.value = user.following
                self.avatarImageURL.value = user.avatar?.original
                self.useCases.findEventsByUser(id: user.id!, completion: { (events) in
                    do {
                        self.events.value = try events.getValue().sorted(by: { $0.date < $1.date })
                    } catch {
                        print("Erro Eventos")
                    }
                })
            }}
        
    }
    
    func presentProfile() {
        self.router.presentProfile()
    }
    
    func passwordReset() {
        self.useCases.passwordReset(email: nil)
    }
    
    
}
