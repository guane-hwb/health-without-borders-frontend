"""NFC compression audit: the benchmark (see README.md in this directory).

Reads the synthetic corpus written by corpus_test.dart (the app's own builders),
reproduces the app's CBOR byte for byte, builds the alternative encodings and
measures them on the test split. DEFLATE is measured by deflate_jobs_test.dart
with the app's dart:io zlib; zstd, brotli, LZMA2 and the context-model reference
are measured here. Invented data only.

    python3 -I bench.py prep   OUT lib/src/core/nfc/nfc_guardian_alias.dart
    python3 -I bench.py prep2  OUT …   # pessimistic estimate (free text apart)
    python3 -I bench.py prep3  OUT …   # cost of each guardian-copy field group
    python3 -I bench.py report OUT …   # results.md

Requires Python 3.14 (compression.zstd) and the brotli command-line tool.
"""

import collections
import datetime as dt
import json
import lzma
import math
import os
import random
import re
import statistics
import struct
import subprocess
import sys
import zlib
from compression import zstd

PHASE, OUT, ALIAS_SRC = sys.argv[1], sys.argv[2], sys.argv[3]
recs = [json.loads(line) for line in open(f"{OUT}/corpus.jsonl", encoding="utf-8")]
meta = json.load(open(f"{OUT}/meta.json"))
train = [r for r in recs if r["split"] == "train"]
test = [r for r in recs if r["split"] == "test"]
AES_V0 = 28  # 12-byte nonce + 16-byte tag, no header (key version 0, every chip today)

# ── The app's key aliases, read from its source ─────────────────────────────
_src = open(ALIAS_SRC, encoding="utf-8").read()
_body = _src.split("const Map<String, String> _fullToShort")[1].split("};")[0]
F2S = dict(re.findall(r"'([^']+)':\s*'([^']+)'", _body))


def rename(node, table):
    if isinstance(node, dict):
        return {table.get(k, k): rename(v, table) for k, v in node.items()}
    if isinstance(node, list):
        return [rename(x, table) for x in node]
    return node


def alias(full, table=F2S):
    a = rename(full, table)
    a["$v"] = 2
    return a


# ── CBOR: definite lengths, shortest integers, shortest lossless floats ─────
class Tag:
    def __init__(self, tag, value):
        self.tag, self.value = tag, value


def _head(major, n):
    if n < 24:
        return bytes([major << 5 | n])
    if n < 0x100:
        return bytes([major << 5 | 24, n])
    if n < 0x10000:
        return bytes([major << 5 | 25]) + struct.pack(">H", n)
    if n < 0x100000000:
        return bytes([major << 5 | 26]) + struct.pack(">I", n)
    return bytes([major << 5 | 27]) + struct.pack(">Q", n)


def _float(x):
    try:
        h = struct.pack(">e", x)
        if struct.unpack(">e", h)[0] == x:
            return b"\xf9" + h
    except (OverflowError, struct.error):
        pass
    f = struct.pack(">f", x)
    if struct.unpack(">f", f)[0] == x:
        return b"\xfa" + f
    return b"\xfb" + struct.pack(">d", x)


def cbor(o):
    if o is None:
        return b"\xf6"
    if o is True:
        return b"\xf5"
    if o is False:
        return b"\xf4"
    if isinstance(o, int):
        return _head(0, o) if o >= 0 else _head(1, -1 - o)
    if isinstance(o, float):
        return _float(o)
    if isinstance(o, str):
        b = o.encode("utf-8")
        return _head(3, len(b)) + b
    if isinstance(o, (bytes, bytearray)):
        return _head(2, len(o)) + bytes(o)
    if isinstance(o, list):
        return _head(4, len(o)) + b"".join(cbor(x) for x in o)
    if isinstance(o, dict):
        return _head(5, len(o)) + b"".join(cbor(k) + cbor(v) for k, v in o.items())
    if isinstance(o, Tag):
        return _head(6, o.tag) + cbor(o.value)
    raise TypeError(type(o))


_bad = 0
for _r in recs:
    _bad += cbor(_r["triage"]).hex() != _r["dart_cbor_triage"]
    for _g in _r["g"]:
        _bad += cbor(alias(_g["full"])).hex() != _g["dart_cbor_alias"]
assert _bad == 0, f"CBOR differs from the app's in {_bad} payloads"

# ── Alternative encodings ────────────────────────────────────────────────────
UUID_RE = re.compile(r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$")
UID_RE = re.compile(r"^([0-9A-F]{2}:){6}[0-9A-F]{2}$")
DATE_RE = re.compile(r"^(\d{4})-(\d{2})-(\d{2})$")
DT_RE = re.compile(r"^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):00([+-])(\d{2}):(\d{2})$")
DIGITS_RE = re.compile(r"^[1-9]\d{0,17}$")
EPOCH_D = dt.date(1900, 1, 1)
EPOCH_M = dt.datetime(2020, 1, 1)

# Paths whose values come from closed lists in the app or from stable public
# catalogs (ICD-10, DIVIPOLA, PAI, REPS, EPS). Person names and free text are
# left out on purpose.
CATALOG = {
    "triage": {"sex", "bt", "docT", "alg[]/c", "alg[]/a", "alg[]/r"},
    "guardian": {
        "patientInfo/identification/documentType", "patientInfo/biologicalSex",
        "patientInfo/nationalityCode", "patientInfo/nationalityName",
        "patientInfo/ethnicity", "patientInfo/bloodType",
        "patientInfo/address/city", "patientInfo/address/cityCode",
        "patientInfo/address/state", "patientInfo/address/country",
        "patientInfo/address/zone",
        "guardianInfo/relationship", "guardianInfo/documentType",
        "guardianInfo/consent/policyVersion",
        "guardian2Info/relationship", "guardian2Info/documentType",
        "guardian2Info/consent/policyVersion",
        "backgroundHistory/chronicConditions[]/chronicDescription",
        "backgroundHistory/chronicConditions[]/chronicCie10Code",
        "backgroundHistory/familyHistory[]/conditionDescription",
        "backgroundHistory/familyHistory[]/relationship",
        "backgroundHistory/medications[]/medicationName",
        "backgroundHistory/medications[]/status",
        "backgroundHistory/medications[]/dosage",
        "allergies[]/category", "allergies[]/allergen", "allergies[]/reaction",
        "medicalHistory[]/type", "medicalHistory[]/careModality",
        "medicalHistory[]/serviceGroup", "medicalHistory[]/careEnvironment",
        "medicalHistory[]/diagnosisType", "medicalHistory[]/dischargeDisposition",
        "medicalHistory[]/provider/repsCode", "medicalHistory[]/provider/name",
        "medicalHistory[]/practitioner/documentType",
        "medicalHistory[]/payer/name",
        "medicalHistory[]/diagnosis[]/icd10Code",
        "medicalHistory[]/diagnosis[]/description",
        "medicalHistory[]/diagnosis[]/source",
        "medicalHistory[]/prescriptions[]/medicationName",
        "medicalHistory[]/prescriptions[]/dosage",
        "medicalHistory[]/prescriptions[]/frequency",
        "medicalHistory[]/prescriptions[]/duration",
        "medicalHistory[]/prescriptions[]/route",
        "medicalHistory[]/prescriptions[]/status",
        "medicalHistory[]/prescriptions[]/intent",
        "vaccinationRecord[]/vaccineName", "vaccinationRecord[]/vaccineCode",
        "vaccinationRecord[]/administratedAt", "vaccinationRecord[]/status",
    },
}


def walk(node, path=""):
    if isinstance(node, dict):
        for k, v in node.items():
            p = f"{path}/{k}" if path else k
            yield p, k, v
            yield from walk(v, p)
    elif isinstance(node, list):
        for x in node:
            yield from walk(x, f"{path}[]")


def key_table(maps):
    c = collections.Counter(k for m in maps for _, k, _ in walk(m))
    return {k: i for i, (k, _) in enumerate(c.most_common())}


def codebooks(maps, kind):
    vals = collections.defaultdict(collections.Counter)
    for m in maps:
        for p, _, v in walk(m):
            if p in CATALOG[kind] and isinstance(v, str):
                vals[p][v] += 1
    return {p: {v: i for i, (v, _) in enumerate(c.most_common())} for p, c in vals.items()}


def scalar(v, books, path):
    """A lossless typed value for a schema-aware reader: the CBOR type (bytes,
    integer, array, tag) says which conversion to undo."""
    if not isinstance(v, str):
        return v
    if books is not None and path in books and v in books[path]:
        return Tag(6, books[path][v])  # catalog code
    if UUID_RE.match(v):
        return bytes.fromhex(v.replace("-", ""))
    if UID_RE.match(v):
        return bytes.fromhex(v.replace(":", ""))
    m = DATE_RE.match(v)
    if m:
        try:
            return Tag(100, (dt.date(*map(int, m.groups())) - EPOCH_D).days)
        except ValueError:
            return v
    m = DT_RE.match(v)
    if m:
        y, mo, d, h, mi, sg, oh, om = m.groups()
        t = dt.datetime(int(y), int(mo), int(d), int(h), int(mi))
        off = (int(oh) * 60 + int(om)) * (1 if sg == "+" else -1)
        return [int((t - EPOCH_M).total_seconds() // 60), off // 15]
    if DIGITS_RE.match(v):
        return int(v)
    return v


def typed(node, keys, books, path=""):
    if isinstance(node, dict):
        out = {}
        for k, v in node.items():
            p = f"{path}/{k}" if path else k
            out[keys.get(k, k)] = typed(v, keys, books, p)
        return out
    if isinstance(node, list):
        return [typed(x, keys, books, f"{path}[]") for x in node]
    return scalar(node, books, path)


def intkeys(node, keys):
    if isinstance(node, dict):
        return {keys.get(k, k): intkeys(v, keys) for k, v in node.items()}
    if isinstance(node, list):
        return [intkeys(x, keys) for x in node]
    return node


def complete_alias(maps):
    """The app's alias table plus a short key for every key it lacks."""
    used = set(F2S.values()) | set(F2S.keys())
    table = dict(F2S)
    for m in maps:
        for _, k, _ in walk(m):
            if k not in table and len(k) > 3:
                base = re.sub(r"[^a-z]", "", k.lower())[:3] or "k"
                cand, i = base, 2
                while cand in used:
                    cand, i = f"{base[:2]}{i}", i + 1
                table[k] = cand
                used.add(cand)
    return table


def g_slice(full, n, m):
    x = json.loads(json.dumps(full))
    x["medicalHistory"] = x.get("medicalHistory", [])[:n]
    x["vaccinationRecord"] = x.get("vaccinationRecord", [])[:m]
    return x


_tri_strip = [r["triage_strip"] for r in train]
_g3_full = [r["g"][3]["full"] for r in train]
_g3_strip = [r["g"][3]["strip"] for r in train]
KT_TRI, KT_G = key_table(_tri_strip), key_table(_g3_strip)
CB_TRI, CB_G = codebooks(_tri_strip, "triage"), codebooks(_g3_strip, "guardian")
FULL_ALIAS = complete_alias(_g3_full)
UNALIASED = sorted({k for m in _g3_full for _, k, _ in walk(m)} - set(F2S))

VAR_TRI = {
    "T0 current": lambda r: cbor(r["triage"]),
    "T1 no redundant keys": lambda r: cbor(r["triage_strip"]),
    "T2 + integer keys": lambda r: cbor(intkeys(r["triage_strip"], KT_TRI)),
    "T3 + typed values": lambda r: cbor(typed(r["triage_strip"], KT_TRI, None)),
    "T4 + catalog codes": lambda r: cbor(typed(r["triage_strip"], KT_TRI, CB_TRI)),
}
VAR_G = {
    "G0 current": lambda r, n, m: cbor(alias(g_slice(r["g"][3]["full"], n, m))),
    "G0b complete alias": lambda r, n, m: cbor(alias(g_slice(r["g"][3]["full"], n, m), FULL_ALIAS)),
    "G1 no redundant keys": lambda r, n, m: cbor(alias(g_slice(r["g"][3]["strip"], n, m))),
    "G2 + integer keys": lambda r, n, m: cbor(intkeys(g_slice(r["g"][3]["strip"], n, m), KT_G)),
    "G3 + typed values": lambda r, n, m: cbor(typed(g_slice(r["g"][3]["strip"], n, m), KT_G, None)),
    "G4 + catalog codes": lambda r, n, m: cbor(typed(g_slice(r["g"][3]["strip"], n, m), KT_G, CB_G)),
}
KS = [0, 1, 3]
CAPACITY_VARIANTS = ["G0 current", "G1 no redundant keys", "G3 + typed values", "G4 + catalog codes"]

for _r in recs[:50]:  # the (n, m) slice of k = 3 is what the app builds for k
    for _k in range(4):
        assert cbor(alias(g_slice(_r["g"][3]["full"], _k, _k))) == cbor(alias(_r["g"][_k]["full"]))


def concat_dict(samples, limit, seed=7):
    """Prefix dictionary: training samples concatenated in a shuffled order."""
    s = list(samples)
    random.Random(seed).shuffle(s)
    out = b""
    for x in s:
        if len(out) + len(x) > limit:
            break
        out += x
    return out


def zstd_c(b, zd=None, level=19):
    opts = {zstd.CompressionParameter.compression_level: level,
            zstd.CompressionParameter.checksum_flag: 0,
            zstd.CompressionParameter.dict_id_flag: 0}
    best = None
    for csf in (0, 1):
        opts[zstd.CompressionParameter.content_size_flag] = csf
        out = zstd.compress(b, options=opts, zstd_dict=zd)
        best = out if best is None or len(out) < len(best) else best
    return len(best) - 4  # without the magic number (libzstd's magicless format)


def brotli_c(b, dict_path=None):
    cmd = ["brotli", "-q", "11", "-c"] + (["-D", dict_path] if dict_path else []) + ["-"]
    return len(subprocess.run(cmd, input=b, capture_output=True, check=True).stdout)


def lzma_c(b):
    return len(lzma.compress(b, format=lzma.FORMAT_RAW,
                             filters=[{"id": lzma.FILTER_LZMA2, "preset": 9 | lzma.PRESET_EXTREME}]))


class ContextModel:
    """Byte context model, orders 0 to 3, Witten-Bell interpolation, trained on
    the training split and adapted within each payload as a reader could do.
    Returns the ideal length of an arithmetic coder with that model: a reference
    for what a trained statistical model reaches, not a theoretical bound."""

    ORDER = 3

    def __init__(self, samples):
        self.cnt = [collections.defaultdict(dict) for _ in range(self.ORDER + 1)]
        self.tot = [collections.Counter() for _ in range(self.ORDER + 1)]
        for b in samples:
            for i, x in enumerate(b):
                for o in range(min(i, self.ORDER) + 1):
                    ctx = b[i - o:i]
                    c = self.cnt[o][ctx]
                    c[x] = c.get(x, 0) + 1
                    self.tot[o][ctx] += 1
        self.dis = [{ctx: len(c) for ctx, c in t.items()} for t in self.cnt]

    def bytes_for(self, b):
        dcnt = [{} for _ in range(self.ORDER + 1)]
        dtot = [collections.Counter() for _ in range(self.ORDER + 1)]
        dnew = [collections.Counter() for _ in range(self.ORDER + 1)]
        bits = 0.0
        for i, x in enumerate(b):
            p = 1 / 256
            for o in range(min(i, self.ORDER) + 1):
                ctx = b[i - o:i]
                n = self.tot[o].get(ctx, 0) + dtot[o].get(ctx, 0)
                if n == 0:
                    continue
                t = self.dis[o].get(ctx, 0) + dnew[o].get(ctx, 0)
                sc = self.cnt[o].get(ctx)
                c = (sc.get(x, 0) if sc else 0) + dcnt[o].get((ctx, x), 0)
                p = (c + t * p) / (n + t)
            bits += -math.log2(p)
            for o in range(min(i, self.ORDER) + 1):
                ctx = b[i - o:i]
                prev = dcnt[o].get((ctx, x), 0)
                dcnt[o][(ctx, x)] = prev + 1
                dtot[o][ctx] += 1
                sc = self.cnt[o].get(ctx)
                if prev == 0 and not (sc and x in sc):
                    dnew[o][ctx] += 1
        return math.ceil(bits / 8) + 1


def slug(name):
    return name.split()[0]


# Free clinical text and person names come from closed lists in the synthetic
# corpus, which the dictionary knows; real ones do not. The pessimistic
# estimate empties them, measures the rest with the dictionary and adds what
# they cost today without one.
FREE_G = {"historyOfCurrentIllness", "generalPhysicalExamination", "systemsExamination",
          "treatmentPlanObservations", "personalHistory", "notes", "firstName", "secondName",
          "firstLastName", "secondLastName", "email", "street", "administratedBy"}
FREE_G_PATHS = ("guardianInfo/name", "guardian2Info/name", "medicalHistory[]/practitioner/name")
FREE_T = {"fn", "ln"}


def empty_free(node, kind, path=""):
    if isinstance(node, dict):
        out = {}
        for k, v in node.items():
            p = f"{path}/{k}" if path else k
            free = (k in FREE_T) if kind == "triage" else (k in FREE_G or p in FREE_G_PATHS)
            out[k] = "" if (free and isinstance(v, str)) else empty_free(v, kind, p)
        return out
    if isinstance(node, list):
        return [empty_free(x, kind, f"{path}[]") for x in node]
    return node


VAR_TRI_FREE = {
    "T0 current": lambda r: cbor(empty_free(r["triage"], "triage")),
    "T3 + typed values": lambda r: cbor(typed(empty_free(r["triage_strip"], "triage"), KT_TRI, None)),
    "T4 + catalog codes": lambda r: cbor(typed(empty_free(r["triage_strip"], "triage"), KT_TRI, CB_TRI)),
}
VAR_G_FREE = {
    "G0 current": lambda r, n, m: cbor(alias(empty_free(g_slice(r["g"][3]["full"], n, m), "guardian"))),
    "G3 + typed values": lambda r, n, m: cbor(typed(empty_free(g_slice(r["g"][3]["strip"], n, m), "guardian"), KT_G, None)),
    "G4 + catalog codes": lambda r, n, m: cbor(typed(empty_free(g_slice(r["g"][3]["strip"], n, m), "guardian"), KT_G, CB_G)),
}

# Field groups of the guardian copy (ADR 006) and the options built from them.
GROUPS = {
    "item identifiers (visits)": {"medicalHistory[]/encounterIdentifier"},
    "item identifiers (vaccines)": {"vaccinationRecord[]/vaccinationId"},
    "consent details": {"guardianInfo/consent", "guardian2Info/consent"},
    "guardian documents": {"guardianInfo/documentType", "guardianInfo/documentNumber",
                           "guardian2Info/documentType", "guardian2Info/documentNumber"},
    "practitioner": {"medicalHistory[]/practitioner"},
    "provider": {"medicalHistory[]/provider"},
    "payer": {"medicalHistory[]/payer"},
    "prescriptions": {"medicalHistory[]/prescriptions"},
    "vaccinator and site": {"vaccinationRecord[]/administratedBy", "vaccinationRecord[]/administratedAt"},
    "address detail": {"patientInfo/address/street", "patientInfo/address/cityCode", "patientInfo/address/zone"},
    "diagnoses (reference)": {"medicalHistory[]/diagnosis"},
    "clinical text (reference)": {"medicalHistory[]/clinicalEvaluation"},
}
OPTIONS = {
    "B identifiers": ["item identifiers (visits)", "item identifiers (vaccines)"],
    "C history fields": ["item identifiers (visits)", "item identifiers (vaccines)", "practitioner",
                         "provider", "payer", "vaccinator and site"],
    "D declarative": ["consent details", "guardian documents", "address detail"],
    "E C + D": ["item identifiers (visits)", "item identifiers (vaccines)", "practitioner", "provider",
                "payer", "vaccinator and site", "consent details", "guardian documents", "address detail"],
}


def drop_paths(node, paths, path=""):
    if isinstance(node, dict):
        out = {}
        for k, v in node.items():
            p = f"{path}/{k}" if path else k
            if p in paths:
                continue
            out[k] = drop_paths(v, paths, p)
        return out
    if isinstance(node, list):
        return [drop_paths(x, paths, f"{path}[]") for x in node]
    return node


def without(r, n, m, paths):
    return cbor(alias(drop_paths(g_slice(r["g"][3]["full"], n, m), paths)))


class Jobs:
    """Payloads for deflate_jobs_test.dart: one binary file plus an index."""

    def __init__(self):
        self.jobs, self.payloads = [], bytearray()

    def add(self, jid, b, dict_name):
        self.jobs.append({"id": jid, "off": len(self.payloads), "len": len(b), "dict": dict_name})
        self.payloads.extend(b)

    def save(self, name):
        open(f"{OUT}/{name}.bin", "wb").write(self.payloads)
        json.dump(self.jobs, open(f"{OUT}/{name}.json", "w"))
        print(f"{name}: {len(self.jobs)} DEFLATE jobs for Dart ({len(self.payloads) / 1e6:.1f} MB)")


# ═══════════════════════════════════════════════════════════════════════════
if PHASE == "prep":
    jobs = Jobs()
    py = {}  # "variant|k|compressor" -> sizes over the test split
    for kind, variants, ks in (("triage", VAR_TRI, [None]), ("guardian", VAR_G, KS)):
        for name, f in variants.items():
            tr = [f(r) for r in train] if kind == "triage" else [f(r, 3, 3) for r in train]
            d32 = concat_dict(tr, 32768)
            open(f"{OUT}/dict_{kind}_{slug(name)}_32k.bin", "wb").write(d32)
            open(f"{OUT}/dict_{kind}_{slug(name)}_8k.bin", "wb").write(d32[-8192:])
            zds = {}
            for size in (8192, 32768):
                try:
                    zds[size] = zstd.train_dict(tr, size)
                except Exception as e:  # too few samples for that size
                    print(f"  zstd train_dict {size} B failed for {kind} {name}: {e}")
            cm = ContextModel(tr)
            for k in ks:
                te = [f(r) for r in test] if kind == "triage" else [f(r, k, k) for r in test]
                tag = f"{name}|{k}"
                for i, b in enumerate(te):
                    for dn in (None, "8k", "32k"):
                        jobs.add(f"bench|{tag}|{i}|{dn}", b,
                                 None if dn is None else f"dict_{kind}_{slug(name)}_{dn}.bin")
                py[f"{tag}|none"] = [len(b) for b in te]
                py[f"{tag}|zstd-19"] = [zstd_c(b) for b in te]
                for size, label in ((8192, "8 KB"), (32768, "32 KB")):
                    if size in zds:
                        py[f"{tag}|zstd-19 + dict. {label}"] = [zstd_c(b, zds[size]) for b in te]
                py[f"{tag}|brotli-11"] = [brotli_c(b) for b in te]
                py[f"{tag}|brotli-11 + dict. 32 KB"] = [
                    brotli_c(b, f"{OUT}/dict_{kind}_{slug(name)}_32k.bin") for b in te]
                py[f"{tag}|raw LZMA2"] = [lzma_c(b) for b in te]
                py[f"{tag}|context model (ref.)"] = [cm.bytes_for(b) for b in te]
                print(f"  {kind} {name} k={k}: done", flush=True)

    for name in CAPACITY_VARIANTS:  # every (n, m) slice of every test record
        f = VAR_G[name]
        for i, r in enumerate(test):
            for n in range(min(3, r["nCons"]) + 1):
                for m in range(min(3, r["nVac"]) + 1):
                    b = f(r, n, m)
                    jobs.add(f"cap|{name}|{i}|{n}|{m}|None", b, None)
                    jobs.add(f"cap|{name}|{i}|{n}|{m}|32k", b, f"dict_guardian_{slug(name)}_32k.bin")

    jobs.save("jobs")
    json.dump(py, open(f"{OUT}/py_sizes.json", "w"))
    json.dump({"unaliased": UNALIASED}, open(f"{OUT}/keys.json", "w"))

elif PHASE == "prep2":
    jobs = Jobs()
    for name, f in VAR_TRI_FREE.items():
        for i, r in enumerate(test):
            b = f(r)
            for dn in (None, "8k", "32k"):
                jobs.add(f"free|{name}|None|{i}|{dn}", b,
                         None if dn is None else f"dict_triage_{slug(name)}_{dn}.bin")
    for name, f in VAR_G_FREE.items():
        for i, r in enumerate(test):
            for n in range(min(3, r["nCons"]) + 1):
                for m in range(min(3, r["nVac"]) + 1):
                    b = f(r, n, m)
                    for dn in (None, "32k"):
                        jobs.add(f"freecap|{name}|{i}|{n}|{m}|{dn}", b,
                                 None if dn is None else f"dict_guardian_{slug(name)}_32k.bin")
    jobs.save("jobs2")

elif PHASE == "prep3":
    jobs = Jobs()
    for i, r in enumerate(test):
        for k in (1, 3):
            n, m = min(k, min(3, r["nCons"])), min(k, min(3, r["nVac"]))
            for g, paths in GROUPS.items():
                jobs.add(f"group|{g}|{k}|{i}", without(r, n, m, paths), None)
        for o, gs in OPTIONS.items():
            paths = set().union(*(GROUPS[g] for g in gs))
            for n in range(min(3, r["nCons"]) + 1):
                for m in range(min(3, r["nVac"]) + 1):
                    jobs.add(f"option|{o}|{i}|{n}|{m}", without(r, n, m, paths), None)
    jobs.save("jobs3")

# ═══════════════════════════════════════════════════════════════════════════
elif PHASE == "report":
    J1 = json.load(open(f"{OUT}/jobs_sizes.json"))
    J2 = json.load(open(f"{OUT}/jobs2_sizes.json"))
    J3 = json.load(open(f"{OUT}/jobs3_sizes.json")) if os.path.exists(f"{OUT}/jobs3_sizes.json") else None
    for j in (J1, J2, J3):
        assert j is None or j["round_trip_failures"] == 0
    D, D2 = J1["sizes"], J2["sizes"]
    A = J1["zlib_dictionary_sizes"]
    PY = json.load(open(f"{OUT}/py_sizes.json"))
    keys = json.load(open(f"{OUT}/keys.json"))
    L = []

    def med_p90(xs):
        xs = sorted(xs)
        return statistics.median(xs), xs[int(0.9 * (len(xs) - 1))], xs[-1]

    def cell(xs):
        if not xs:
            return "—"
        m, p, _ = med_p90(xs)
        return f"{m:.0f} ({p:.0f})"

    def table(rows, head):
        out = ["| " + " | ".join(head) + " |", "|" + "---|" * len(head)]
        out += ["| " + " | ".join(str(c) for c in row) + " |" for row in rows]
        return "\n".join(out)

    DN = {"DEFLATE-9 (current)": "None", "DEFLATE-9 + dict. 8 KB": "8k", "DEFLATE-9 + dict. 32 KB": "32k"}

    def sizes(tag, comp):
        if comp in DN:
            return [D[f"bench|{tag}|{i}|{DN[comp]}"] for i in range(len(test))]
        return PY.get(f"{tag}|{comp}")

    COMPS = ["none", "DEFLATE-9 (current)", "DEFLATE-9 + dict. 8 KB", "DEFLATE-9 + dict. 32 KB",
             "zstd-19", "zstd-19 + dict. 8 KB", "zstd-19 + dict. 32 KB", "brotli-11",
             "brotli-11 + dict. 32 KB", "raw LZMA2", "context model (ref.)"]
    diff_a = [A[k] - D[k] for k in A]

    L.append("# NFC compression audit — benchmark results\n")
    L.append(f"Synthetic corpus: {len(train)} training and {len(test)} test records. Figures are over the "
             "test split, in bytes of compressed payload (no encryption, no NDEF record): median (90th "
             "percentile). DEFLATE is measured with the app's dart:io zlib. With `raw: true` a dictionary "
             f"has no effect in dart:io (checked: {J1['raw_ignores_dictionary']}); the dictionary columns "
             "use raw DEFLATE primed with the dictionary and flushed with Z_SYNC_FLUSH "
             f"({J1['round_trips']} round trips, {J1['round_trip_failures']} failures). The zlib format "
             f"with a dictionary, minus its rebuildable header and DICTID, adds {statistics.mean(diff_a):.1f} B "
             f"(min {min(diff_a)}, max {max(diff_a)}). zstd, brotli, LZMA2 and the context model are measured "
             "in Python; zstd without its 4-byte magic number.\n")
    L.append(f"Guardian-copy keys the app's alias table does not shorten ({len(keys['unaliased'])}): "
             + ", ".join(f"`{k}`" for k in keys["unaliased"]) + ".\n")

    def block(title, variants, k):
        L.append(f"## {title}\n")
        rows = [[name] + [cell(sizes(f"{name}|{k}", c)) for c in COMPS] for name in variants]
        L.append(table(rows, ["encoding"] + COMPS))
        L.append("")

    block("Triage (patient device)", VAR_TRI, None)
    for k in KS:
        block(f"Guardian copy with {k} consultation(s) and {k} vaccine(s)", VAR_G, k)

    # ── Whole NDEF message: optimistic and pessimistic ─────────────────────
    def tri(name, i, dn):
        return D[f"bench|{name}|None|{i}|{dn}"]

    def tri_pes(name, i, dn):
        if dn == "None":
            return tri(name, i, dn)
        return D2[f"free|{name}|None|{i}|{dn}"] + tri(name, i, "None") - D2[f"free|{name}|None|{i}|None"]

    def gk(r, k):
        return min(k, min(3, r["nCons"])), min(k, min(3, r["nVac"]))

    def gcap(name, i, n, m, dn):
        return D[f"cap|{name}|{i}|{n}|{m}|{dn}"]

    def gcap_pes(name, i, n, m, dn):
        if dn == "None":
            return gcap(name, i, n, m, dn)
        return (D2[f"freecap|{name}|{i}|{n}|{m}|{dn}"] + gcap(name, i, n, m, "None")
                - D2[f"freecap|{name}|{i}|{n}|{m}|None"])

    def ndef(comp, ext, kind):
        body = comp + AES_V0
        if ext:
            return body + (meta["ndef_overhead_ext8_sr"] if body <= 255 else meta["ndef_overhead_ext8_lr"])
        sr, lr = ((meta["ndef_overhead_triage_sr"], meta["ndef_overhead_triage_lr"]) if kind == "triage"
                  else (meta["ndef_overhead_guardian_sr"], meta["ndef_overhead_guardian_lr"]))
        return body + (sr if body <= 255 else lr)

    L.append("## Whole NDEF message (payload + 28 B of AES-GCM + NDEF record)\n")
    L.append("*Pessimistic*: free clinical text and person names get nothing from the dictionary "
             "(measured apart and charged what they cost today without one). The short record type "
             "measured here is an 8-character external type; ADR 005 implements a 17-character one "
             "(9 B more per chip).\n")
    rows = []

    def row(label, xs):
        m, p, mx = med_p90(xs)
        rows.append([label, f"{m:.0f}", f"{p:.0f}", f"{mx:.0f}",
                     f"{100 * sum(x <= 492 for x in xs) / len(xs):.0f} %",
                     f"{100 * sum(x <= 872 for x in xs) / len(xs):.0f} %"])

    row("triage: current", [ndef(tri("T0 current", i, "None"), False, "triage") for i in range(len(test))])
    for name, dn, ext, lab in [("T0 current", "8k", False, "T0 + 8 KB dictionary"),
                               ("T3 + typed values", "8k", True, "T3 + 8 KB dictionary + external type"),
                               ("T4 + catalog codes", "8k", True, "T4 + 8 KB dictionary + external type")]:
        row(f"triage: {lab} (optimistic)", [ndef(tri(name, i, dn), ext, "triage") for i in range(len(test))])
        row(f"triage: {lab} (pessimistic)", [ndef(tri_pes(name, i, dn), ext, "triage") for i in range(len(test))])
    for k in KS:
        row(f"guardian {k}+{k}: current",
            [ndef(gcap("G0 current", i, *gk(r, k), "None"), False, "g") for i, r in enumerate(test)])
        for name, ext, lab in [("G0 current", False, "G0 + 32 KB dictionary"),
                               ("G3 + typed values", True, "G3 + 32 KB dictionary + external type"),
                               ("G4 + catalog codes", True, "G4 + 32 KB dictionary + external type")]:
            row(f"guardian {k}+{k}: {lab} (optimistic)",
                [ndef(gcap(name, i, *gk(r, k), "32k"), ext, "g") for i, r in enumerate(test)])
            row(f"guardian {k}+{k}: {lab} (pessimistic)",
                [ndef(gcap_pes(name, i, *gk(r, k), "32k"), ext, "g") for i, r in enumerate(test)])
    L.append(table(rows, ["case", "median (B)", "p90 (B)", "max (B)", "fits NTAG215 (492 B)",
                          "fits NTAG216 (872 B)"]))
    L.append("")

    # ── Capacity ───────────────────────────────────────────────────────────
    def best_fit(size, r, cap):
        best = None
        for n in range(min(3, r["nCons"]) + 1):
            for m in range(min(3, r["nVac"]) + 1):
                if size(n, m) <= cap:
                    if best is None or (n + m, n) > (best[0] + best[1], best[0]):
                        best = (n, m)
        return best

    L.append("## Capacity of the guardian copy (up to 3 consultations + 3 vaccines)\n")
    L.append("Full search over (consultations, vaccines): the most entries win; ties go to more "
             "consultations. The first row per chip is what the app's own algorithm keeps today.\n")
    rows = []
    for chip, cap, key in (("NTAG215", 492, "215"), ("NTAG216", 872, "216")):
        fits = [r["fit_now"][key] for r in test]
        rows.append(["app algorithm and encoding today", chip,
                     f"{statistics.mean(f[0] for f in fits):.2f}",
                     f"{statistics.mean(f[1] for f in fits):.2f}",
                     f"{100 * sum(f[0] >= 1 for f in fits) / len(fits):.0f} %",
                     f"{100 * sum(not f[3] for f in fits) / len(fits):.0f} %"])
        cases = [("current encoding, full search", "G0 current", "None", False, gcap),
                 ("no redundant keys", "G1 no redundant keys", "None", False, gcap),
                 ("+ integer keys and typed values", "G3 + typed values", "None", False, gcap)]
        for lab, name, ext in [("G0 + 32 KB dictionary", "G0 current", False),
                               ("G3 + 32 KB dictionary + external type", "G3 + typed values", True),
                               ("G4 + 32 KB dictionary + external type", "G4 + catalog codes", True)]:
            cases.append((f"{lab} (optimistic)", name, "32k", ext, gcap))
            cases.append((f"{lab} (pessimistic)", name, "32k", ext, gcap_pes))
        for lab, name, dn, ext, fn in cases:
            fs = [best_fit(lambda n, m, i=i: ndef(fn(name, i, n, m, dn), ext, "g"), r, cap)
                  for i, r in enumerate(test)]
            ok = [f for f in fs if f]
            rows.append([lab, chip,
                         f"{statistics.mean(f[0] for f in ok):.2f}" if ok else "—",
                         f"{statistics.mean(f[1] for f in ok):.2f}" if ok else "—",
                         f"{100 * sum(bool(f) and f[0] >= 1 for f in fs) / len(fs):.0f} %",
                         f"{100 * sum(f is None for f in fs) / len(fs):.0f} %"])
    L.append(table(rows, ["variant", "chip", "consultations kept (mean)", "vaccines kept (mean)",
                          "records with ≥ 1 consultation", "base does not fit"]))
    L.append(f"\nMost this history allows: {statistics.mean(min(3, r['nCons']) for r in test):.2f} "
             f"consultations and {statistics.mean(min(3, r['nVac']) for r in test):.2f} vaccines on "
             f"average; {100 * sum(r['nCons'] >= 1 for r in test) / len(test):.0f} % of the records have "
             "at least one consultation.\n")

    L.append("## Marginal cost of a consultation + vaccine pair (whole NDEF message, median)\n")
    rows = []
    sel = [(i, r) for i, r in enumerate(test) if r["nCons"] >= 3 and r["nVac"] >= 3]
    for lab, name, dn, ext, fn in [("current", "G0 current", "None", False, gcap),
                                   ("G3 + dictionary + external type (optimistic)", "G3 + typed values", "32k", True, gcap),
                                   ("G3 + dictionary + external type (pessimistic)", "G3 + typed values", "32k", True, gcap_pes)]:
        base = [ndef(fn(name, i, 0, 0, dn), ext, "g") for i, r in sel]
        one = [ndef(fn(name, i, 1, 1, dn), ext, "g") for i, r in sel]
        three = [ndef(fn(name, i, 3, 3, dn), ext, "g") for i, r in sel]
        rows.append([lab, f"{statistics.median(base):.0f}",
                     f"{statistics.median([u - b for u, b in zip(one, base)]):.0f}",
                     f"{statistics.median([(t - u) / 2 for t, u in zip(three, one)]):.0f}", len(sel)])
    L.append(table(rows, ["variant", "base, no history (B)", "first pair (B)", "each further pair (B)",
                          "records"]))
    L.append("")

    # ── Where the bytes go (Python zlib: shares, not the app's figures) ─────
    def defl(b):
        c = zlib.compressobj(9, zlib.DEFLATED, -15, 8)
        return len(c.compress(b) + c.flush())

    def sz(full):
        return defl(cbor(alias(full)))

    def blank(node, pred):
        if isinstance(node, dict):
            return {k: ("" if pred(k, v) else blank(v, pred)) for k, v in node.items()}
        if isinstance(node, list):
            return [blank(x, pred) for x in node]
        return node

    TEXT = {"historyOfCurrentIllness", "generalPhysicalExamination", "systemsExamination",
            "treatmentPlanObservations", "personalHistory"}
    sections = ["patientId", "device_uid", "patientInfo", "guardianInfo", "guardian2Info",
                "backgroundHistory", "allergies", "medicalHistory", "vaccinationRecord", "baseVersion"]
    kinds = {
        "free clinical text": lambda k, v: k in TEXT and isinstance(v, str),
        "UUIDs": lambda k, v: isinstance(v, str) and bool(UUID_RE.match(v)),
        "dates and date-times": lambda k, v: isinstance(v, str) and bool(
            DATE_RE.match(v) or re.match(r"^\d{4}-\d{2}-\d{2}T", v)),
        "key names (current → integer)": None,
    }
    saved = collections.defaultdict(list)
    totals = []
    for r in test:
        full = r["g"][3]["full"]
        t = sz(full)
        totals.append(t)
        for sec in sections:
            saved[sec].append(t - sz({k: v for k, v in full.items() if k != sec}) if sec in full else 0)
        for g, pred in kinds.items():
            saved[g].append(t - (defl(cbor(intkeys(full, KT_G))) if pred is None else sz(blank(full, pred))))
    L.append("## Where the bytes go (current guardian copy, up to 3 + 3, after DEFLATE)\n")
    L.append("Measured with Python's zlib, which differs from the app's by a few bytes; read the shares. "
             f"Mean compressed size: {statistics.mean(totals):.0f} B.\n")
    L.append(table([[s, f"{statistics.mean(saved[s]):.0f}", f"{100 * statistics.mean(saved[s]) / statistics.mean(totals):.0f} %"]
                    for s in sections + list(kinds)],
                   ["part", "bytes saved by removing it (mean)", "share of the total"]))
    L.append("\nRemoving a part saves less than its own size when it shares text with the rest; the "
             "shares do not add up to 100 %.\n")

    # ── Redundant keys ─────────────────────────────────────────────────────
    qg = collections.Counter(re.sub(r"^/", "", p) for r in test for p in r["g"][3]["removed"])
    qt = collections.Counter(re.sub(r"^/", "", p) for r in test for p in r["triage_removed"])
    L.append("## Keys written that do not change what the app reconstructs (test split, up to 3 + 3)\n")
    L.append(table([[f"`{p}`", c] for p, c in qg.most_common(30)], ["path", "occurrences in 200 records"]))
    L.append("\nTriage:\n")
    L.append(table([[f"`{p}`", c] for p, c in qt.most_common(10)], ["path", "occurrences in 200 records"]))
    L.append("")

    # ── Field groups of the guardian copy (ADR 006) ─────────────────────────
    if J3 is not None:
        D3 = J3["sizes"]
        L.append("## Cost of each guardian-copy field group (ADR 006)\n")
        L.append("Bytes saved by leaving the group out, after the app's DEFLATE, median over the records "
                 "that have it.\n")
        rows = []
        for g in GROUPS:
            cells = [g]
            for k in (1, 3):
                deltas = []
                for i, r in enumerate(test):
                    n, m = min(k, min(3, r["nCons"])), min(k, min(3, r["nVac"]))
                    d = gcap("G0 current", i, n, m, "None") - D3[f"group|{g}|{k}|{i}"]
                    if d != 0:
                        deltas.append(d)
                cells.append(f"{statistics.median(deltas):.0f} B" if deltas else "—")
                if k == 3:
                    cells.append(f"{len(deltas)} of {len(test)}")
            rows.append(cells)
        L.append(table(rows, ["group", "with 1 + 1", "with 3 + 3", "records with the group (3 + 3)"]))
        L.append("")

        def give_back_fit(size, r, budget):
            """The app's trim plus the give-back step of PR #182."""
            n, m = min(3, r["nCons"]), min(3, r["nVac"])
            max_n, max_m = n, m
            s = size(n, m)
            cut_c = cut_v = False
            while s > budget and (n > 0 or m > 0):
                cut_c = n >= m and n > 0
                cut_v = not cut_c
                if cut_c:
                    n -= 1
                else:
                    m -= 1
                s = size(n, m)
            if s <= budget:
                while cut_c and m < max_m and size(n, m + 1) <= budget:
                    m += 1
                while cut_v and n < max_n and size(n + 1, m) <= budget:
                    n += 1
            return n, m, s <= budget

        L.append("## Capacity of each ADR 006 option (current encoding, app budgets, fit of PR #182)\n")
        rows = []
        for o in ["A as today"] + list(OPTIONS):
            for chip, budget in (("NTAG215", 458), ("NTAG216", 838)):
                res = []
                for i, r in enumerate(test):
                    if o == "A as today":
                        size = lambda n, m, i=i: gcap("G0 current", i, n, m, "None") + AES_V0
                    else:
                        size = lambda n, m, i=i, o=o: D3[f"option|{o}|{i}|{n}|{m}"] + AES_V0
                    res.append(give_back_fit(size, r, budget))
                rows.append([o, chip, f"{statistics.mean(x[0] for x in res):.2f}",
                             f"{statistics.mean(x[1] for x in res):.2f}",
                             f"{100 * sum(x[0] >= 1 and x[2] for x in res) / len(res):.0f} %",
                             f"{100 * sum(not x[2] for x in res) / len(res):.0f} %"])
        L.append(table(rows, ["option", "chip", "consultations kept (mean)", "vaccines kept (mean)",
                              "records with ≥ 1 consultation", "base does not fit"]))
        L.append("")

    open(f"{OUT}/results.md", "w", encoding="utf-8").write("\n".join(L) + "\n")
    print("\n".join(L))
