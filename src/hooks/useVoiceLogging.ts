import { useState, useCallback } from 'react';
import { useToast } from './use-toast';
import { parseVoiceCommand } from '@/lib/voiceParser';

export function useVoiceLogging() {
  const { toast } = useToast();
  const [isListening, setIsListening] = useState(false);
  const [transcript, setTranscript] = useState('');

  const startListening = useCallback(async () => {
    try {
      // Check if Web Speech API is available
      if (!('webkitSpeechRecognition' in window) && !('SpeechRecognition' in window)) {
        toast({
          title: 'Not Supported',
          description: 'Voice recognition is not supported in this browser.',
          variant: 'destructive',
        });
        return null;
      }

      const SpeechRecognition = (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
      const recognition = new SpeechRecognition();

      recognition.continuous = false;
      recognition.interimResults = false;
      recognition.lang = 'en-US';

      setIsListening(true);
      setTranscript('');

      return new Promise<string>((resolve, reject) => {
        recognition.onresult = (event: any) => {
          const transcript = event.results[0][0].transcript;
          setTranscript(transcript);
          setIsListening(false);
          resolve(transcript);
        };

        recognition.onerror = (event: any) => {
          console.error('Speech recognition error:', event.error);
          setIsListening(false);
          toast({
            title: 'Recognition Error',
            description: 'Could not recognize speech. Please try again.',
            variant: 'destructive',
          });
          reject(event.error);
        };

        recognition.onend = () => {
          setIsListening(false);
        };

        recognition.start();
      });
    } catch (error) {
      console.error('Voice logging error:', error);
      setIsListening(false);
      toast({
        title: 'Error',
        description: 'Failed to start voice recognition.',
        variant: 'destructive',
      });
      return null;
    }
  }, [toast]);

  const stopListening = useCallback(() => {
    setIsListening(false);
  }, []);

  return {
    isListening,
    transcript,
    startListening,
    stopListening,
    parseCommand: parseVoiceCommand,
  };
}