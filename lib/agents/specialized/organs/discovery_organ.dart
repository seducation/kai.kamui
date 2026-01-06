import '../../core/step_types.dart';
import '../../core/step_schema.dart';
import '../../coordination/organ_base.dart';
import '../../specialized/web_crawler_agent.dart';

/// The Discovery Organ 🫀
///
/// Specialized in "Ingestion"—fetching raw information from external sources.
class DiscoveryOrgan extends Organ {
  DiscoveryOrgan({
    required WebCrawlerAgent crawler,
  }) : super(
          name: 'DiscoveryOrgan',
          tissues: [crawler],
          tokenLimit: 30000,
        );

  @override
  Future<R> onRun<R>(dynamic input) async {
    final crawler = tissues[0] as WebCrawlerAgent;

    return await execute<R>(
      action: StepType.fetch,
      target: 'External Information Discovery',
      task: () async {
        logStatus(StepType.fetch, 'Crawling for raw data nuggets',
            StepStatus.running);
        final result = await crawler.run<String>(input);
        consumeMetabolite(result.length);
        return result as R;
      },
    );
  }
}
