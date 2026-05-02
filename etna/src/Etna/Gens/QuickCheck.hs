module Etna.Gens.QuickCheck where

import qualified Test.QuickCheck as QC

import Etna.Properties
  ( Wheel210Index(..)
  , FromInfArgs(..)
  )

-- Hot range covers the period [0, 209] of the wheel-210 table; the
-- bug is visible at many indices in this range (e.g. 11, 13, 17, 19,
-- ...). Larger indices wrap modulo 210 so cover the same period.
gen_to_wheel210_monotonic :: QC.Gen Wheel210Index
gen_to_wheel210_monotonic = do
  i <- QC.choose (0, 209)
  pure (Wheel210Index (fromIntegral (i :: Int)))

-- The bug fires at fromInfinite construction time, regardless of
-- value or index. Keep both small so QuickCheck doesn't waste time
-- on (already-cached) deep indexing.
gen_from_infinite_index_equals_head :: QC.Gen FromInfArgs
gen_from_infinite_index_equals_head = do
  n <- QC.choose (0, 1000)
  k <- QC.choose (0, 1023)
  pure (FromInfArgs (fromIntegral (n :: Int)) (fromIntegral (k :: Int)))
