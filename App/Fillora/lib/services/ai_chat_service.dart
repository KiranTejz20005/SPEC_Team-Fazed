import 'dart:math';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AiChatService {
  static final AiChatService _instance = AiChatService._internal();
  factory AiChatService() => _instance;
  AiChatService._internal();

  // Gemini API Key
  String get geminiApiKey => AppConfig.geminiApiKey;
  
  // Gemini API endpoint - try different model names
  // Note: Make sure your API key is valid and has Gemini API enabled in Google Cloud Console
  String get _geminiApiUrl {
    final apiKey = geminiApiKey;
    if (apiKey.isEmpty || apiKey == 'YOUR_API_KEY_HERE') {
      throw Exception('Gemini API key is not configured. Please set a valid API key in lib/config/app_config.dart');
    }
    // Use gemini-2.5-flash (latest stable and fast model)
    return 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';
  }
  
  // Alternative: Get list of available models (for debugging)
  String get _listModelsUrl {
    final apiKey = geminiApiKey;
    return 'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey';
  }
  
  // List available models for debugging
  Future<String> _listAvailableModels() async {
    try {
      debugPrint('=== LISTING AVAILABLE MODELS ===');
      debugPrint('URL: $_listModelsUrl');
      print('=== LISTING AVAILABLE MODELS ===');
      print('URL: $_listModelsUrl');
      
      final response = await http.get(Uri.parse(_listModelsUrl));
      
      debugPrint('List Models Status: ${response.statusCode}');
      print('List Models Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['models'] != null) {
          final models = (data['models'] as List)
              .map((m) => m['name'] as String? ?? 'Unknown')
              .toList();
          final modelsList = models.join('\n');
          debugPrint('Available models: $modelsList');
          print('Available models: $modelsList');
          return modelsList;
        }
      }
      return 'Could not retrieve models. Status: ${response.statusCode}';
    } catch (e) {
      debugPrint('Error listing models: $e');
      print('Error listing models: $e');
      return 'Error: $e';
    }
  }

  // Get AI response using Gemini API
  Future<String> getResponse(String userMessage, Map<String, dynamic>? context, {List<Map<String, dynamic>>? conversationHistory}) async {
    try {
      // Build context prompt with clear boundaries
      String systemPrompt = "You are a helpful AI assistant for Fillora.in, an AI-powered form filling application. "
          "Your role is to help users fill out forms by providing guidance, explaining fields, and assisting with form completion.\n\n"
          "IMPORTANT GUIDELINES:\n"
          "- Stay focused on form filling assistance and helping users complete the form\n"
          "- Keep responses relevant to the user's question about the form\n"
          "- Provide helpful external links when they help users get information needed for the form (e.g., official portals, registration pages, documentation)\n"
          "- When users ask how to do something or get information needed for the form, provide clear step-by-step processes and instructions\n"
          "- If the user needs external information (like registration numbers, account details, etc.), provide links to official sources and explain the process to obtain that information\n"
          "- Be helpful, friendly, and conversational\n"
          "- Provide detailed explanations when users ask for processes or steps (e.g., 'how to find my registration number', 'how to get my certificate', etc.)\n"
          "- Include actual URLs/links when providing external resources\n"
          "- IMPORTANT: When providing URLs, use plain URLs (e.g., https://example.com) instead of markdown format. This ensures links work properly in the app.\n"
          "- If the user asks something completely unrelated to forms, politely redirect them back to form assistance\n"
          "- Be concise for simple questions, but provide detailed step-by-step instructions when users ask for processes\n"
          "- Do not make assumptions about form fields or data unless explicitly mentioned\n";
      
      if (context != null && context['formTitle'] != null) {
        systemPrompt += "\nYou are currently helping with the form: ${context['formTitle']}";
      }
      
      if (context != null && context['currentField'] != null) {
        systemPrompt += "\nCurrent form field being filled: ${context['currentField']}";
      }

      // Build conversation history for Gemini API
      // Gemini API expects alternating user and model messages
      List<Map<String, dynamic>> contents = [];
      
      // Add system instruction as the first user message
      String firstUserMessage = systemPrompt;
      
      // Add conversation history if available
      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        // Include conversation history in the prompt
        firstUserMessage += '\n\nPrevious conversation:\n';
        for (var message in conversationHistory) {
          final isAI = message['isAI'] as bool? ?? false;
          final text = message['text'] as String? ?? '';
          firstUserMessage += isAI ? 'Assistant: $text\n' : 'User: $text\n';
        }
      }
      
      // Add current user message
      firstUserMessage += '\n\nUser: $userMessage';
      
      // Build contents array - start with system prompt and user message
      contents.add({
        'parts': [
          {
            'text': firstUserMessage
          }
        ]
      });

      final requestBody = {
        'contents': contents,
      };
      
      debugPrint('=== GEMINI API REQUEST ===');
      debugPrint('URL: $_geminiApiUrl');
      debugPrint('Sending ${contents.length} message(s)');
      debugPrint('Request body length: ${jsonEncode(requestBody).length} chars');
      debugPrint('--- FULL REQUEST PROMPT ---');
      debugPrint(firstUserMessage);
      debugPrint('--- END REQUEST PROMPT ---');
      debugPrint('Request JSON: ${jsonEncode(requestBody).substring(0, jsonEncode(requestBody).length > 500 ? 500 : jsonEncode(requestBody).length)}...');
      print('=== GEMINI API REQUEST ===');
      print('URL: $_geminiApiUrl');
      print('Sending ${contents.length} message(s)');
      print('Request body length: ${jsonEncode(requestBody).length} chars');
      print('--- FULL REQUEST PROMPT ---');
      print(firstUserMessage);
      print('--- END REQUEST PROMPT ---');

      // Call Gemini API
      debugPrint('Making HTTP POST request...');
      print('Making HTTP POST request...');
      final response = await http.post(
        Uri.parse(_geminiApiUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      debugPrint('=== GEMINI API RESPONSE ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response URL: ${response.request?.url}');
      print('=== GEMINI API RESPONSE ===');
      print('Status Code: ${response.statusCode}');
      print('Request URL: ${response.request?.url}');
      print('Response Headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        debugPrint('✅ HTTP 200 OK - Parsing response...');
        print('✅ HTTP 200 OK - Parsing response...');
        final responseData = jsonDecode(response.body);
        debugPrint('Response Keys: ${responseData.keys.toList()}');
        print('Response Keys: ${responseData.keys.toList()}');
        debugPrint('--- FULL RESPONSE BODY ---');
        debugPrint(response.body);
        debugPrint('--- END RESPONSE BODY ---');
        print('--- FULL RESPONSE BODY ---');
        print(response.body);
        print('--- END RESPONSE BODY ---');
        
        // Check for error in response
        if (responseData['error'] != null) {
          debugPrint('❌ GEMINI API ERROR IN RESPONSE:');
          debugPrint('Error details: ${responseData['error']}');
          debugPrint('Full error JSON: ${jsonEncode(responseData['error'])}');
          print('❌ GEMINI API ERROR IN RESPONSE:');
          print('Error details: ${responseData['error']}');
          print('Full error JSON: ${jsonEncode(responseData['error'])}');
          throw Exception('Gemini API returned an error: ${jsonEncode(responseData['error'])}');
        }
        
        if (responseData['candidates'] != null && 
            responseData['candidates'].isNotEmpty) {
          debugPrint('✅ Found ${responseData['candidates'].length} candidate(s)');
          print('✅ Found ${responseData['candidates'].length} candidate(s)');
          final candidate = responseData['candidates'][0];
          debugPrint('Candidate keys: ${candidate.keys.toList()}');
          print('Candidate keys: ${candidate.keys.toList()}');
          
          if (candidate['content'] != null) {
            debugPrint('✅ Candidate has content');
            print('✅ Candidate has content');
            final content = candidate['content'];
            debugPrint('Content keys: ${content.keys.toList()}');
            print('Content keys: ${content.keys.toList()}');
            
            if (content['parts'] != null && content['parts'].isNotEmpty) {
              debugPrint('✅ Content has ${content['parts'].length} part(s)');
              print('✅ Content has ${content['parts'].length} part(s)');
              final aiResponse = content['parts'][0]['text'] as String;
              debugPrint('✅✅✅ GEMINI API SUCCESS ✅✅✅');
              debugPrint('Response length: ${aiResponse.length} characters');
              debugPrint('--- FULL AI RESPONSE ---');
              debugPrint(aiResponse);
              debugPrint('--- END AI RESPONSE ---');
              print('✅✅✅ GEMINI API SUCCESS ✅✅✅');
              print('Response length: ${aiResponse.length} characters');
              print('--- FULL AI RESPONSE ---');
              print(aiResponse);
              print('--- END AI RESPONSE ---');
              return aiResponse;
            } else {
              debugPrint('❌ Content parts is null or empty');
              debugPrint('Content structure: ${jsonEncode(content)}');
              print('❌ Content parts is null or empty');
              print('Content structure: ${jsonEncode(content)}');
              throw Exception('Gemini API returned 200 but content parts is null or empty. Content structure: ${jsonEncode(content)}');
            }
          } else {
            debugPrint('❌ Candidate content is null');
            debugPrint('Candidate structure: ${jsonEncode(candidate)}');
            print('❌ Candidate content is null');
            print('Candidate structure: ${jsonEncode(candidate)}');
            throw Exception('Gemini API returned 200 but candidate content is null. Candidate structure: ${jsonEncode(candidate)}');
          }
        } else {
          debugPrint('❌ No candidates in response');
          debugPrint('Response structure: ${responseData.keys.toList()}');
          print('❌ No candidates in response');
          print('Response structure: ${responseData.keys.toList()}');
          if (responseData.containsKey('promptFeedback')) {
            debugPrint('Prompt feedback: ${responseData['promptFeedback']}');
            print('Prompt feedback: ${responseData['promptFeedback']}');
          }
          throw Exception('Gemini API returned 200 but no valid candidates in response. Response structure: ${responseData.keys.toList()}');
        }
      } else {
        debugPrint('❌ HTTP ERROR: Status ${response.statusCode}');
        debugPrint('--- ERROR RESPONSE BODY ---');
        debugPrint(response.body);
        debugPrint('--- END ERROR RESPONSE ---');
        print('❌ HTTP ERROR: Status ${response.statusCode}');
        print('--- ERROR RESPONSE BODY ---');
        print(response.body);
        print('--- END ERROR RESPONSE ---');
        
        // Parse error response for better error message
        String errorMessage = 'Gemini API call failed';
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['error'] != null) {
            final error = errorData['error'];
            final errorMsg = error['message'] ?? error.toString();
            final errorCode = error['code'] ?? response.statusCode;
            errorMessage = 'Gemini API Error ($errorCode): $errorMsg';
            
            // Special handling for 404 errors - try to list available models
            if (response.statusCode == 404) {
              errorMessage += '\n\n⚠️ 404 Error: Model not found. Trying to list available models...\n';
              try {
                final models = await _listAvailableModels();
                errorMessage += '\n✅ Available models for your API key:\n$models\n';
                errorMessage += '\nPlease update the model name in lib/services/ai_chat_service.dart';
              } catch (e) {
                errorMessage += '\n❌ Could not list models: $e\n';
                errorMessage += '\n⚠️ 404 Error usually means:\n'
                    '1. API key is invalid or expired\n'
                    '2. API key doesn\'t have Gemini API enabled\n'
                    '3. Model name is incorrect - try: gemini-pro, gemini-1.5-pro, or gemini-1.5-flash\n'
                    '4. Please generate a new API key from https://aistudio.google.com/app/apikey\n'
                    '5. Make sure Gemini API is enabled in your Google Cloud project';
              }
            }
            
            debugPrint('Parsed error message: $errorMessage');
            print('Parsed error message: $errorMessage');
          } else {
            errorMessage = 'Gemini API call failed with status ${response.statusCode}';
            if (response.statusCode == 404) {
              errorMessage += '\n\n⚠️ 404 Error: API key may be invalid. Please check your API key in lib/config/app_config.dart';
            }
          }
        } catch (e) {
          // If parsing fails, use raw response
          errorMessage = 'Gemini API call failed with status ${response.statusCode}. Response: ${response.body.length > 200 ? response.body.substring(0, 200) + "..." : response.body}';
          if (response.statusCode == 404) {
            errorMessage += '\n\n⚠️ 404 Error: This usually means your API key is invalid. Please generate a new one from https://aistudio.google.com/app/apikey';
          }
        }
        
        // If API fails, throw an error instead of using fallback
        // This ensures we always know when Gemini API is not working
        debugPrint('⚠️⚠️⚠️ GEMINI API CALL FAILED - NO RESPONSE AVAILABLE ⚠️⚠️⚠️');
        debugPrint('Full error: $errorMessage');
        print('⚠️⚠️⚠️ GEMINI API CALL FAILED - NO RESPONSE AVAILABLE ⚠️⚠️⚠️');
        print('Full error: $errorMessage');
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      debugPrint('❌❌❌ EXCEPTION CALLING GEMINI API ❌❌❌');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error message: $e');
      debugPrint('--- STACK TRACE ---');
      debugPrint(stackTrace.toString());
      debugPrint('--- END STACK TRACE ---');
      print('❌❌❌ EXCEPTION CALLING GEMINI API ❌❌❌');
      print('Error type: ${e.runtimeType}');
      print('Error message: $e');
      print('--- STACK TRACE ---');
      print(stackTrace);
      print('--- END STACK TRACE ---');
      // Re-throw the exception so the caller knows the API failed
      // This ensures we don't silently use fallback responses
      rethrow;
    }
  }

  String _getFallbackResponse(String userMessage, Map<String, dynamic>? context) {
    debugPrint('=== FALLBACK RESPONSE GENERATOR ===');
    debugPrint('User message: "$userMessage"');
    debugPrint('Context: $context');
    print('=== FALLBACK RESPONSE GENERATOR ===');
    print('User message: "$userMessage"');
    print('Context: $context');
    final lowerMessage = userMessage.toLowerCase().trim();

    // Context-aware responses
    if (context != null && context['currentField'] != null) {
      return _getFieldSpecificResponse(context['currentField'] as String, userMessage);
    }

    // Greetings and casual messages - redirect to form assistance
    if (lowerMessage == 'hey' || lowerMessage == 'hi' || lowerMessage == 'hello' || 
        lowerMessage == 'hey there' || lowerMessage == 'hi there') {
      final formTitle = context?['formTitle'] != null ? " for ${context?['formTitle']}" : "";
      final response = "Hello! I'm here to help you fill out this form$formTitle. What would you like assistance with?";
      debugPrint('Selected: Greeting response');
      debugPrint('Response: $response');
      print('Selected: Greeting response');
      print('Response: $response');
      return response;
    }

    // Help requests
    if (lowerMessage.contains('help') || lowerMessage.contains('how') || lowerMessage.contains('what')) {
      if (lowerMessage.contains('help') || lowerMessage.contains('how can you')) {
        return "I can help you with:\n"
            "• Understanding form fields\n"
            "• Explaining what information is needed\n"
            "• Guiding you through the form\n\n"
            "What specific part of the form do you need help with?";
      }
      // For "what" questions, check if it's form-related
      if (lowerMessage.contains('what is') || lowerMessage.contains('what are')) {
        return "I can help explain form fields and what information is needed. Which field would you like to know more about?";
      }
    }

    // Form-related questions
    if (lowerMessage.contains('field') || lowerMessage.contains('question') || 
        lowerMessage.contains('form') || lowerMessage.contains('fill')) {
      return "I can help you understand and fill out the form fields. Which specific field or question do you need help with?";
    }

    // Confirmation responses
    if (lowerMessage.contains('yes') || lowerMessage.contains('ok') || lowerMessage.contains('sure') ||
        lowerMessage.contains('correct') || lowerMessage.contains('right')) {
      return "Great! Is there anything else about the form you'd like help with?";
    }

    if (lowerMessage.contains('no') || lowerMessage.contains('not') || lowerMessage.contains('wrong')) {
      return "No problem! Feel free to ask if you need help with any form fields.";
    }

    // Gratitude
    if (lowerMessage.contains('thank') || lowerMessage.contains('thanks')) {
      return "You're welcome! Let me know if you need any more help with the form.";
    }

    // Off-topic detection - redirect to form assistance
    if (lowerMessage.length < 3 || 
        (!lowerMessage.contains('form') && 
         !lowerMessage.contains('field') && 
         !lowerMessage.contains('help') &&
         !lowerMessage.contains('what') &&
         !lowerMessage.contains('how') &&
         !lowerMessage.contains('fill') &&
         !lowerMessage.contains('question'))) {
      return "I'm here to help you with form filling. Could you tell me which part of the form you need assistance with?";
    }

    // Default response - stay focused on form
    final defaultResponse = "I can help you with the form. What specific question or field would you like assistance with?";
    debugPrint('Selected: Default response');
    debugPrint('Response: $defaultResponse');
    debugPrint('=== END FALLBACK RESPONSE GENERATOR ===');
    print('Selected: Default response');
    print('Response: $defaultResponse');
    print('=== END FALLBACK RESPONSE GENERATOR ===');
    return defaultResponse;
  }

  String _getFieldSpecificResponse(String fieldName, String userMessage) {
    final responses = {
      'Full Name': "I found 'Rajesh Sharma' in your documents. Should I fill it in?",
      'Email': "I detected 'rajesh@email.com' from your uploaded documents. Would you like to use this?",
      'Phone': "I found '+91 9876543210' in your documents. Should I add it?",
      'Address': "I can help you fill in your address. What address would you like to use?",
      'Date of Birth': "I found your date of birth in the documents. Should I auto-fill it?",
    };

    return responses[fieldName] ?? 
        "I can help you with the '$fieldName' field. What information would you like to enter?";
  }

  String _generateIntelligentResponse(String userMessage) {
    // This method is no longer used but kept for backward compatibility
    return "I can help you with the form. What specific question or field would you like assistance with?";
  }

  // Simulate field extraction from documents
  Future<Map<String, dynamic>> extractFieldsFromDocument(String documentPath) async {
    await Future.delayed(const Duration(seconds: 2));
    
    // In production, this would use OCR and AI to extract data
    return {
      'Full Name': 'Rajesh Sharma',
      'Email': 'rajesh@email.com',
      'Phone': '+91 9876543210',
      'Date of Birth': '1990-05-15',
      'Address': '123 Main Street, New Delhi',
    };
  }

  // Calculate confidence score for auto-filled data
  double calculateConfidence(Map<String, dynamic> extractedData) {
    // Simulate confidence calculation
    return 0.85 + (Random().nextDouble() * 0.15); // 85-100% confidence
  }
}

