module Etna.Gens.Hedgehog where

import           Hedgehog       (Gen)
import qualified Hedgehog.Gen   as Gen
import qualified Hedgehog.Range as Range

import Etna.Properties
  ( Wheel210Index(..)
  , FromInfArgs(..)
  )

gen_to_wheel210_monotonic :: Gen Wheel210Index
gen_to_wheel210_monotonic = do
  i <- Gen.word (Range.linear 0 209)
  pure (Wheel210Index i)

gen_from_infinite_index_equals_head :: Gen FromInfArgs
gen_from_infinite_index_equals_head = do
  n <- Gen.word (Range.linear 0 1000)
  k <- Gen.word (Range.linear 0 1023)
  pure (FromInfArgs n k)
