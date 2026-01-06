import 'agent_capability.dart';
import 'planner_agent.dart';
import 'agent_registry.dart';

/// Helper to set up default agent profiles with capabilities
class AgentProfileSetup {
  /// Register all known agents with their capabilities
  static void registerDefaults(PlannerAgent planner, AgentRegistry registry) {
    // CodeWriterAgent
    if (registry.getAgent('CodeWriter') != null) {
      planner.registerProfile(AgentProfile(
        agentName: 'CodeWriter',
        capabilities: [
          DefaultCapabilities.codeWriter,
          DefaultCapabilities.codeDebugger,
        ],
        maxConcurrentTasks: 3,
      ));
    }

    // WebCrawlerAgent
    if (registry.getAgent('WebCrawler') != null) {
      planner.registerProfile(AgentProfile(
        agentName: 'WebCrawler',
        capabilities: [DefaultCapabilities.webCrawler],
        maxConcurrentTasks: 10,
      ));
    }

    // FileSystemAgent
    if (registry.getAgent('FileSystem') != null) {
      planner.registerProfile(AgentProfile(
        agentName: 'FileSystem',
        capabilities: [DefaultCapabilities.fileManager],
        maxConcurrentTasks: 5,
      ));
    }

    // StorageAgent
    if (registry.getAgent('Storage') != null) {
      planner.registerProfile(AgentProfile(
        agentName: 'Storage',
        capabilities: [DefaultCapabilities.storage],
        maxConcurrentTasks: 10,
      ));
    }

    // DiffAgent
    if (registry.getAgent('Diff') != null) {
      planner.registerProfile(AgentProfile(
        agentName: 'Diff',
        capabilities: [DefaultCapabilities.diff],
        maxConcurrentTasks: 5,
      ));
    }

    // SystemAgent
    if (registry.getAgent('System') != null) {
      planner.registerProfile(AgentProfile(
        agentName: 'System',
        capabilities: [DefaultCapabilities.system],
        maxConcurrentTasks: 3,
      ));
    }

    // AppwriteFunctionAgent
    if (registry.getAgent('AppwriteFunction') != null) {
      planner.registerProfile(AgentProfile(
        agentName: 'AppwriteFunction',
        capabilities: [DefaultCapabilities.appwriteFunction],
        maxConcurrentTasks: 5,
      ));
    }
  }

  /// Create a custom agent profile
  static AgentProfile createCustomProfile({
    required String agentName,
    required List<AgentCapability> capabilities,
    int maxConcurrentTasks = 5,
  }) {
    return AgentProfile(
      agentName: agentName,
      capabilities: capabilities,
      maxConcurrentTasks: maxConcurrentTasks,
    );
  }
}
