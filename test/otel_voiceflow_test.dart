// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_voiceflow/otel_voiceflow.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_voiceflow-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('interact records intent + KB + tokens', () async {
    await tracedVoiceflow<String>(
      operation: 'interact',
      invoke: () async => const VoiceflowCallResult(
        value: 'ok',
        result: VoiceflowResult(
          projectId: 'proj_1',
          environment: 'production',
          userId: 'user_42',
          sessionId: 'sess_1',
          intent: 'refund_request',
          intentConfidence: 0.92,
          requestType: 'text',
          knowledgeBaseId: 'kb_1',
          kbHits: 3,
          kbDocumentIds: 'doc_a,doc_b,doc_c',
          modelName: 'gpt-4o',
          tokensConsumed: 950,
          tracesEmitted: 8,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('voiceflow interact')!);
    expect(a['voiceflow.intent'], 'refund_request');
    expect(a['voiceflow.intent.confidence'], 0.92);
    expect(a['voiceflow.kb.hits'], 3);
    expect(a['voiceflow.kb.document_ids'], 'doc_a,doc_b,doc_c');
    expect(a['voiceflow.tokens.consumed'], 950);
  });

  test('ended=error sets span error', () async {
    await tracedVoiceflow<String>(
      operation: 'interact',
      invoke: () async => const VoiceflowCallResult(
        value: 'ok',
        result: VoiceflowResult(
          endedReason: 'error',
        ),
      ),
    );
    expect(
      spans.findSpanByName('voiceflow interact')!.status,
      SpanStatusCode.Error,
    );
  });

  test('out-of-scope does NOT set span error', () async {
    await tracedVoiceflow<String>(
      operation: 'interact',
      invoke: () async => const VoiceflowCallResult(
        value: 'ok',
        result: VoiceflowResult(
          endedReason: 'out-of-scope',
        ),
      ),
    );
    expect(
      spans.findSpanByName('voiceflow interact')!.status,
      isNot(SpanStatusCode.Error),
    );
  });

  test('suppression skips spans', () async {
    await runWithoutVoiceflowInstrumentationAsync(() async {
      await tracedVoiceflow<String>(
        operation: 'kb.query',
        invoke: () async => const VoiceflowCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('voiceflow '), isEmpty);
  });
}
