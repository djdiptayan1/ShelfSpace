//
//  librarianModel.swift
//  lms
//
//  Created by Diptayan Jash on 25/04/25.
//

import Foundation
import SwiftUI

struct Librarian: Identifiable {
    let id = UUID()
    var name: String
    var image: UIImage?
    var email: String
    var phone: String
    var libraryCode: String
    var isActive: Bool = true
}
