// tool/nfc_compression_audit/deflate_jobs_test.dart
//
// Step 3 of the NFC compression audit. Compresses every payload bench.py
// prepared with the same dart:io zlib the app uses (level 9, raw DEFLATE), so
// the DEFLATE figures are the app's, not Python's (the two zlibs give
// different sizes for the same bytes).
//
// For a job without a dictionary: ZLibEncoder(level: 9, raw: true).
// For a job with a dictionary, two ways, both checked by a round trip:
//   - primed raw stream: compress the dictionary, flush to a byte boundary
//     (Z_SYNC_FLUSH) and keep only what follows; the reader inflates its own
//     compressed form of the dictionary first. This is the stream zlib writes
//     after deflateSetDictionary, with no extra bytes;
//   - zlib format with the dictionary, minus the 2-byte header and 4-byte
//     DICTID a reader can rebuild; the 4-byte Adler-32 stays.
// It also records whether ZLibEncoder(raw: true, dictionary: d) applies the
// dictionary at all (it does not).
//
// Not part of the test suite. Needs HWB_AUDIT_OUT (the directory bench.py
// wrote to) and HWB_AUDIT_JOBS (jobs, jobs2 or jobs3).

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

final String? kOut = Platform.environment['HWB_AUDIT_OUT'];
final String kJobs = Platform.environment['HWB_AUDIT_JOBS'] ?? 'jobs';

List<int> _drain(RawZLibFilter filter, {required bool end}) {
  final List<int> out = <int>[];
  List<int>? chunk;
  while ((chunk = filter.processed(flush: true, end: end)) != null) {
    out.addAll(chunk!);
  }
  return out;
}

bool _same(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

void main() {
  test(
    'NFC compression audit: DEFLATE with the app zlib',
    () {
      final String out = kOut!;
      final List<dynamic> jobs =
          jsonDecode(File('$out/$kJobs.json').readAsStringSync())
              as List<dynamic>;
      final Uint8List all = File('$out/$kJobs.bin').readAsBytesSync();
      final Map<String, Uint8List> dictionaries = <String, Uint8List>{};
      final Map<String, List<int>> primers = <String, List<int>>{};
      final Map<String, int> sizes = <String, int>{};
      final Map<String, int> zlibSizes = <String, int>{};
      bool? rawIgnoresDictionary;
      int roundTrips = 0;
      int failures = 0;

      for (final dynamic j in jobs) {
        final Map<String, dynamic> job = j as Map<String, dynamic>;
        final String id = job['id'] as String;
        final int off = job['off'] as int;
        final Uint8List data = Uint8List.sublistView(
          all,
          off,
          off + (job['len'] as int),
        );
        final String? name = job['dict'] as String?;

        if (name == null) {
          final List<int> packed = ZLibEncoder(
            level: 9,
            raw: true,
          ).convert(data);
          sizes[id] = packed.length;
          if (roundTrips * 7 < sizes.length) {
            roundTrips++;
            if (!_same(ZLibDecoder(raw: true).convert(packed), data)) {
              failures++;
            }
          }
          continue;
        }

        final Uint8List dict = dictionaries.putIfAbsent(
          name,
          () => File('$out/$name').readAsBytesSync(),
        );
        rawIgnoresDictionary ??= _same(
          ZLibEncoder(level: 9, raw: true).convert(data),
          ZLibEncoder(level: 9, raw: true, dictionary: dict).convert(data),
        );

        // Primed raw stream.
        final RawZLibFilter writer = RawZLibFilter.deflateFilter(
          level: 9,
          raw: true,
        );
        writer.process(dict, 0, dict.length);
        _drain(writer, end: false);
        writer.process(data, 0, data.length);
        final List<int> stream = _drain(writer, end: true);
        sizes[id] = stream.length;
        final List<int> primer = primers.putIfAbsent(name, () {
          final RawZLibFilter f = RawZLibFilter.deflateFilter(
            level: 9,
            raw: true,
          );
          f.process(dict, 0, dict.length);
          return _drain(f, end: false);
        });
        final List<int> input = <int>[...primer, ...stream];
        final RawZLibFilter reader = RawZLibFilter.inflateFilter(raw: true);
        reader.process(input, 0, input.length);
        final List<int> inflated = _drain(reader, end: true);
        roundTrips++;
        if (inflated.length != dict.length + data.length ||
            !_same(inflated.sublist(dict.length), data)) {
          failures++;
        }

        // zlib format with the dictionary.
        final List<int> zlib = ZLibEncoder(
          level: 9,
          dictionary: dict,
        ).convert(data);
        zlibSizes[id] = zlib.length - 6;
        if (!_same(ZLibDecoder(dictionary: dict).convert(zlib), data)) {
          failures++;
        }
      }

      File('$out/${kJobs}_sizes.json').writeAsStringSync(
        jsonEncode(<String, dynamic>{
          'sizes': sizes,
          'zlib_dictionary_sizes': zlibSizes,
          'raw_ignores_dictionary': rawIgnoresDictionary,
          'round_trips': roundTrips,
          'round_trip_failures': failures,
        }),
      );
      expect(failures, 0);
    },
    skip: kOut == null || kOut!.isEmpty
        ? 'Set HWB_AUDIT_OUT (and HWB_AUDIT_JOBS).'
        : false,
    timeout: const Timeout(Duration(minutes: 30)),
  );
}
