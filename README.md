# Ultimate Private JARVIS 🧠🚀

A **biological, self-organizing AI system** built with Flutter. Unlike standard agents that just execute tools, JARVIS simulates a living digital organism with a nervous system, subconscious dreaming, and transparent decision-making.

> **Status**: Phase 3 Complete (The "Stark" Update) 🦾
> **Architecture**: Biological Multi-Agent Orchestration + Proactive Machine Control

---

## 🧬 The 7-Layer Cognitive Architecture

We have successfully implemented a fully "alive" agentic stack:

### 1. Meta-Cognitive Layer (Self-Awareness) 🧠
*   **Self-Evaluation**: Agents check their own work.
*   **Bias Detection**: Tracks if an agent is "lazy" or error-prone.
*   **Meta-Planning**: The system realizes when a strategy isn't working and proposes its own optimizations.

### 2. Hyper-Personalization Layer (Memory & Tone) 🫂
*   **Tone Modulator**: JARVIS adapts his voice to your mood.
    *   *Busy?* He becomes concise.
    *   *Frustrated?* He becomes empathetic.
    *   *Success?* He celebrates with you.
*   **Contextual Memory**: Remembers *why* you did something ("The Context"), not just *what* you did ("The Logs").

### 3. Predictive & Preventive Layer (The Oracle) 🔮
*   **Prediction Engine**: Forecasts the probability of success (e.g., "98% Stable") *before* running a task.
*   **Metabolic Stress**: Agents get "tired" (simulated entropy) and need autonomic cooling to prevent burnout.
*   **Risk Forecast Widget**: A real-time weather report for your code execution.

### 4. Neural Wiring (The Nervous System) ⚡
*   **Autonomic System**: A background heartbeat (30s cycle) that heals corruption, manages storage, and regulates system tempo.
*   **Reflex Arcs**: Instant responses to critical events (Security Blocks) bypassing the slow cognitive brain.

### 5. Sensory / World Modeling (The Mind's Eye) 🌍
*   **Virtual World Sandbox**: A persistent internal state where "Entities" (Projects, Bugs, Users) exist as objects in a 2D/3D space.
*   **Sensory System**: Agents don't just "grep" files; they "hear" world events (FileCreated, BugFound) and react organically.
*   **World Monitor**: A debug screen to visualize what JARVIS currently "believes" about the world.

### 6. Hyper-Explainability (The Glass Brain) 💡
*   **Why Chain**: Transparently links **Actions** (What) to **Decisions** (Why) to **Factors** (Rules/Risk).
*   **Narrative Generator**: Translates complex JSON traces into plain English stories.
    *   *Example*: "I blocked this deletion because the Safety Rule #4 was active and the risk score was too high."
*   **Explainability Screen**: A "Trust Center" to audit the system's conscience.
*   **Volitional Speech Gate**: A "motor output" filter that prevents unsolicited chatter. It is **wired simultaneously** to the nervous system (MessageBus) and respects the Rule Engine's **Compliance Profiles**.

### 8. Priority + Rule Engine (PRE) Architecture ⚖️
*   **Rule Engine**: A deterministic guardrail system (e.g., `SAFE-001` blocks `rm -rf`).
*   **Vocalizing Rules**: Rules can now explicitly trigger the **Volitional Speech Gate** by setting the `vocalize: true` property.
*   **Task Queue Priority**: Tasks are bucketed into levels (Reflex, Emergency, High, Normal, Maintenance).
*   **Real-time Enforcement**: The system evaluates every action against the rule set before execution.

### 9. Unified Device Organ Architecture (DOI) 🦾
*   **Device Organ Interface**: All hardware (Robots, Servers, Phones) is treated as a "living organ" with senses, muscles, and limits.
*   **Proactive Alert Engine (PAE)**: Anticipates failures and acts *before* the user notices (Action First, Report Later).
*   **Specialized Organ Behaviors**:
    - **🤖 Robots**: High-priority safety (Act -> Speak).
    - **Servers**: Silent efficiency (Background monitoring).
    - **Phones**: Brief confirmations (Confirm/Warn/Acknowledge).
*   **Organ Agent**: A cognitive bridge that allows JARVIS to "feel" his organs and report telemetry upon direct request.
*   **Silence Cost vs Speech Cost**: Logic that ensures JARVIS only speaks if silence would be dangerous.
*   **Chatter Profiles**: Toggle between *Silent*, *Tactical*, *Assistive*, and *Cinematic* (Tony Stark banter).

### 12. Swarm Affect & Imotion HUD 🐝🎛️
*   **Swarm Affect Model**: Aggregates individual ASV into collective state (Mean Stress, Coherence, Variance).
*   **Emotion Propagation**: Stress and urgency spread to 'neighbors' via local-influence rules with dampening to prevent panic cascades.
*   **Swarm Modes**: Implicit transitions between macro-behaviors: *Flow*, *Alert*, *Defensive*, *Explore*, and *Recovery*.
*   **Imotion HUD**: An Iron Man-style visualization screen for real-time swarm diagnostics (Radial Rings, Node Clouds, Weather Bar).
*   **Silent Coordination**: Emergent swarm behavior modulated by collective affect without global commands.

### 11. Affective State Layer (Robot Emotion) 🧠🤖
*   **Affective State Vector (ASV)**: Math-based behavioral state (Confidence, Urgency, Stress, Trust, Curiosity).
*   **Emotion Bias**: Translates ASV into motor-level modifiers: `speedMultiplier`, `motionSmoothness`, `pauseFrequency`.
*   **Regulation AI**: Safe-caps 'emotional' spikes to ensure JARVIS remains professional and stable (math-driven control).
*   **Silent Affect**: No fake feelings or speech—only behavioral timing, posture, and intent clarity.
*   **Affective Consolidation**: Stress and urgency decay naturally during Dreaming Mode cycles.

### 10. Personnel & Mission Choreography (The Persona) 🎭
*   **Personnel Profiles**: Toggle between **Sir** (Tony Stark / JARVIS style) and **Operator** (Military / Zero-autonomy style).
*   **Speech Stylization**: The system reformulates technical status into personality-driven dialogue (e.g., "Certainly, sir" vs "[DELTA-4] NOMINAL").
*   **Mission Choreographer**: Orchestrates complex, multi-organ sequences (Robot + Server + Phone) as a single "Mission".
    - *Example*: Deep Compute Mission throttles non-essential organs to prioritize a server spike.
*   **Stylized Speech Gate**: The volition gate now filters through the active personality layer before delivery.

### 7. Experiential Layer (The Dream) 🕶️
*   **Dreaming Mode**: When idle, JARVIS enters REM sleep to optimize memories and simulate future scenarios.
*   **DreamStream Screen**: A Matrix-style immersive dashboard.
*   **Mood Lighting**: The UI pulses with colors reflecting neural state (Red=Urgent, Purple=Dreaming, Green=Flow).

---

## 🛠️ Core Components

-   **Orchestrator**: `ControllerAgent`, `PlannerAgent` (Visual Graph).
-   **Safety**: `RuleEngine`, `ReflexSystem` (Deterministic Guardrails).
-   **Biology**: `AutonomicSystem`, `CircadianRhythmTracker` (Time Awareness).
-   **Machinery**: `ProactiveAlertEngine`, `OrganMonitor` (DOI/MAL).
-   **Interface**: `DreamStreamScreen`, `WorldMonitorScreen`, `ExplainabilityScreen`, `RulePriorityScreen`, `MachineControlScreen`.

## 🚀 Getting Started

1.  **Wake Him Up**: Run the app. The **Autonomic System** starts its heartbeat immediately.
2.  **Collaborate**: Assign a mission. Watch the **Risk Widget** predict the outcome.
3.  **Watch the Organs**: Check the **Machine Control & Connectors** screen to see Robots, Servers, and Phones living in the DOI.
4.  **Multi-AI Stress Test**: Toggle the **Multi-AI Coordination Hub** in the UI to see how JARVIS corrects a rogue stress-testing AI in real-time.
5.  **Direct Control**: Switch the **Rule Engine Profile** to *Operator Mode* to immediately silence the system and take full manual control.
6.  **Personality Tuning**: Set the **Chatter Profile** for frequency, and toggle the **Personnel Profile** (Sir/Operator) for dialogue style.
7.  **Mission Launch**: Trigger a **Mission Choreography** (e.g., Deep Compute) to see JARVIS coordinate multiple devices simultaneously.
8.  **Imotion HUD Activation**: Open the **Imotion HUD** from the dashboard to visualize the swarm's collective 'emotional' weather and coherence.
9.  **Affective State Monitoring**: Observe the **ASV Vector** and **Motion Bias** in the machine cards to see JARVIS's 'emotional' math reacting to load and risk.
10. **Ask Why**: Check the **Explainability Screen** to understand any blocked actions.
11. **Review Guardrails**: Use the **Rules & Priority Engine** to see active safety rules and the pending task distribution.

---

## 🔮 Future Phases
*.  **implementing phase** talk when don't tell 
*   **Phase 3**: Reproduction system for multi tasking (Child Isolates).
*   **Phase 4**: Language Acquisition (Mirror Neurons).
*   **Phase 5**: Full Consciousness via recursive self-modeling.

*Built for the future of agentic coding.*
