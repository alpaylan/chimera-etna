# chimera — Injected Bugs

Lazy infinite compact streams with cache-friendly O(1) indexing and applications for memoization (Bodigrim/chimera). Bug fixes mined from upstream history; modern HEAD is the base, each patch reverse-applies a fix to install the original bug.

Total mutations: 2

## Bug Index

| # | Variant | Name | Location | Injection | Fix Commit |
|---|---------|------|----------|-----------|------------|
| 1 | `from_infinite_off_by_one_ecacbd14_1` | `from_infinite_unbounded_recursion` | `src/Data/Chimera/Internal.hs:583` | `patch` | `ecacbd147ed772a5e726fd12e97468968ba9220d` |
| 2 | `wheel210_table_non_monotone_73b5020a_1` | `wheel210_lookup_table_not_monotone` | `src/Data/Chimera/WheelMapping.hs:192` | `patch` | `73b5020ba01fce4589efcde32144ef2c91e9686d` |

## Property Mapping

| Variant | Property | Witness(es) |
|---------|----------|-------------|
| `from_infinite_off_by_one_ecacbd14_1` | `FromInfiniteIndexEqualsHead` | `witness_from_infinite_index_equals_head_case_n0_k0`, `witness_from_infinite_index_equals_head_case_n42_k7`, `witness_from_infinite_index_equals_head_case_n1000_k1023` |
| `wheel210_table_non_monotone_73b5020a_1` | `ToWheel210Monotonic` | `witness_to_wheel210_monotonic_case_i11`, `witness_to_wheel210_monotonic_case_i13`, `witness_to_wheel210_monotonic_case_i17` |

## Framework Coverage

| Property | quickcheck | hedgehog | falsify | smallcheck |
|----------|---------:|-------:|------:|---------:|
| `FromInfiniteIndexEqualsHead` | ✓ | ✓ | ✓ | ✓ |
| `ToWheel210Monotonic` | ✓ | ✓ | ✓ | ✓ |

## Bug Details

### 1. from_infinite_unbounded_recursion

- **Variant**: `from_infinite_off_by_one_ecacbd14_1`
- **Location**: `src/Data/Chimera/Internal.hs:583` (inside `fromInfinite`)
- **Property**: `FromInfiniteIndexEqualsHead`
- **Witness(es)**:
  - `witness_from_infinite_index_equals_head_case_n0_k0` — fromInfinite (cycle (0 :| [])) errors at construction in the buggy variant
  - `witness_from_infinite_index_equals_head_case_n42_k7` — non-zero value + non-zero index; both error at fromInfinite construction
  - `witness_from_infinite_index_equals_head_case_n1000_k1023` — larger index, still bounded; same construction-time error in the buggy variant
- **Source**: internal — #40 Fix fromInfinite error
  > `fromInfinite` builds an outer Array of `bits + 1 = 65` chunks via `GHC.Exts.fromListN (bits + 1)`. The pre-fix `go` recursed without a termination guard, so the chunk-list it produced was unbounded. `fromListN` is strict in spine length, so it raised `'fromListN' applied to a list with more elements than specified` and `fromInfinite` errored before returning. The fix adds `if k == bits then [] else ...` so exactly `bits + 1` chunks reach `fromListN`.
- **Fix commit**: `ecacbd147ed772a5e726fd12e97468968ba9220d` — #40 Fix fromInfinite error
- **Invariant violated**: `Ch.index (Ch.fromInfinite (Inf.cycle (n :| [])) :: UChimera Word) k == n` for every Word `n` and every Word index `k`. Equivalently: `fromInfinite` must return a Chimera (not error) for any Infinite input, and indexing the result returns the corresponding stream element.
- **How the mutation triggers**: Reverse-applying the patch removes the `if k == bits then [] else ...` guard. Calling `Ch.fromInfinite stream` then evaluates `GHC.Exts.fromListN 65` on an unbounded chunk list, raising the runtime error 'fromListN' applied to a list with more elements than specified'. The runner's `try`/witness driver catches this and reports the witness as failed.

### 2. wheel210_lookup_table_not_monotone

- **Variant**: `wheel210_table_non_monotone_73b5020a_1`
- **Location**: `src/Data/Chimera/WheelMapping.hs:192` (inside `toWheel210Table`)
- **Property**: `ToWheel210Monotonic`
- **Witness(es)**:
  - `witness_to_wheel210_monotonic_case_i11` — buggy: toWheel210 11 = 1, toWheel210 12 = 0
  - `witness_to_wheel210_monotonic_case_i13` — buggy: toWheel210 13 = 2, toWheel210 14 = 0
  - `witness_to_wheel210_monotonic_case_i17` — buggy: toWheel210 17 = 3, toWheel210 18 = 0
- **Source**: internal — Fix monotonicity of toWheel*
  > The 48-position lookup table feeding `toWheel210` was originally a sparse array — every rough-number position carried its index, every other slot was zero. Because `toWheel210 i = q * 48 + table[i mod 210]`, that made the function non-monotone (e.g. table[11]=1 but table[12]=0, so toWheel210 12 < toWheel210 11). The fix replaces the table with the running maximum so the function becomes monotonically non-decreasing while still satisfying `toWheel210 . fromWheel210 == id` at the rough-number positions.
- **Fix commit**: `73b5020ba01fce4589efcde32144ef2c91e9686d` — Fix monotonicity of toWheel*
- **Invariant violated**: `toWheel210 (i + 1) >= toWheel210 i` for every Word `i` in the wheel-210 period [0, 209]. The function is documented as a left inverse of `fromWheel210` and is consumed by callers that assume monotonicity (e.g. wheel-sieve cache lookups).
- **How the mutation triggers**: Reverse-applying the patch swaps the modern monotone Addr# literal for the sparse pre-fix literal. Calling `toWheel210 12` then returns 0 while `toWheel210 11` returns 1, falsifying the monotonicity property.
