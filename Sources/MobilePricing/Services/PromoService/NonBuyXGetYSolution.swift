//
//  File.swift
//  
//
//  Created by Michael Rutherford on 2/7/21.
//

import Foundation
import MoneyAndExchangeRates

struct NonBuyXGetYSolution {
    var promoTuples: [PromoTuple] = []
    
    init() {
    }
    
    init(_ promoSolutions: NonBuyXGetYSolution ...) {
        for promoSolution in promoSolutions {
            self.append(contentsOf: promoSolution)
        }
    }
    
    init(_ promoTuples: [PromoTuple]) {
        self.promoTuples = promoTuples
    }
    
    mutating func append(_ promoTuple: PromoTuple) {
        self.promoTuples.append(promoTuple)
    }
    
    mutating func append(contentsOf promoSolution: NonBuyXGetYSolution) {
        self.promoTuples.append(contentsOf: promoSolution.promoTuples)
    }
}
