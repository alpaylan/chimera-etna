{-# LANGUAGE ScopedTypeVariables #-}

module Etna.Properties where

import qualified Data.List.NonEmpty  as NE
import qualified Data.List.Infinite  as Inf

import qualified Data.Chimera                 as Ch
import qualified Data.Chimera.WheelMapping    as WM

import           Etna.Result

------------------------------------------------------------------------------
-- Variant 1: wheel210_table_non_monotone_73b5020a_1
-- "Fix monotonicity of toWheel*"
------------------------------------------------------------------------------

-- | A position @i@ in the wheel-210 domain at which we check the
-- monotonicity invariant @toWheel210 i <= toWheel210 (i + 1)@.
--
-- Bug: pre-fix, @toWheel210Table@ was a sparse table of mostly-zero
-- entries with the @47@ "real" rough-number positions punched into
-- otherwise-zero rows. The function @toWheel210 i = q * 48 + table[i mod 210]@
-- therefore wasn't monotone — e.g. @toWheel210 11 = 1@ but
-- @toWheel210 12 = 0@. The fix replaces the table with the running
-- maximum, making the function monotonically non-decreasing.
newtype Wheel210Index = Wheel210Index { unWheel210Index :: Word }
  deriving (Show, Eq)

property_to_wheel210_monotonic :: Wheel210Index -> PropertyResult
property_to_wheel210_monotonic (Wheel210Index i)
  -- Avoid wraparound at maxBound :: Word.
  | i >= maxBound - 1 = Discard
  | otherwise =
      let a = WM.toWheel210 i
          b = WM.toWheel210 (i + 1)
      in if a <= b
           then Pass
           else Fail $
             "toWheel210 " ++ show i ++ " = " ++ show a ++
             ", toWheel210 " ++ show (i + 1) ++ " = " ++ show b ++
             " (expected monotonically non-decreasing)"

------------------------------------------------------------------------------
-- Variant 2: from_infinite_off_by_one_ecacbd14_1
-- "#40 Fix fromInfinite error"
------------------------------------------------------------------------------

-- | Inputs for the fromInfinite property: a value @n@ to fill an
-- infinite stream with and an index @k@ at which to read from the
-- resulting Chimera.
--
-- Bug: pre-fix, @fromInfinite@'s internal @go@ recursed without a
-- termination condition (no @if k == bits then [] else ...@). It
-- therefore fed an unbounded list to @GHC.Exts.fromListN (bits + 1)@,
-- which is strict in spine length and raises a runtime error
-- ("fromListN: list length differs from given length"). The fix adds
-- the termination guard so exactly @bits + 1@ chunks reach
-- @fromListN@.
data FromInfArgs = FromInfArgs
  { fiValue :: !Word
  , fiIndex :: !Word
  } deriving (Show, Eq)

property_from_infinite_index_equals_head :: FromInfArgs -> PropertyResult
property_from_infinite_index_equals_head (FromInfArgs n k) =
  let stream = Inf.cycle (n NE.:| [])
      ch    = Ch.fromInfinite stream :: Ch.UChimera Word
      -- Cap the index so we don't drift to the largest inner vector.
      -- Bug triggers at construction time, well before indexing.
      ix    = k `mod` 65536
      v     = Ch.index ch ix
  in if v == n
       then Pass
       else Fail $
         "index " ++ show ix ++ " of fromInfinite (cycle (" ++ show n ++
         " :| [])) = " ++ show v ++ ", expected " ++ show n
