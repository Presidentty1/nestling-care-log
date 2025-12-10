import { useState, useRef, useEffect } from 'react';
import { useQuery } from '@tanstack/react-query';
import type { Baby } from '@/lib/types';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { BabySwitcher } from '@/components/BabySwitcher';
import { QuickQuestions } from '@/components/QuickQuestions';
import { MedicalDisclaimer } from '@/components/MedicalDisclaimer';
import { MobileNav } from '@/components/MobileNav';
import { useAIChat } from '@/hooks/useAIChat';
import { ArrowLeft, Send, Loader2, Bot, User, AlertCircle, Settings } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { aiPreferencesService } from '@/services/aiPreferencesService';
import { useAuth } from '@/hooks/useAuth';
import { babyService } from '@/services/babyService';

export default function AIAssistant() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [selectedBabyId, setSelectedBabyId] = useState<string | null>(null);
  const [input, setInput] = useState('');
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const [isSwitcherOpen, setIsSwitcherOpen] = useState(false);

  const { data: aiEnabled } = useQuery({
    queryKey: ['ai-preferences', user?.id],
    queryFn: async () => {
      if (!user) return false;
      return await aiPreferencesService.canUseAI(user.id);
    },
    enabled: !!user,
  });

  const { data: babies } = useQuery({
    queryKey: ['babies'],
    queryFn: async () => {
      return await babyService.getUserBabies();
    },
  });

  if (babies && babies.length > 0 && !selectedBabyId) {
    setSelectedBabyId(babies[0].id);
    localStorage.setItem('selected_baby_id', babies[0].id);
  }

  const selectedBaby = babies?.find(b => b.id === selectedBabyId) || null;

  const { messages, isLoading, sendMessage, error: chatError } = useAIChat(selectedBaby);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  const handleSend = async () => {
    if (!input.trim() || isLoading) return;

    try {
      await sendMessage(input);
      setInput('');
    } catch (error) {
      console.error('Send message error:', error);
      if (error instanceof Error && error.message?.includes('not found')) {
        // AI function not available
      } else if (error instanceof Error && error.message?.includes('network')) {
        // Network error already handled by hook
      }
    }
  };

  const handleQuickQuestion = (question: string) => {
    sendMessage(question);
  };

  return (
    <div className='min-h-screen bg-background pb-20'>
      <div className='sticky top-0 z-10 bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60 border-b'>
        <div className='container mx-auto p-4'>
          <div className='flex items-center gap-4 mb-4'>
            <Button onClick={() => navigate(-1)} variant='ghost' size='sm'>
              <ArrowLeft className='h-4 w-4' />
            </Button>
            <div>
              <h1 className='text-2xl font-bold'>AI Assistant</h1>
              <p className='text-sm text-muted-foreground'>Ask questions about baby care</p>
            </div>
          </div>
          {babies && babies.length > 1 && (
            <Button
              onClick={() => setIsSwitcherOpen(true)}
              variant='outline'
              size='sm'
              className='gap-2'
            >
              {selectedBaby?.name}
            </Button>
          )}
        </div>
      </div>

      <div className='container mx-auto p-4 max-w-3xl'>
        {/* Trust messaging banner */}
        <Alert className='mb-4 border-primary/20 bg-primary/5'>
          <AlertCircle className='h-4 w-4 text-primary' />
          <AlertDescription className='text-primary font-medium'>
            General guidance only; not a replacement for your pediatrician
          </AlertDescription>
        </Alert>

        <MedicalDisclaimer
          variant='ai'
          className='sticky top-0 z-10 bg-background/95 backdrop-blur'
        />

        {aiEnabled === false && (
          <Alert variant='destructive' className='mb-4'>
            <AlertCircle className='h-4 w-4' />
            <AlertDescription className='flex items-center justify-between'>
              <span>
                AI Assistant is disabled. Enable AI features in Settings to ask questions.
              </span>
              <Button
                variant='ghost'
                size='sm'
                onClick={() => navigate('/settings/ai-data-sharing')}
                className='ml-2'
              >
                <Settings className='h-4 w-4 mr-1' />
                Settings
              </Button>
            </AlertDescription>
          </Alert>
        )}

        {messages.length === 0 && (
          <div className='space-y-4 mb-6'>
            <Card className='p-6 text-center'>
              <Bot className='h-12 w-12 mx-auto mb-4 text-primary' />
              <h3 className='font-semibold mb-2 text-foreground'>Hi! I'm here to help</h3>
              <p className='text-caption text-muted-foreground max-w-md mx-auto'>
                Ask me anything about baby care, feeding schedules, sleep tips, or developmental
                milestones. I'm here to support you.
              </p>
            </Card>

            <QuickQuestions onQuestionSelect={handleQuickQuestion} />
          </div>
        )}

        {chatError && (
          <Alert variant='destructive' className='mb-4'>
            <AlertCircle className='h-4 w-4' />
            <AlertDescription>
              Having trouble connecting. Check your internet and try asking again.
            </AlertDescription>
          </Alert>
        )}

        <div className='space-y-4 mb-4'>
          {messages.map(message => (
            <div
              key={message.id}
              className={`flex gap-3 ${message.role === 'user' ? 'justify-end' : 'justify-start'}`}
            >
              {message.role === 'assistant' && (
                <div className='flex-shrink-0'>
                  <div className='w-8 h-8 rounded-full bg-primary flex items-center justify-center'>
                    <Bot className='h-4 w-4 text-primary-foreground' />
                  </div>
                </div>
              )}

              <Card
                className={`p-4 max-w-[80%] ${message.role === 'user' ? 'bg-primary text-primary-foreground' : ''}`}
              >
                <p className='text-sm whitespace-pre-wrap'>{message.content}</p>
              </Card>

              {message.role === 'user' && (
                <div className='flex-shrink-0'>
                  <div className='w-8 h-8 rounded-full bg-muted flex items-center justify-center'>
                    <User className='h-4 w-4' />
                  </div>
                </div>
              )}
            </div>
          ))}

          {isLoading && (
            <div className='flex gap-3 justify-start'>
              <div className='flex-shrink-0'>
                <div className='w-8 h-8 rounded-full bg-primary flex items-center justify-center'>
                  <Bot className='h-4 w-4 text-primary-foreground' />
                </div>
              </div>
              <Card className='p-4'>
                <Loader2 className='h-4 w-4 animate-spin' />
              </Card>
            </div>
          )}

          <div ref={messagesEndRef} />
        </div>
      </div>

      <div className='fixed bottom-16 left-0 right-0 bg-background border-t p-4'>
        <div className='container mx-auto max-w-3xl flex gap-2'>
          <Input
            value={input}
            onChange={e => setInput(e.target.value)}
            onKeyPress={e => e.key === 'Enter' && handleSend()}
            placeholder={
              aiEnabled === false ? 'Enable AI features to chat...' : 'Ask a question...'
            }
            disabled={isLoading || aiEnabled === false}
          />
          <Button onClick={handleSend} disabled={!input.trim() || isLoading || aiEnabled === false}>
            {isLoading ? (
              <Loader2 className='h-4 w-4 animate-spin' />
            ) : (
              <Send className='h-4 w-4' />
            )}
          </Button>
        </div>
      </div>

      <MobileNav />
    </div>
  );
}
