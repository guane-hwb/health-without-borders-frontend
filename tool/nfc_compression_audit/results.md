# NFC compression audit — benchmark results

Synthetic corpus: 400 training and 200 test records. Figures are over the test split, in bytes of compressed payload (no encryption, no NDEF record): median (90th percentile). DEFLATE is measured with the app's dart:io zlib. With `raw: true` a dictionary has no effect in dart:io (checked: True); the dictionary columns use raw DEFLATE primed with the dictionary and flushed with Z_SYNC_FLUSH (18061 round trips, 0 failures). The zlib format with a dictionary, minus its rebuildable header and DICTID, adds 4.0 B (min 4, max 4). zstd, brotli, LZMA2 and the context model are measured in Python; zstd without its 4-byte magic number.

Guardian-copy keys the app's alias table does not shorten (9): `baseVersion`, `duration`, `frequency`, `height`, `intent`, `isBloodTypeCertified`, `prescriptions`, `route`, `weight`.

## Triage (patient device)

| encoding | none | DEFLATE-9 (current) | DEFLATE-9 + dict. 8 KB | DEFLATE-9 + dict. 32 KB | zstd-19 | zstd-19 + dict. 8 KB | zstd-19 + dict. 32 KB | brotli-11 | brotli-11 + dict. 32 KB | raw LZMA2 | context model (ref.) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| T0 current | 122 (167) | 120 (154) | 55 (68) | 48 (61) | 124 (155) | 58 (68) | 56 (68) | 121 (156) | 63 (76) | 124 (160) | 28 (36) |
| T1 no redundant keys | 120 (166) | 118 (153) | 55 (68) | 48 (60) | 122 (153) | 58 (68) | 57 (66) | 120 (155) | 64 (76) | 122 (160) | 27 (36) |
| T2 + integer keys | 92 (133) | 94 (133) | 52 (67) | 46 (59) | 98 (134) | 55 (67) | 55 (66) | 96 (133) | 61 (74) | 97 (136) | 27 (35) |
| T3 + typed values | 69 (106) | 72 (107) | 38 (46) | 35 (43) | 74 (110) | 45 (54) | 45 (53) | 73 (110) | 60 (72) | 73 (110) | 30 (39) |
| T4 + catalog codes | 66 (85) | 70 (88) | 37 (45) | 35 (43) | 71 (90) | 44 (53) | 44 (53) | 70 (89) | 60 (72) | 70 (89) | 30 (38) |

## Guardian copy with 0 consultation(s) and 0 vaccine(s)

| encoding | none | DEFLATE-9 (current) | DEFLATE-9 + dict. 8 KB | DEFLATE-9 + dict. 32 KB | zstd-19 | zstd-19 + dict. 8 KB | zstd-19 + dict. 32 KB | brotli-11 | brotli-11 + dict. 32 KB | raw LZMA2 | context model (ref.) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| G0 current | 552 (655) | 434 (488) | 280 (328) | 214 (261) | 445 (501) | 242 (287) | 174 (211) | 422 (473) | 219 (266) | 447 (503) | 126 (155) |
| G0b complete alias | 522 (627) | 411 (466) | 277 (322) | 214 (260) | 424 (480) | 236 (288) | 169 (211) | 403 (456) | 218 (265) | 425 (482) | 125 (155) |
| G1 no redundant keys | 502 (600) | 397 (452) | 271 (320) | 214 (260) | 406 (461) | 243 (291) | 169 (206) | 382 (435) | 218 (266) | 405 (463) | 128 (157) |
| G2 + integer keys | 420 (512) | 360 (413) | 258 (304) | 210 (256) | 372 (424) | 221 (265) | 166 (204) | 352 (409) | 216 (260) | 372 (427) | 119 (148) |
| G3 + typed values | 331 (398) | 323 (378) | 225 (270) | 163 (208) | 326 (379) | 204 (246) | 146 (178) | 318 (369) | 201 (241) | 320 (370) | 124 (155) |
| G4 + catalog codes | 280 (340) | 276 (327) | 198 (244) | 154 (190) | 276 (331) | 180 (222) | 142 (176) | 274 (323) | 183 (228) | 274 (320) | 120 (150) |

## Guardian copy with 1 consultation(s) and 1 vaccine(s)

| encoding | none | DEFLATE-9 (current) | DEFLATE-9 + dict. 8 KB | DEFLATE-9 + dict. 32 KB | zstd-19 | zstd-19 + dict. 8 KB | zstd-19 + dict. 32 KB | brotli-11 | brotli-11 + dict. 32 KB | raw LZMA2 | context model (ref.) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| G0 current | 1556 (1769) | 1050 (1175) | 524 (612) | 392 (453) | 1065 (1192) | 433 (495) | 324 (378) | 995 (1111) | 388 (447) | 1080 (1201) | 286 (351) |
| G0b complete alias | 1504 (1730) | 1018 (1137) | 520 (607) | 390 (451) | 1032 (1154) | 418 (493) | 322 (379) | 966 (1083) | 387 (449) | 1046 (1167) | 282 (348) |
| G1 no redundant keys | 1418 (1625) | 958 (1078) | 508 (576) | 388 (444) | 974 (1098) | 432 (487) | 318 (367) | 908 (1024) | 383 (447) | 983 (1103) | 278 (344) |
| G2 + integer keys | 1260 (1448) | 906 (1024) | 481 (545) | 378 (434) | 924 (1040) | 394 (458) | 312 (362) | 866 (977) | 379 (438) | 922 (1036) | 266 (331) |
| G3 + typed values | 1078 (1263) | 850 (960) | 435 (507) | 310 (369) | 849 (960) | 356 (419) | 278 (321) | 818 (926) | 335 (408) | 843 (950) | 277 (343) |
| G4 + catalog codes | 884 (1034) | 740 (832) | 384 (450) | 293 (345) | 735 (829) | 316 (377) | 270 (322) | 700 (790) | 312 (365) | 724 (817) | 256 (320) |

## Guardian copy with 3 consultation(s) and 3 vaccine(s)

| encoding | none | DEFLATE-9 (current) | DEFLATE-9 + dict. 8 KB | DEFLATE-9 + dict. 32 KB | zstd-19 | zstd-19 + dict. 8 KB | zstd-19 + dict. 32 KB | brotli-11 | brotli-11 + dict. 32 KB | raw LZMA2 | context model (ref.) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| G0 current | 3232 (3799) | 1711 (1947) | 896 (1048) | 662 (779) | 1719 (1946) | 731 (852) | 560 (657) | 1590 (1801) | 646 (758) | 1708 (1932) | 564 (682) |
| G0b complete alias | 3134 (3685) | 1671 (1909) | 886 (1041) | 662 (775) | 1680 (1906) | 718 (846) | 563 (667) | 1558 (1775) | 648 (756) | 1670 (1894) | 558 (677) |
| G1 no redundant keys | 2922 (3448) | 1608 (1844) | 847 (997) | 653 (773) | 1618 (1841) | 710 (832) | 557 (657) | 1498 (1713) | 640 (745) | 1608 (1834) | 550 (664) |
| G2 + integer keys | 2636 (3126) | 1552 (1786) | 804 (956) | 634 (751) | 1558 (1780) | 681 (799) | 547 (646) | 1445 (1662) | 626 (734) | 1536 (1759) | 526 (634) |
| G3 + typed values | 2302 (2749) | 1452 (1681) | 757 (893) | 531 (645) | 1442 (1666) | 604 (705) | 490 (579) | 1373 (1586) | 550 (645) | 1415 (1636) | 544 (655) |
| G4 + catalog codes | 1889 (2287) | 1248 (1432) | 676 (808) | 512 (615) | 1238 (1414) | 545 (644) | 481 (570) | 1158 (1322) | 529 (620) | 1190 (1364) | 488 (609) |

## Whole NDEF message (payload + 28 B of AES-GCM + NDEF record)

*Pessimistic*: free clinical text and person names get nothing from the dictionary (measured apart and charged what they cost today without one). The short record type measured here is an 8-character external type; ADR 005 implements a 17-character one (9 B more per chip).

| case | median (B) | p90 (B) | max (B) | fits NTAG215 (492 B) | fits NTAG216 (872 B) |
|---|---|---|---|---|---|
| triage: current | 178 | 211 | 242 | 100 % | 100 % |
| triage: T0 + 8 KB dictionary (optimistic) | 112 | 125 | 152 | 100 % | 100 % |
| triage: T0 + 8 KB dictionary (pessimistic) | 124 | 140 | 162 | 100 % | 100 % |
| triage: T3 + 8 KB dictionary + external type (optimistic) | 77 | 85 | 99 | 100 % | 100 % |
| triage: T3 + 8 KB dictionary + external type (pessimistic) | 90 | 100 | 106 | 100 % | 100 % |
| triage: T4 + 8 KB dictionary + external type (optimistic) | 76 | 84 | 98 | 100 % | 100 % |
| triage: T4 + 8 KB dictionary + external type (pessimistic) | 90 | 99 | 106 | 100 % | 100 % |
| guardian 0+0: current | 496 | 550 | 652 | 46 % | 100 % |
| guardian 0+0: G0 + 32 KB dictionary (optimistic) | 274 | 323 | 366 | 100 % | 100 % |
| guardian 0+0: G0 + 32 KB dictionary (pessimistic) | 323 | 376 | 426 | 100 % | 100 % |
| guardian 0+0: G3 + 32 KB dictionary + external type (optimistic) | 202 | 247 | 291 | 100 % | 100 % |
| guardian 0+0: G3 + 32 KB dictionary + external type (pessimistic) | 268 | 317 | 382 | 100 % | 100 % |
| guardian 0+0: G4 + 32 KB dictionary + external type (optimistic) | 192 | 229 | 250 | 100 % | 100 % |
| guardian 0+0: G4 + 32 KB dictionary + external type (pessimistic) | 250 | 303 | 389 | 100 % | 100 % |
| guardian 1+1: current | 1112 | 1237 | 1356 | 2 % | 12 % |
| guardian 1+1: G0 + 32 KB dictionary (optimistic) | 454 | 515 | 608 | 78 % | 100 % |
| guardian 1+1: G0 + 32 KB dictionary (pessimistic) | 726 | 811 | 943 | 11 % | 96 % |
| guardian 1+1: G3 + 32 KB dictionary + external type (optimistic) | 352 | 411 | 488 | 100 % | 100 % |
| guardian 1+1: G3 + 32 KB dictionary + external type (pessimistic) | 645 | 724 | 863 | 14 % | 100 % |
| guardian 1+1: G4 + 32 KB dictionary + external type (optimistic) | 335 | 387 | 458 | 100 % | 100 % |
| guardian 1+1: G4 + 32 KB dictionary + external type (pessimistic) | 678 | 768 | 882 | 12 % | 100 % |
| guardian 3+3: current | 1773 | 2009 | 2167 | 2 % | 11 % |
| guardian 3+3: G0 + 32 KB dictionary (optimistic) | 724 | 841 | 912 | 16 % | 96 % |
| guardian 3+3: G0 + 32 KB dictionary (pessimistic) | 1202 | 1382 | 1503 | 10 % | 22 % |
| guardian 3+3: G3 + 32 KB dictionary + external type (optimistic) | 573 | 687 | 732 | 30 % | 100 % |
| guardian 3+3: G3 + 32 KB dictionary + external type (pessimistic) | 1076 | 1244 | 1394 | 11 % | 27 % |
| guardian 3+3: G4 + 32 KB dictionary + external type (optimistic) | 554 | 657 | 699 | 32 % | 100 % |
| guardian 3+3: G4 + 32 KB dictionary + external type (pessimistic) | 1142 | 1314 | 1451 | 11 % | 24 % |

## Capacity of the guardian copy (up to 3 consultations + 3 vaccines)

Full search over (consultations, vaccines): the most entries win; ties go to more consultations. The first row per chip is what the app's own algorithm keeps today.

| variant | chip | consultations kept (mean) | vaccines kept (mean) | records with ≥ 1 consultation | base does not fit |
|---|---|---|---|---|---|
| app algorithm and encoding today | NTAG215 | 0.00 | 0.01 | 0 % | 54 % |
| current encoding, full search | NTAG215 | 0.00 | 0.02 | 0 % | 54 % |
| no redundant keys | NTAG215 | 0.00 | 0.22 | 0 % | 22 % |
| + integer keys and typed values | NTAG215 | 0.00 | 0.93 | 0 % | 2 % |
| G0 + 32 KB dictionary (optimistic) | NTAG215 | 0.52 | 2.17 | 50 % | 0 % |
| G0 + 32 KB dictionary (pessimistic) | NTAG215 | 0.00 | 2.21 | 0 % | 0 % |
| G3 + 32 KB dictionary + external type (optimistic) | NTAG215 | 1.29 | 2.22 | 88 % | 0 % |
| G3 + 32 KB dictionary + external type (pessimistic) | NTAG215 | 0.02 | 2.34 | 2 % | 0 % |
| G4 + 32 KB dictionary + external type (optimistic) | NTAG215 | 1.45 | 2.19 | 89 % | 0 % |
| G4 + 32 KB dictionary + external type (pessimistic) | NTAG215 | 0.01 | 2.34 | 2 % | 0 % |
| app algorithm and encoding today | NTAG216 | 0.01 | 1.03 | 0 % | 0 % |
| current encoding, full search | NTAG216 | 0.01 | 2.35 | 0 % | 0 % |
| no redundant keys | NTAG216 | 0.05 | 2.32 | 5 % | 0 % |
| + integer keys and typed values | NTAG216 | 0.17 | 2.28 | 17 % | 0 % |
| G0 + 32 KB dictionary (optimistic) | NTAG216 | 2.27 | 2.32 | 89 % | 0 % |
| G0 + 32 KB dictionary (pessimistic) | NTAG216 | 0.86 | 2.22 | 82 % | 0 % |
| G3 + 32 KB dictionary + external type (optimistic) | NTAG216 | 2.27 | 2.35 | 89 % | 0 % |
| G3 + 32 KB dictionary + external type (pessimistic) | NTAG216 | 1.15 | 2.23 | 88 % | 0 % |
| G4 + 32 KB dictionary + external type (optimistic) | NTAG216 | 2.27 | 2.35 | 89 % | 0 % |
| G4 + 32 KB dictionary + external type (pessimistic) | NTAG216 | 0.97 | 2.29 | 88 % | 0 % |

Most this history allows: 2.27 consultations and 2.35 vaccines on average; 89 % of the records have at least one consultation.

## Marginal cost of a consultation + vaccine pair (whole NDEF message, median)

| variant | base, no history (B) | first pair (B) | each further pair (B) | records |
|---|---|---|---|---|
| current | 500 | 648 | 390 | 86 |
| G3 + dictionary + external type (optimistic) | 206 | 153 | 138 | 86 |
| G3 + dictionary + external type (pessimistic) | 264 | 391 | 258 | 86 |

## Where the bytes go (current guardian copy, up to 3 + 3, after DEFLATE)

Measured with Python's zlib, which differs from the app's by a few bytes; read the shares. Mean compressed size: 1561 B.

| part | bytes saved by removing it (mean) | share of the total |
|---|---|---|
| patientId | 29 | 2 % |
| device_uid | 17 | 1 % |
| patientInfo | 143 | 9 % |
| guardianInfo | 90 | 6 % |
| guardian2Info | 19 | 1 % |
| backgroundHistory | 34 | 2 % |
| allergies | 11 | 1 % |
| medicalHistory | 945 | 61 % |
| vaccinationRecord | 189 | 12 % |
| baseVersion | 11 | 1 % |
| free clinical text | 493 | 32 % |
| UUIDs | 155 | 10 % |
| dates and date-times | 69 | 4 % |
| key names (current → integer) | 42 | 3 % |

Removing a part saves less than its own size when it shares text with the rest; the shares do not add up to 100 %.

## Keys written that do not change what the app reconstructs (test split, up to 3 + 3)

| path | occurrences in 200 records |
|---|---|
| `vaccinationRecord[]/status` | 470 |
| `medicalHistory[]/type` | 455 |
| `medicalHistory[]/careModality` | 455 |
| `medicalHistory[]/diagnosisType` | 455 |
| `medicalHistory[]/riskFactors` | 455 |
| `medicalHistory[]/practitioner/documentType` | 418 |
| `medicalHistory[]/prescriptions[]/status` | 392 |
| `medicalHistory[]/prescriptions[]/intent` | 392 |
| `medicalHistory[]/serviceGroup` | 311 |
| `medicalHistory[]/careEnvironment` | 307 |
| `patientInfo/address/country` | 200 |
| `guardianInfo/consent/policyVersion` | 200 |
| `vaccinationRecord[]/vaccineCode` | 178 |
| `patientInfo/isBloodTypeCertified` | 167 |
| `medicalHistory[]/prescriptions` | 167 |
| `medicalHistory[]/diagnosis` | 154 |
| `vaccinationRecord[]/dose` | 153 |
| `allergies` | 150 |
| `backgroundHistory/medications` | 135 |
| `backgroundHistory/chronicConditions` | 131 |
| `backgroundHistory/familyHistory` | 126 |
| `guardian2Info/consent/policyVersion` | 61 |
| `patientInfo/identification/documentType` | 33 |
| `backgroundHistory/medications[]/status` | 29 |
| `medicalHistory` | 22 |
| `vaccinationRecord` | 19 |
| `backgroundHistory/familyHistory[]/relationship` | 13 |

Triage:

| path | occurrences in 200 records |
|---|---|
| `bt` | 89 |
| `btC` | 18 |

## Cost of each guardian-copy field group (ADR 006)

Bytes saved by leaving the group out, after the app's DEFLATE, median over the records that have it.

| group | with 1 + 1 | with 3 + 3 | records with the group (3 + 3) |
|---|---|---|---|
| item identifiers (visits) | 29 B | 83 B | 178 of 200 |
| item identifiers (vaccines) | 29 B | 83 B | 181 of 200 |
| consent details | 28 B | 27 B | 200 of 200 |
| guardian documents | 13 B | 12 B | 200 of 200 |
| practitioner | 30 B | 62 B | 177 of 200 |
| provider | 39 B | 49 B | 149 of 200 |
| payer | 14 B | 18 B | 113 of 200 |
| prescriptions | 80 B | 112 B | 178 of 200 |
| vaccinator and site | 29 B | 60 B | 181 of 200 |
| address detail | 13 B | 12 B | 169 of 200 |
| diagnoses (reference) | 45 B | 87 B | 177 of 200 |
| clinical text (reference) | 295 B | 582 B | 178 of 200 |

## Capacity of each ADR 006 option (current encoding, app budgets, fit of PR #182)

| option | chip | consultations kept (mean) | vaccines kept (mean) | records with ≥ 1 consultation | base does not fit |
|---|---|---|---|---|---|
| A as today | NTAG215 | 0.00 | 0.01 | 0 % | 54 % |
| A as today | NTAG216 | 0.01 | 2.35 | 0 % | 0 % |
| B identifiers | NTAG215 | 0.00 | 0.08 | 0 % | 54 % |
| B identifiers | NTAG216 | 0.02 | 2.33 | 2 % | 0 % |
| C history fields | NTAG215 | 0.00 | 0.35 | 0 % | 54 % |
| C history fields | NTAG216 | 0.08 | 2.30 | 8 % | 0 % |
| D declarative | NTAG215 | 0.00 | 0.24 | 0 % | 4 % |
| D declarative | NTAG216 | 0.02 | 2.33 | 2 % | 0 % |
| E C + D | NTAG215 | 0.00 | 1.31 | 0 % | 4 % |
| E C + D | NTAG216 | 0.22 | 2.21 | 22 % | 0 % |

