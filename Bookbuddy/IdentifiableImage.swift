//
//  IdentifiableImage.swift
//  Bookbuddy
//
//  Created by Stephen Spence on 29/10/2025.
//

import UIKit

struct IdentifiableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}
