# chimera (ETNA workload)

ETNA workload built from the Bodigrim/chimera library. Drives QuickCheck,
Hedgehog, Falsify, and SmallCheck against pure-Haskell properties mined
from upstream bug-fix history.

Upstream: <https://github.com/Bodigrim/chimera>
Base commit (this fork): `09f847aa1ce4f1671c14a39bba2da5d11b9bf5b3`
GHC: pinned to `9.6.6` via `cabal.project` (`with-compiler:`).

## Variants

Two variants survived the discover/atomize filter:

| Variant | Source commit | Property |
| --- | --- | --- |
| `wheel210_table_non_monotone_73b5020a_1` | `73b5020` "Fix monotonicity of toWheel*" | `ToWheel210Monotonic` |
| `from_infinite_off_by_one_ecacbd14_1` | `ecacbd1` "#40 Fix fromInfinite error" | `FromInfiniteIndexEqualsHead` |

`14581e6` ("#39 Fix fromListWithDef divergence") was inspected and
dropped: the bug only manifests on truly infinite Haskell list inputs
(`cycle`, `repeat`-style). QuickCheck/Hedgehog/Falsify/SmallCheck only
generate finite lists, and divergence (vs. `error`) is not catchable
from pure properties even when reachable, so the variant is unverifiable
under the workload's four-backend contract.

All other "Fix" commits in upstream history are CI/build/haddock/typo
patches that don't manifest as runtime invariant failures (full
classification in `progress.jsonl`).

## Patches, not branches

Every variant lives as a single file in `patches/`. The base tree is the
fixed state; `git apply -R patches/<variant>.patch` installs the bug,
and `git apply patches/<variant>.patch` restores the fix. The wheel-210
patch was hand-synthesized against modern HEAD because the upstream file
moved (`Data/BitStream/WheelMapping.hs` → `src/Data/Chimera/WheelMapping.hs`)
and the table representation changed (`U.Vector Word8` → GHC `Addr#`
string literal) since the original 2017 fix; the fromInfinite patch is
the unmodified `git format-patch -1 ecacbd1` output.

## Layout

```
chimera/
  src/Data/Chimera/...                  # upstream library, untouched on base
  cabal.project                          # ours; pins GHC 9.6.6 + adds etna/
  etna.toml                              # manifest (single source of truth)
  patches/<variant>.patch                # bug-injection patches
  etna/
    etna-runner.cabal
    src/Etna/Result.hs
    src/Etna/Properties.hs               # property_<snake> :: Args -> PropertyResult
    src/Etna/Witnesses.hs                # witness_<snake>_case_<tag> :: PropertyResult
    src/Etna/Gens/{QuickCheck,Hedgehog,Falsify,SmallCheck}.hs
    app/Main.hs                          # CLI dispatcher
    test/Witnesses.hs                    # `cabal test etna-witnesses`
  BUGS.md, TASKS.md                      # generated; do not hand-edit
  progress.jsonl                         # per-run scratch (gitignored)
```

## Running

```sh
cd /path/to/chimera
cabal build etna-runner

# Confirm base witnesses pass:
cabal test etna-witnesses

# Run a property under a backend:
cd etna
cabal run etna-runner -- quickcheck ToWheel210Monotonic
cabal run etna-runner -- smallcheck FromInfiniteIndexEqualsHead
cabal run etna-runner -- etna All       # witness replay across all properties
```

The runner emits one JSON line on stdout per invocation and always
exits 0 (except on argv-parse error), per the etna driver contract.

## Validation matrix (base + each variant)

```
                  ToWheel210Monotonic   FromInfiniteIndexEqualsHead
base
  etna             passed                 passed
  quickcheck       passed                 passed
  hedgehog         passed                 passed
  falsify          passed                 passed
  smallcheck       passed                 passed

variant: wheel210_table_non_monotone_73b5020a_1
  etna             FAILED (witness i11)   passed   <- orthogonal
  quickcheck       FAILED                 passed
  hedgehog         FAILED                 passed
  falsify          FAILED                 passed
  smallcheck       FAILED (depth 12)      passed

variant: from_infinite_off_by_one_ecacbd14_1
  etna             passed   <- orthogonal FAILED (witness n0_k0)
  quickcheck       passed                 FAILED
  hedgehog         passed                 FAILED
  falsify          passed                 FAILED (try-wrapped error)
  smallcheck       passed                 FAILED
```

20-of-20 cells match the expected detection pattern; SmallCheck depth is
pinned to 12 in `etna/app/Main.hs` so the smallest-bug index for the
wheel-210 table (i = 11) is reachable.
