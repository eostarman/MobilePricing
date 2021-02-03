//  Created by Michael Rutherford on 1/30/21.

import Foundation
import MoneyAndExchangeRates

public struct PromoSolution {
    var promoTuples: [PromoTuple] = []
    var unusedFreebies: [UnusedFreebie] = []
    
    init() {
    }
    
    init(_ promoSolutions: PromoSolution ...) {
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
    
    mutating func append(contentsOf promoSolution: PromoSolution) {
        self.promoTuples.append(contentsOf: promoSolution.promoTuples)
        self.unusedFreebies.append(contentsOf: promoSolution.unusedFreebies)
    }
}
