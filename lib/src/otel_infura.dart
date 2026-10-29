// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_infura_suppression.dart';

const _tracerName = 'dartastic_otel_libs_infura';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class InfuraResult {
  /// Creates a result.
  const InfuraResult({
    this.network,
    this.chainId,
    this.rpcMethod,
    this.batchSize,
    this.creditsUsed,
    this.responseBytes,
    this.blockNumber,
    this.ipfsKind,
    this.ipfsCid,
    this.ipfsSizeBytes,
    this.archive,
    this.rateLimitRemaining,
    this.errorCode,
    this.errorMessage,
    this.statusCode,
  });

  /// `mainnet`, `sepolia`, `holesky`, `polygon-mainnet`,
  /// `arbitrum-mainnet`, `optimism-mainnet`, `linea-mainnet`,
  /// `palm-mainnet`, `near-mainnet`, `starknet-mainnet`.
  final String? network;

  /// CAIP-2 chain id.
  final String? chainId;

  /// JSON-RPC method.
  final String? rpcMethod;

  final int? batchSize;

  /// Infura request credits (primary billing dimension).
  final int? creditsUsed;

  final int? responseBytes;
  final int? blockNumber;

  /// IPFS operation kind: `pin`, `unpin`, `add`, `get`, `cat`, `ls`,
  /// `stat`, `dag.get`, `dag.put`, `key.list`.
  final String? ipfsKind;

  /// IPFS Content Identifier.
  final String? ipfsCid;

  final int? ipfsSizeBytes;

  /// Archive-node call (charged at higher CU rate).
  final bool? archive;

  final int? rateLimitRemaining;

  final String? errorCode;
  final String? errorMessage;
  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class InfuraCallResult<T> {
  /// Creates a call result.
  const InfuraCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final InfuraResult? result;
}

/// Wraps an Infura API call in a CLIENT span. [operation] is one of
/// `rpc.send`, `rpc.sendBatch`, `ipfs.pin`, `ipfs.unpin`, `ipfs.add`,
/// `ipfs.get`, `ipfs.cat`, `ipfs.ls`, `ipfs.stat`,
/// `ipfs.dag.get`, `ipfs.dag.put`, `ipfs.key.list`,
/// `nft.getMetadata`, `nft.getOwners`, `nft.getTransfers`,
/// `gas.suggested`, `gas.history`.
Future<T> tracedInfura<T>({
  required String operation,
  required Future<InfuraCallResult<T>> Function() invoke,
}) async {
  if (infuraInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'infura',
    'rpc.method': operation,
    'infura.operation': operation,
  };

  final span = _tracer().startSpan(
    'infura $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.network != null) {
        extras.add(OTelAPI.attributeString('infura.network', res.network!));
      }
      if (res.chainId != null) {
        extras.add(OTelAPI.attributeString('infura.chain.id', res.chainId!));
      }
      if (res.rpcMethod != null) {
        extras
            .add(OTelAPI.attributeString('infura.rpc.method', res.rpcMethod!));
      }
      if (res.batchSize != null) {
        extras.add(OTelAPI.attributeInt('infura.batch.size', res.batchSize!));
      }
      if (res.creditsUsed != null) {
        extras.add(OTelAPI.attributeInt(
          'infura.credits.used',
          res.creditsUsed!,
        ));
      }
      if (res.responseBytes != null) {
        extras.add(OTelAPI.attributeInt(
          'infura.response.bytes',
          res.responseBytes!,
        ));
      }
      if (res.blockNumber != null) {
        extras.add(OTelAPI.attributeInt(
          'infura.block.number',
          res.blockNumber!,
        ));
      }
      if (res.ipfsKind != null) {
        extras.add(OTelAPI.attributeString('infura.ipfs.kind', res.ipfsKind!));
      }
      if (res.ipfsCid != null) {
        extras.add(OTelAPI.attributeString('infura.ipfs.cid', res.ipfsCid!));
      }
      if (res.ipfsSizeBytes != null) {
        extras.add(OTelAPI.attributeInt(
          'infura.ipfs.size_bytes',
          res.ipfsSizeBytes!,
        ));
      }
      if (res.archive != null) {
        extras.add(OTelAPI.attributeBool('infura.archive', res.archive!));
      }
      if (res.rateLimitRemaining != null) {
        extras.add(OTelAPI.attributeInt(
          'infura.rate_limit.remaining',
          res.rateLimitRemaining!,
        ));
      }
      if (res.errorCode != null) {
        extras.add(OTelAPI.attributeString(
          'infura.error.code',
          res.errorCode!,
        ));
        span.setStatus(SpanStatusCode.Error, 'Infura ${res.errorCode}');
      }
      if (res.errorMessage != null) {
        extras.add(OTelAPI.attributeString(
          'infura.error.message',
          res.errorMessage!,
        ));
      }
      if (res.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          res.statusCode!,
        ));
        if (res.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Infura HTTP ${res.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
