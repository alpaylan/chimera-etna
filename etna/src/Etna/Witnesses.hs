module Etna.Witnesses where

import Etna.Properties
import Etna.Result

------------------------------------------------------------------------------
-- Variant 1: wheel210_table_non_monotone_73b5020a_1
------------------------------------------------------------------------------

-- toWheel210 11 = 1, toWheel210 12 = 0 in the buggy table.
witness_to_wheel210_monotonic_case_i11 :: PropertyResult
witness_to_wheel210_monotonic_case_i11 =
  property_to_wheel210_monotonic (Wheel210Index 11)

-- toWheel210 13 = 2, toWheel210 14 = 0 in the buggy table.
witness_to_wheel210_monotonic_case_i13 :: PropertyResult
witness_to_wheel210_monotonic_case_i13 =
  property_to_wheel210_monotonic (Wheel210Index 13)

-- toWheel210 209 = 47 (period boundary); next is i=210 -> q=1, r=0
-- which gives 48 -> still monotone after the fix; on the buggy table
-- toWheel210 209 = 47 and toWheel210 210 = 48 (still monotone here).
-- Picking a buggy hot-spot well inside the period: toWheel210 17 = 3,
-- toWheel210 18 = 0.
witness_to_wheel210_monotonic_case_i17 :: PropertyResult
witness_to_wheel210_monotonic_case_i17 =
  property_to_wheel210_monotonic (Wheel210Index 17)

------------------------------------------------------------------------------
-- Variant 2: from_infinite_off_by_one_ecacbd14_1
------------------------------------------------------------------------------

-- fromInfinite (cycle (0 :| [])) errors at construction in the buggy
-- version; in the fixed version index 0 is 0.
witness_from_infinite_index_equals_head_case_n0_k0 :: PropertyResult
witness_from_infinite_index_equals_head_case_n0_k0 =
  property_from_infinite_index_equals_head (FromInfArgs 0 0)

-- Same construction bug; this just exercises a non-zero index.
witness_from_infinite_index_equals_head_case_n42_k7 :: PropertyResult
witness_from_infinite_index_equals_head_case_n42_k7 =
  property_from_infinite_index_equals_head (FromInfArgs 42 7)

-- Larger value + larger index, still bounded.
witness_from_infinite_index_equals_head_case_n1000_k1023 :: PropertyResult
witness_from_infinite_index_equals_head_case_n1000_k1023 =
  property_from_infinite_index_equals_head (FromInfArgs 1000 1023)
