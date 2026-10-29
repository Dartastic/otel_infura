// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_infura/otel_infura.dart';

/// Traces Infura calls with OpenTelemetry.
///
/// `otel_infura` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Infura call in
/// [tracedInfura]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'infura-example');

  // Wraps an Infura API call in a CLIENT span.
  final infuraId = await tracedInfura<String>(
    operation: 'rpc.send',
    invoke: () async {
      // Make the Infura call here, then report what it returned.
      const id = 'infura_8f3a2c';
      return const InfuraCallResult(
          value: id,
          result: InfuraResult(
              network: 'mainnet',
              chainId: 'chain_8f3a2c',
              rpcMethod: 'example',
              batchSize: 512,
              creditsUsed: 1,
              responseBytes: 512,
              blockNumber: 1,
              ipfsKind: 'pin',
              ipfsCid: 'ipfsc_8f3a2c',
              ipfsSizeBytes: 512,
              archive: true,
              rateLimitRemaining: 25,
              errorCode: 'example',
              errorMessage: 'example',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedInfura rpc.send returned $infuraId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutInfuraInstrumentationAsync.
  await runWithoutInfuraInstrumentationAsync(
    () => tracedInfura<String>(
      operation: 'rpc.send',
      invoke: () async {
        const id = 'infura_8f3a2c';
        return const InfuraCallResult(
            value: id,
            result: InfuraResult(
                network: 'mainnet',
                chainId: 'chain_8f3a2c',
                rpcMethod: 'example',
                batchSize: 512,
                creditsUsed: 1,
                responseBytes: 512,
                blockNumber: 1,
                ipfsKind: 'pin',
                ipfsCid: 'ipfsc_8f3a2c',
                ipfsSizeBytes: 512,
                archive: true,
                rateLimitRemaining: 25,
                errorCode: 'example',
                errorMessage: 'example',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
