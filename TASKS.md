# chimera — ETNA Tasks

Total tasks: 8

## Task Index

| Task | Variant | Framework | Property | Witness |
|------|---------|-----------|----------|---------|
| 001 | `from_infinite_off_by_one_ecacbd14_1` | quickcheck | `FromInfiniteIndexEqualsHead` | `witness_from_infinite_index_equals_head_case_n0_k0` |
| 002 | `from_infinite_off_by_one_ecacbd14_1` | hedgehog | `FromInfiniteIndexEqualsHead` | `witness_from_infinite_index_equals_head_case_n0_k0` |
| 003 | `from_infinite_off_by_one_ecacbd14_1` | falsify | `FromInfiniteIndexEqualsHead` | `witness_from_infinite_index_equals_head_case_n0_k0` |
| 004 | `from_infinite_off_by_one_ecacbd14_1` | smallcheck | `FromInfiniteIndexEqualsHead` | `witness_from_infinite_index_equals_head_case_n0_k0` |
| 005 | `wheel210_table_non_monotone_73b5020a_1` | quickcheck | `ToWheel210Monotonic` | `witness_to_wheel210_monotonic_case_i11` |
| 006 | `wheel210_table_non_monotone_73b5020a_1` | hedgehog | `ToWheel210Monotonic` | `witness_to_wheel210_monotonic_case_i11` |
| 007 | `wheel210_table_non_monotone_73b5020a_1` | falsify | `ToWheel210Monotonic` | `witness_to_wheel210_monotonic_case_i11` |
| 008 | `wheel210_table_non_monotone_73b5020a_1` | smallcheck | `ToWheel210Monotonic` | `witness_to_wheel210_monotonic_case_i11` |

## Witness Catalog

- `witness_from_infinite_index_equals_head_case_n0_k0` — fromInfinite (cycle (0 :| [])) errors at construction in the buggy variant
- `witness_from_infinite_index_equals_head_case_n42_k7` — non-zero value + non-zero index; both error at fromInfinite construction
- `witness_from_infinite_index_equals_head_case_n1000_k1023` — larger index, still bounded; same construction-time error in the buggy variant
- `witness_to_wheel210_monotonic_case_i11` — buggy: toWheel210 11 = 1, toWheel210 12 = 0
- `witness_to_wheel210_monotonic_case_i13` — buggy: toWheel210 13 = 2, toWheel210 14 = 0
- `witness_to_wheel210_monotonic_case_i17` — buggy: toWheel210 17 = 3, toWheel210 18 = 0
