//
//  File.swift
//  
//
//  Created by Michael Rutherford on 2/7/21.
//

import Foundation
import MoneyAndExchangeRates

struct BuyXGetYSolution {
    var promoTuples: [PromoTuple] = []
    var unusedFreebies: [UnusedFreebie] = []
    
    init() {
    }
    
    init(_ promoSolutions: BuyXGetYSolution ...) {
        for promoSolution in promoSolutions {
            self.append(contentsOf: promoSolution)
        }
    }
    
    init(_ promoTuples: [PromoTuple], _ unusedFreebies: [UnusedFreebie] ) {
        self.promoTuples = promoTuples
        self.unusedFreebies = unusedFreebies
    }
    
    mutating func append(_ promoTuple: PromoTuple) {
        self.promoTuples.append(promoTuple)
    }
    
    mutating func append(contentsOf promoSolution: BuyXGetYSolution) {
        self.promoTuples.append(contentsOf: promoSolution.promoTuples)
        self.unusedFreebies.append(contentsOf: promoSolution.unusedFreebies)
    }
}

