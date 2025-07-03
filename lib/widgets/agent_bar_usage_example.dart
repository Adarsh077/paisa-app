// Example of how to use AgentBar in any screen
//
// Import the AgentBar widget:
// import 'package:paisa_app/widgets/agent_bar.dart';
//
// Then use it in your widget build method:
//
// 1. Basic usage with default text:
// AgentBar()
//
// 2. With custom text:
// AgentBar(
//   text: 'Ask me anything about your expenses...',
// )
//
// 3. With callbacks for speech results and completion:
// AgentBar(
//   text: 'How can I help you today?',
//   onSpeechResult: (String result) {
//     print('User said: $result');
//   },
//   onChatComplete: () {
//     // Refresh your screen data
//     _loadData();
//   },
// )
//
// 4. With custom mic button behavior:
// AgentBar(
//   text: 'Voice assistant',
//   onMicPressed: () {
//     // Custom mic button action
//     _handleMicPressed();
//   },
// )
//
// The AgentBar is now a generic component that can be easily:
// - Added to any screen
// - Customized with different text
// - Connected to different callbacks
// - Used consistently across the app
