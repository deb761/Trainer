//
//  PhaseSection.swift
//  Trainer
//
//  Created by Deborah Engelmeyer on 9/15/17.
//  Copyright © 2017 The Inquisitive Introvert. All rights reserved.
//

import Foundation

public struct PhaseSection {
    var name: String
    var collapsed: Bool
    
    public init(name: String, collapsed: Bool = true) {
        self.name = name
        self.collapsed = collapsed
    }
}

