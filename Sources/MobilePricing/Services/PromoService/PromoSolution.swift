//  Created by Michael Rutherford on 1/30/21.

import Foundation
import MoneyAndExchangeRates

public struct PromoSolution {
    public var unusedFreebies: [UnusedFreebie] = []
    
    init() {
    }
    
    init(_ buyXGetYSolution: BuyXGetYSolution, _ nonBuyXGetYSolution: NonBuyXGetYSolution) {
        unusedFreebies = buyXGetYSolution.unusedFreebies
    }
    
    init(contractSolution: PromoSolution, nonContractSolution: PromoSolution) {
        unusedFreebies = contractSolution.unusedFreebies
        unusedFreebies.append(contentsOf: nonContractSolution.unusedFreebies)
    }
}
