import { useState } from 'react';
import { useMutation } from '@tanstack/react-query';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { useToast } from '@/hooks/use-toast';
import { MessageSquare, Star } from 'lucide-react';
import { feedbackService } from '@/services/feedbackService';

export default function Feedback() {
  const { toast } = useToast();
  const [feedback, setFeedback] = useState({
    type: 'general' as 'bug' | 'feature_request' | 'general' | 'rating',
    subject: '',
    message: '',
    rating: 0,
  });

  const submitMutation = useMutation({
    mutationFn: async () => {
      await feedbackService.submitFeedback({
        feedback_type: feedback.type,
        subject: feedback.subject,
        message: feedback.message,
        rating: feedback.rating > 0 ? feedback.rating : null,
      });
    },
    onSuccess: () => {
      toast({ title: 'Thank you for your feedback!' });
      setFeedback({ type: 'general', subject: '', message: '', rating: 0 });
    },
    onError: (error: any) => {
      toast({
        title: 'Failed to submit feedback',
        description: error.message,
        variant: 'destructive',
      });
    },
  });

  return (
    <div className="min-h-screen bg-background p-4">
      <div className="max-w-2xl mx-auto space-y-6">
        <h1 className="text-3xl font-bold">Feedback</h1>

        <Card className="p-6 text-center space-y-4">
          <MessageSquare className="w-16 h-16 mx-auto text-primary" />
          <h2 className="text-2xl font-bold">We'd Love to Hear From You</h2>
          <p className="text-muted-foreground">
            Your feedback helps us improve Nestling for everyone
          </p>
        </Card>

        <Card className="p-6 space-y-4">
          <div>
            <Label>Feedback Type</Label>
            <Select
              value={feedback.type}
              onValueChange={(value) => setFeedback({ ...feedback, type: value })}
            >
              <SelectTrigger>
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="bug">Bug Report</SelectItem>
                <SelectItem value="feature_request">Feature Request</SelectItem>
                <SelectItem value="general">General Feedback</SelectItem>
                <SelectItem value="rating">App Rating</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {feedback.type === 'rating' && (
            <div>
              <Label>Rating</Label>
              <div className="flex gap-2 mt-2">
                {[1, 2, 3, 4, 5].map((star) => (
                  <button
                    key={star}
                    onClick={() => setFeedback({ ...feedback, rating: star })}
                    className="p-0 border-0 bg-transparent"
                  >
                    <Star
                      className={`w-8 h-8 ${
                        star <= feedback.rating ? 'fill-yellow-400 text-yellow-400' : 'text-gray-300'
                      }`}
                    />
                  </button>
                ))}
              </div>
            </div>
          )}

          <div>
            <Label>Subject</Label>
            <Input
              value={feedback.subject}
              onChange={(e) => setFeedback({ ...feedback, subject: e.target.value })}
              placeholder="Brief summary..."
            />
          </div>

          <div>
            <Label>Message</Label>
            <Textarea
              value={feedback.message}
              onChange={(e) => setFeedback({ ...feedback, message: e.target.value })}
              placeholder="Tell us more..."
              rows={6}
            />
          </div>

          <Button
            className="w-full"
            onClick={() => submitMutation.mutate()}
            disabled={submitMutation.isPending || !feedback.message}
          >
            Submit Feedback
          </Button>
        </Card>
      </div>
    </div>
  );
}