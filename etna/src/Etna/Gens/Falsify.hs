module Etna.Gens.Falsify where

import qualified Test.Falsify.Generator as F
import qualified Test.Falsify.Range     as FR

import Etna.Properties
  ( Wheel210Index(..)
  , FromInfArgs(..)
  )

gen_to_wheel210_monotonic :: F.Gen Wheel210Index
gen_to_wheel210_monotonic = do
  i <- F.inRange (FR.between (0 :: Word, 209))
  pure (Wheel210Index i)

gen_from_infinite_index_equals_head :: F.Gen FromInfArgs
gen_from_infinite_index_equals_head = do
  n <- F.inRange (FR.between (0 :: Word, 1000))
  k <- F.inRange (FR.between (0 :: Word, 1023))
  pure (FromInfArgs n k)
