module Simulator where

import           Constants     (e)
import qualified Constants     as C
import qualified Data.Vector   as V
import           GHC.Float     (powerDouble)
import           System.Random (randomIO)

import           Data.Bool     (bool)
import           Types         (Customer (..), CustomerType (..), Seconds, State (..), Stats (..))

simulate :: Int -> IO [Stats]
simulate seconds = do
  let newStateYellow =
        State
          { queue = V.empty
          , lastArrived = 0.0
          , totalWaitingSeconds = 0.0
          , maxWaitingSeconds = 0.0
          , totalQueueLength = 0
          , maxQueueLength = 0
          , customersServed = 0
          , tellerFreeAt = 0.0
          , seconds = 0.0
          , customerType = C.yellow
          }
      newStateBlue = newStateYellow {customerType = C.blue}
      newStateRed = newStateYellow {customerType = C.red}
  sequence $ simulate' seconds <$> [newStateYellow, newStateBlue, newStateRed]

simulate' :: Int -> State -> IO Stats
simulate' 0 state = pure . getStats $ state
simulate' n state = updateStateIO state >>= simulate' (n - 1)

doesCustomerArrive :: Seconds -> Double -> Double -> Bool
doesCustomerArrive seconds alpha successProb =
  let arrivingProb = arrivingProbability seconds alpha
   in arrivingProb >= successProb

arrivingProbability :: Seconds -> Double -> Double
arrivingProbability seconds alpha = 1.0 - (e `powerDouble` (-seconds / alpha))

getProcessingTime :: Double -> Double -> CustomerType -> Double
getProcessingTime constant x (CustomerType _ alpha beta) =
  constant * (x `powerDouble` (alpha - 1)) * ((1 - x) `powerDouble` (beta - 1))

updateStateIO :: State -> IO State
updateStateIO state = do
  arrivalSuccessProb <- randomIO
  x <- randomIO
  pure . updateState arrivalSuccessProb x $ state

updateState :: Double -> Double -> State -> State
updateState arrivalSuccessProb x State {..}
 -- new cusomer arrival logic
 =
  let addNewCustomer =
        doesCustomerArrive (seconds - lastArrived) C.alpha arrivalSuccessProb
      lastArrived' = bool lastArrived seconds addNewCustomer
      queue' =
        if addNewCustomer
          then V.snoc queue $
               Customer
                 seconds
                 (getProcessingTime C.betaDistributionConstant x customerType)
          else queue
   -- customer serving logic
      shouldServe = seconds >= tellerFreeAt && V.length queue' > 0
      totalWaitingSeconds' =
        totalWaitingSeconds +
        bool 0.0 (seconds - getArrivalTime queue') shouldServe
      maxWaitingSeconds' =
        max maxWaitingSeconds $
        bool 0.0 (seconds - getArrivalTime queue') shouldServe
      totalQueueLength' = totalQueueLength + V.length queue'
      maxQueueLength' = max maxQueueLength $ V.length queue'
      customersServed' = customersServed + bool 0 1 shouldServe
      tellerFreeAt' =
        tellerFreeAt + bool 0.0 (processingTime . V.head $ queue') shouldServe
      queue'' = bool queue' (V.tail queue') shouldServe
   in State
        { queue = queue''
        , lastArrived = lastArrived'
        , totalWaitingSeconds = totalWaitingSeconds'
        , maxWaitingSeconds = maxWaitingSeconds'
        , totalQueueLength = totalQueueLength'
        , maxQueueLength = maxQueueLength'
        , customersServed = customersServed'
        , tellerFreeAt = tellerFreeAt'
        , seconds = seconds + 1
        , customerType
        }

getStats :: State -> Stats
getStats State {..} =
  let waitingSeconds = (\cust -> seconds - arrivedAt cust) <$> queue
      totalWaitingSeconds' = totalWaitingSeconds + sum waitingSeconds
      maxWaitingSeconds' =
        max maxWaitingSeconds (V.foldl' max 0.0 waitingSeconds)
      customers = customersServed + V.length queue
   in Stats
        { statAvgWaitingTime = totalWaitingSeconds' / fromIntegral customers
        , statMaxWaitingTime = maxWaitingSeconds'
        , statAvgQueueLength = fromIntegral totalQueueLength / seconds
        , statMaxQueueLength = maxQueueLength
        }

getArrivalTime :: V.Vector Customer -> Double
getArrivalTime = arrivedAt . V.head
