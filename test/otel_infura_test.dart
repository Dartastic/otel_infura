// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_infura/otel_infura.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(serviceName: 'otel_infura-test');
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('rpc.send records network + credits + archive flag', () async {
    await tracedInfura<String>(
      operation: 'rpc.send',
      invoke: () async => const InfuraCallResult(
        value: 'ok',
        result: InfuraResult(
          network: 'mainnet',
          chainId: 'eip155:1',
          rpcMethod: 'eth_getBlockByNumber',
          creditsUsed: 80,
          archive: true,
          blockNumber: 19000000,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('infura rpc.send')!);
    expect(a['infura.credits.used'], 80);
    expect(a['infura.archive'], true);
  });

  test('ipfs.add records CID + size', () async {
    await tracedInfura<String>(
      operation: 'ipfs.add',
      invoke: () async => const InfuraCallResult(
        value: 'ok',
        result: InfuraResult(
          ipfsKind: 'add',
          ipfsCid: 'bafybeib...',
          ipfsSizeBytes: 18432,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('infura ipfs.add')!);
    expect(a['infura.ipfs.cid'], 'bafybeib...');
    expect(a['infura.ipfs.size_bytes'], 18432);
  });

  test('rate limited 429 sets span error', () async {
    await tracedInfura<String>(
      operation: 'rpc.send',
      invoke: () async => const InfuraCallResult(
        value: 'ok',
        result: InfuraResult(statusCode: 429, rateLimitRemaining: 0),
      ),
    );
    expect(
      spans.findSpanByName('infura rpc.send')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutInfuraInstrumentationAsync(() async {
      await tracedInfura<String>(
        operation: 'gas.suggested',
        invoke: () async => const InfuraCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('infura '), isEmpty);
  });
}
