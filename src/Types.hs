module Types where

import           Data.Vector (Vector)

type Alpha = Double

type Beta = Double

data CustomerColor
  = Yellow
  | Red
  | Blue

data CustomerType =
  CustomerType CustomerColor Alpha Beta

data Customer =
  Customer
    { arrivedAt      :: Seconds
    , processingTime :: Double
    }

type Seconds = Double

data State =
  State
    { queue               :: Vector Customer
    , lastArrived         :: Seconds
    , totalWaitingSeconds :: Seconds
    , maxWaitingSeconds   :: Seconds
    , totalQueueLength    :: Int
    , maxQueueLength      :: Int
    , customersServed     :: Int
    , tellerFreeAt        :: Double
    , seconds             :: Seconds
    , customerType        :: CustomerType
    }

data Stats =
  Stats
    { statAvgWaitingTime :: Seconds
    , statMaxWaitingTime :: Seconds
    , statAvgQueueLength :: Double
    , statMaxQueueLength :: Int
    }
  deriving (Show)
