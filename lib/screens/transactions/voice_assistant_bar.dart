import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../routes.dart';
import '../agent/agent.service.dart';

class VoiceAssistantBar extends StatefulWidget {
  final String text;
  final VoidCallback? onMicPressed;
  final Function(String)? onSpeechResult;
  final VoidCallback? onChatComplete;

  const VoiceAssistantBar({
    Key? key,
    this.text = 'Kya hukum hai mere aaqa?',
    this.onMicPressed,
    this.onSpeechResult,
    this.onChatComplete,
  }) : super(key: key);

  @override
  State<VoiceAssistantBar> createState() => _VoiceAssistantBarState();
}

class _VoiceAssistantBarState extends State<VoiceAssistantBar> {
  final SpeechToText _speechToText = SpeechToText();
  final AgentService _agentService = AgentService();
  bool _speechEnabled = false;
  String _currentWords = '';
  bool _isListening = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    // Stop speech recognition and clean up resources
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
    super.dispose();
  }

  /// Initialize speech-to-text
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: _onSpeechStatus,
      onError: _onSpeechError,
    );
    if (mounted) {
      setState(() {});
    }
  }

  /// Handle speech status changes
  void _onSpeechStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
      if (_currentWords.isNotEmpty) {
        print('Final speech result: $_currentWords');
        widget.onSpeechResult?.call(_currentWords);
        _sendToChat(_currentWords);
      }
    }
  }

  /// Send speech result to chat service
  Future<void> _sendToChat(String message) async {
    if (message.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final messages = [
        {"role": "user", "content": message}
      ];
      
      await _agentService.chat(messages);
      
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        // Call the refresh callback if provided
        widget.onChatComplete?.call();
      }
    } catch (e) {
      print('Error sending to chat: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        
        // Call the refresh callback even on error
        widget.onChatComplete?.call();
      }
    }
  }

  /// Handle speech errors
  void _onSpeechError(dynamic error) {
    print('Speech error: $error');
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  /// Start or stop listening for speech
  void _toggleListening() async {
    if (!_speechEnabled) {
      print('Speech recognition not available');
      return;
    }

    if (_isListening) {
      // Stop listening
      await _speechToText.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    } else {
      // Start listening
      if (mounted) {
        setState(() {
          _currentWords = '';
          _isListening = true;
        });
      }

      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        ),
        onSoundLevelChange: null,
      );
    }
  }

  /// Handle speech results
  void _onSpeechResult(SpeechRecognitionResult result) {
    if (mounted) {
      setState(() {
        _currentWords = result.recognizedWords;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Display current speech, processing state, or default text (no response display)
    String displayText;
    Color textColor;
    FontWeight? fontWeight;

    if (_isListening) {
      displayText = _currentWords.isEmpty ? 'Listening...' : _currentWords;
      textColor = colorScheme.primary;
      fontWeight = FontWeight.w500;
    } else if (_isProcessing) {
      displayText = 'Processing...';
      textColor = colorScheme.onSurface.withOpacity(0.7);
      fontWeight = FontWeight.w400;
    } else {
      displayText = widget.text;
      textColor = colorScheme.onSurface.withOpacity(0.8);
      fontWeight = null;
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.pushReplacementNamed(context, agent);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor,
                      fontWeight: fontWeight,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (_isProcessing) return; // Disable tap when processing
                    
                    if (widget.onMicPressed != null) {
                      widget.onMicPressed!();
                    } else {
                      _toggleListening();
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color:
                          _isListening
                              ? colorScheme.error.withOpacity(0.1)
                              : colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: _isProcessing
                        ? Center(
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                          )
                        : Icon(
                            _isListening ? Icons.stop : Icons.mic,
                            color:
                                _isListening
                                    ? colorScheme.error
                                    : colorScheme.primary,
                            size: 18,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
