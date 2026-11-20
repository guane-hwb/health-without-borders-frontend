"""Writes results.md from the outputs of calibration_test.dart and levers_test.dart.

Usage: python3 -I report.py CORPUS.json CALIBRATION.json LEVERS.json OUT.md
"""

import json
import statistics as st
import sys

CORPUS, CAL, LEV, OUT = sys.argv[1:5]
corpus = json.load(open(CORPUS, encoding="utf-8"))
cal = json.load(open(CAL, encoding="utf-8"))
lev = json.load(open(LEV, encoding="utf-8"))

# Figures of the NFC capacity analysis of 21 Oct 2026 (develop e6f31b5, its own
# corpus of 100 synthetic patients), as that analysis reports them.
ORIGINAL = {
    "triage_median": 263,
    "triage_by_allergies": {0: (171, 306), 1: (211, 296), 2: (248, 344), 3: (289, 339)},
    "cases": (362, 412, 472),
    "copy_cbor_median": 4164,
    "copy_compressed_median": 2212,
    "copy_long_max": 3318,
    "ten_long_max": 5715,
    "ntag216_fit": 2,
    "desfire2k_kept": ("1+2", "0+1"),
    "desfire4k_full": 100,
}
NDEF = {"NTAG213": 137, "NTAG215": 492, "NTAG216": 868, "DESFire EV3 2K": 1900, "DESFire EV3 4K": 3800}


def med(xs):
    m = st.median(xs)
    return int(m) if m == int(m) else m


def num(x):
    if isinstance(x, float) and x != int(x):
        return f"{x:,.1f}"
    return f"{int(x):,}"


def pct(new, old):
    return f"{100 * (new / old - 1):+.1f}"


out = []
w = out.append
w("# NFC size options: results\n")
w(f"Synthetic corpus of {len(corpus['pacientes'])} patients (seed {corpus['meta']['seed']}, "
  f"text scale {corpus['meta']['escala_texto']}), written by `gen_corpus.py`; every size is "
  "measured with the app's own code. Sizes are bytes of the NDEF message (payload, AES-GCM seal "
  "with the key header, and the NDEF record) unless a table says otherwise. \"Normal\" and "
  "\"long\" are the two text variants of the corpus; a full copy is 3 consultations and 3 "
  "vaccines.\n")

# ── 1. Calibration ─────────────────────────────────────────────────────────
tri = cal["triaje"]
cop = [c for c in cal["copias"] if not c.get("ablacion")]


def f1(texto, k, m, key="mensaje"):
    return [c["f1"][key] for c in cop if c["texto"] == texto and c["k"] == k and c["m"] == m]


def fit_rows(chip, texto):
    return [a["f1"] for a in cal["ajuste"] if a["chip"] == chip and a["texto"] == texto]


def kept(chip, texto):
    ok = [r for r in fit_rows(chip, texto) if r["fits"]]
    return f"{med([r['n'] for r in ok])}+{med([r['m'] for r in ok])}"


by_alg = []
for a in range(4):
    xs = [t["f1"]["mensaje"] for t in tri if t["alergias"] == a]
    by_alg.append(f"{min(xs)}–{max(xs)}")
orig_alg = " · ".join(f"{lo}–{hi}" for lo, hi in ORIGINAL["triage_by_allergies"].values())
w("## 1. Calibration: format 1 as written today, against the 21 Oct 2026 analysis\n")
w("| Measure | 21 Oct 2026 (its corpus, develop `e6f31b5`) | This corpus (format 1 as written today) |")
w("|---|---|---|")
w(f"| Triage message, median (B) | {ORIGINAL['triage_median']} | {num(med([t['f1']['mensaje'] for t in tri]))} |")
w(f"| Triage with 0, 1, 2 and 3 allergies, min–max (B) | {orig_alg} | {' · '.join(by_alg)} |")
w(f"| Constructed cases with 3, 5 and 8 allergies, 4 chronic conditions and 2 guardians (B) | "
  f"{' · '.join(map(str, ORIGINAL['cases']))} | {' · '.join(str(e['f1']['mensaje']) for e in cal['extremos'])} |")
w(f"| Full copy, CBOR before compression, median (B) | {num(ORIGINAL['copy_cbor_median'])} | {num(med(f1('normal', 3, 3, 'cuerpo')))} |")
w(f"| Full copy, compressed, median (B) | {num(ORIGINAL['copy_compressed_median'])} | {num(med(f1('normal', 3, 3, 'plano')))} |")
w(f"| Full copy with long text, maximum (B) | {num(ORIGINAL['copy_long_max'])} | {num(max(f1('largo', 3, 3)))} |")
w(f"| 10 consultations with long text, maximum (B) | {num(ORIGINAL['ten_long_max'])} | {num(max(f1('largo', 10, 3)))} |")
w(f"| NTAG216: copies that fit at all (of 100) | {ORIGINAL['ntag216_fit']} | {sum(r['fits'] for r in fit_rows('NTAG216', 'normal'))} |")
w(f"| DESFire EV3 2K: median kept, normal · long text (consultations+vaccines) | "
  f"{' · '.join(ORIGINAL['desfire2k_kept'])} | {kept('DESFire EV3 2K', 'normal')} · {kept('DESFire EV3 2K', 'largo')} |")
w(f"| DESFire EV3 4K: full copies, normal and long text (of 100) | {ORIGINAL['desfire4k_full']} | "
  f"{sum(r['fits'] and r['n'] == 3 and r['m'] == 3 for r in fit_rows('DESFire EV3 4K', 'normal'))} and "
  f"{sum(r['fits'] and r['n'] == 3 and r['m'] == 3 for r in fit_rows('DESFire EV3 4K', 'largo'))} |\n")
w("The 21 Oct figures are quoted as that analysis gives them; its copy sizes may be encrypted payloads "
  "(34 B less than the message).\n")

# ── 2. Format 2 baseline and what is left ──────────────────────────────────
seal = lev["seal"]
rec = lev["record"]


def copy_msg(p):
    assert p + seal > 255
    return p + seal + rec["guardian_long"]


def triage_msg(p, short=None, long=None, seal_=None):
    s = seal if seal_ is None else seal_
    short = rec["triage_short"] if short is None else short
    long = rec["triage_long"] if long is None else long
    return p + s + (short if p + s <= 255 else long)


C = lev["copies"]


def sizes(lever, texto):
    return [copy_msg(r[lever]) for r in C if r["texto"] == texto]


base = {t: med(sizes("base", t)) for t in ("normal", "largo")}
campos = ("historyOfCurrentIllness", "generalPhysicalExamination", "systemsExamination", "treatmentPlanObservations")


def text_of(i, variant):
    h = corpus["historiales"][variant][i][:3]
    return [c["clinicalEvaluation"].get(f, "") for c in h for f in campos]


w("## 2. Format 2 as built, and how much of it is free text\n")
w("| Measure | Normal text | Long text |")
w("|---|---|---|")
w(f"| Full copy, median (B) | {num(base['normal'])} | {num(base['largo'])} |")
for chip in ("NTAG216", "DESFire EV3 2K"):
    w(f"| Full copies within the {chip} message, {num(NDEF[chip])} B (of 100) | "
      f"{sum(x <= NDEF[chip] for x in sizes('base', 'normal'))} | {sum(x <= NDEF[chip] for x in sizes('base', 'largo'))} |")
share = {t: 1 - med(sizes("no_text", t)) / base[t] for t in ("normal", "largo")}
w(f"| Share of the copy that is free clinical text (%) | {100 * share['normal']:.1f} | {100 * share['largo']:.1f} |")
bits = {}
for t in ("normal", "largo"):
    bpc, bpw, chars = [], [], []
    for r in C:
        if r["texto"] != t:
            continue
        txt = text_of(r["i"], t)
        n = sum(len(x) for x in txt)
        words = sum(len(x.split()) for x in txt)
        b = r["base"] - r["no_text"]
        bpc.append(8 * b / n)
        bpw.append(8 * b / words)
        chars.append(n)
    bits[t] = (med(chars), med(bpc), med(bpw))
w(f"| Characters of free clinical text per copy, median | {num(bits['normal'][0])} | {num(bits['largo'][0])} |")
w(f"| What format 2 spends on that text (bits per character) | {bits['normal'][1]:.2f} | {bits['largo'][1]:.2f} |")
w(f"| The same, per word (bits) | {bits['normal'][2]:.1f} | {bits['largo'][2]:.1f} |\n")

# ── 3. Levers on the guardian copy ─────────────────────────────────────────
LABELS = {
    "phones": "Phones stored as digits only",
    "app_catalogs": "Text rebuilt from catalogs the app ships (vaccine, country)",
    "icd_catalog": "Text rebuilt from an ICD-10/ICD-11 catalog (diagnosis, coded conditions)",
    "dane_catalog": "Text rebuilt from a DANE catalog (city, department)",
    "derivable": "All derivable text (the three catalogs)",
    "text_latest_only": "Free clinical text only in the most recent consultation",
    "text_cap_160": "Each free clinical text field cut to 160 characters",
    "no_text": "No free clinical text at all (ceiling)",
    "adr006": "ADR 006, option C",
    "adr006+text_latest_only": "ADR 006 (C) + text only in the latest consultation",
    "no_new_catalogs": "Phones + app catalogs + ADR 006 (C) + text only in the latest",
    "all": "Everything above except the text cap and the ceiling",
}
w("## 3. Levers on the guardian copy (format 2 with dictionary 1)\n")
w("| Lever | Normal, median (B) | Change (%) | Within 2K (of 100) | Long, median (B) | Change (%) | Within 2K (of 100) | Long, maximum (B) |")
w("|---|---|---|---|---|---|---|---|")
w(f"| Format 2 as built | {num(base['normal'])} | — | {sum(x <= 1900 for x in sizes('base', 'normal'))} | "
  f"{num(base['largo'])} | — | {sum(x <= 1900 for x in sizes('base', 'largo'))} | {num(max(sizes('base', 'largo')))} |")
for key, label in LABELS.items():
    n, l = sizes(key, "normal"), sizes(key, "largo")
    w(f"| {label} | {num(med(n))} | {pct(med(n), base['normal'])} | {sum(x <= 1900 for x in n)} | "
      f"{num(med(l))} | {pct(med(l), base['largo'])} | {sum(x <= 1900 for x in l)} | {num(max(l))} |")
w("\n\"Within 2K\" counts full copies whose message fits the ~1,900 B of a DESFire EV3 2K.\n")

# ── 4. Record and header ───────────────────────────────────────────────────
w("## 4. What surrounds the payload\n")
w(f"Measured with the app's code: the seal adds {seal} B (AES-GCM nonce and tag, and the 3-byte key header); "
  f"format 2's external record adds {rec['guardian_short']} B to a payload of up to 255 B and "
  f"{rec['guardian_long']} B to a longer one. An NDEF record with no type (TNF unknown) adds 3 and 6 B, "
  "and merging the key header with the format and dictionary bytes would save 3 B more.\n")
w("| Wrapping | Full copy, normal, median (B) | Triage, median (B) | Triage within NTAG213 (of 100) |")
w("|---|---|---|---|")
T = lev["triage"]
WRAPS = (
    # (label, triage short record, triage long record, guardian long record, seal)
    ("Format 2 as built (external type)", rec["triage_short"], rec["triage_long"], rec["guardian_long"], seal),
    ("Record with no type", 3, 6, 6, seal),
    ("Record with no type, merged header", 3, 6, 6, seal - 3),
)
for label, sr, lr, glr, s_ in WRAPS:
    cm = med([r["base"] + s_ + glr for r in C if r["texto"] == "normal"])
    tm = [triage_msg(r["base"], sr, lr, s_) for r in T]
    w(f"| {label} | {num(cm)} | {num(med(tm))} | {sum(x <= 137 for x in tm)} |")
w("")

# ── 5. Triage ──────────────────────────────────────────────────────────────
w("## 5. Levers on the triage (patient device)\n")
w("| Lever | Median (B) | Maximum (B) | Within NTAG213, 137 B (of 100) |")
w("|---|---|---|---|")
for key, label in (("base", "Format 2 as built"), ("phone", "Guardian phone as digits"),
                   ("phone+chronic_codes", "+ chronic conditions as ICD-10 codes")):
    xs = [triage_msg(r[key]) for r in T]
    w(f"| {label} | {num(med(xs))} | {num(max(xs))} | {sum(x <= 137 for x in xs)} |")
xs = [triage_msg(r["phone+chronic_codes"], 3, 6, seal - 3) for r in T]
w(f"| + record with no type and merged header | {num(med(xs))} | {num(max(xs))} | {sum(x <= 137 for x in xs)} |")
w("")

open(OUT, "w", encoding="utf-8").write("\n".join(out))
print(f"wrote {OUT}")
