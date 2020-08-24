module Constants where

import           Types (CustomerColor (Blue, Red, Yellow), CustomerType (CustomerType))

e :: Double
e = 2.71828182845904523536028747135266249775724709369995

alpha :: Double
alpha = 100.0

betaDistributionConstant :: Double
betaDistributionConstant = 200.0

yellow :: CustomerType
yellow = CustomerType Yellow 2.0 5.0

red :: CustomerType
red = CustomerType Red 2.0 2.0

blue :: CustomerType
blue = CustomerType Blue 5.0 1.0
