// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_voiceflow_suppression.dart';

const _tracerName = 'dartastic_otel_libs_voiceflow';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class VoiceflowResult {
  const VoiceflowResult({
    this.projectId,
    this.versionId,
    this.environment,
    this.userId,
    this.sessionId,
    this.intent,
    this.intentConfidence,
    this.requestType,
    this.endedReason,
    this.kbHits,
    this.kbDocumentIds,
    this.knowledgeBaseId,
    this.modelName,
    this.tokensConsumed,
    this.tracesEmitted,
    this.statusCode,
  });

  /// Voiceflow project (the agent definition).
  final String? projectId;

  /// Version id when calling the version-locked API.
  final String? versionId;

  /// `development` / `production` — agent environment slug.
  final String? environment;

  /// `userID` query param Voiceflow uses as a session affinity key.
  final String? userId;

  /// Voiceflow Run API `sessionID`.
  final String? sessionId;

  /// Matched intent name (or `None` if classifier returned no match).
  final String? intent;

  /// Intent classifier confidence (0.0-1.0).
  final double? intentConfidence;

  /// `text` / `launch` / `intent` / `action` / `path` / `no-reply`.
  final String? requestType;

  /// `end` (end node) / `error` / `out-of-scope` / `handoff` /
  /// `unknown`.
  final String? endedReason;

  /// Knowledge Base hit count from semantic search.
  final int? kbHits;

  /// Comma-separated document ids that backed the KB answer.
  final String? kbDocumentIds;

  /// Knowledge Base id (Voiceflow lets you scope per-project KBs).
  final String? knowledgeBaseId;

  /// Model used (default Voiceflow rotates among OpenAI/Anthropic; can
  /// also be `claude-3-5-sonnet`, `gpt-4o`, etc.).
  final String? modelName;

  /// Voiceflow charges per token consumed across LLM/AI Response/AI
  /// Set blocks.
  final int? tokensConsumed;

  /// How many trace events were returned (each maps to a UI step).
  final int? tracesEmitted;

  final int? statusCode;
}

class VoiceflowCallResult<T> {
  const VoiceflowCallResult({required this.value, this.result});
  final T value;
  final VoiceflowResult? result;
}

/// Wraps a Voiceflow Dialog Manager / Knowledge Base API call in a
/// CLIENT span. [operation] is one of `interact`, `interact.stream`,
/// `state.get`, `state.update`, `state.delete`, `transcript.create`,
/// `kb.query`, `kb.documents.upsert`, `kb.documents.list`,
/// `analytics.events`, `nlu.predict`.
Future<T> tracedVoiceflow<T>({
  required String operation,
  required Future<VoiceflowCallResult<T>> Function() invoke,
}) async {
  if (voiceflowInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'voiceflow',
    'rpc.method': operation,
    'voiceflow.operation': operation,
  };

  final span = _tracer().startSpan(
    'voiceflow $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.projectId != null) {
        extras.add(OTel.attributeString(
          'voiceflow.project.id',
          r.result!.projectId!,
        ));
      }
      if (r.result!.versionId != null) {
        extras.add(OTel.attributeString(
          'voiceflow.version.id',
          r.result!.versionId!,
        ));
      }
      if (r.result!.environment != null) {
        extras.add(OTel.attributeString(
          'voiceflow.environment',
          r.result!.environment!,
        ));
      }
      if (r.result!.userId != null) {
        extras.add(OTel.attributeString(
          'voiceflow.user.id',
          r.result!.userId!,
        ));
      }
      if (r.result!.sessionId != null) {
        extras.add(OTel.attributeString(
          'voiceflow.session.id',
          r.result!.sessionId!,
        ));
      }
      if (r.result!.intent != null) {
        extras.add(OTel.attributeString(
          'voiceflow.intent',
          r.result!.intent!,
        ));
      }
      if (r.result!.intentConfidence != null) {
        extras.add(OTel.attributeDouble(
          'voiceflow.intent.confidence',
          r.result!.intentConfidence!,
        ));
      }
      if (r.result!.requestType != null) {
        extras.add(OTel.attributeString(
          'voiceflow.request.type',
          r.result!.requestType!,
        ));
      }
      if (r.result!.endedReason != null) {
        extras.add(OTel.attributeString(
          'voiceflow.ended.reason',
          r.result!.endedReason!,
        ));
        if (r.result!.endedReason == 'error') {
          span.setStatus(SpanStatusCode.Error, 'Voiceflow ended=error');
        }
      }
      if (r.result!.kbHits != null) {
        extras.add(OTel.attributeInt(
          'voiceflow.kb.hits',
          r.result!.kbHits!,
        ));
      }
      if (r.result!.kbDocumentIds != null) {
        extras.add(OTel.attributeString(
          'voiceflow.kb.document_ids',
          r.result!.kbDocumentIds!,
        ));
      }
      if (r.result!.knowledgeBaseId != null) {
        extras.add(OTel.attributeString(
          'voiceflow.knowledge_base.id',
          r.result!.knowledgeBaseId!,
        ));
      }
      if (r.result!.modelName != null) {
        extras.add(OTel.attributeString(
          'voiceflow.model.name',
          r.result!.modelName!,
        ));
      }
      if (r.result!.tokensConsumed != null) {
        extras.add(OTel.attributeInt(
          'voiceflow.tokens.consumed',
          r.result!.tokensConsumed!,
        ));
      }
      if (r.result!.tracesEmitted != null) {
        extras.add(OTel.attributeInt(
          'voiceflow.traces.emitted',
          r.result!.tracesEmitted!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTel.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Voiceflow HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
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
