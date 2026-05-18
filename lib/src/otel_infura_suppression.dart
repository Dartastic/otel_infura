// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'dart:async';

const _key = #dartastic_otel_libs_infura_suppress;

bool infuraInstrumentationSuppressed() => Zone.current[_key] == true;

T runWithoutInfuraInstrumentation<T>(T Function() body) =>
    runZoned(body, zoneValues: {_key: true});

Future<T> runWithoutInfuraInstrumentationAsync<T>(
  Future<T> Function() body,
) =>
    runZoned(body, zoneValues: {_key: true});
