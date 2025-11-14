import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { MessageCircle } from 'lucide-react';

interface QuickQuestionsProps {
  onQuestionSelect: (question: string) => void;
}

const questions = [
  "How much sleep should my baby get?",
  "When should I start solid foods?",
  "How can I help my baby sleep through the night?",
  "What are normal developmental milestones?",
  "How often should my baby eat?",
  "When should I worry about crying?",
];

export function QuickQuestions({ onQuestionSelect }: QuickQuestionsProps) {
  return (
    <Card className="p-4">
      <div className="flex items-center gap-2 mb-3">
        <MessageCircle className="h-4 w-4 text-primary" />
        <h3 className="font-medium">Quick Questions</h3>
      </div>
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
        {questions.map((question, idx) => (
          <Button
            key={idx}
            variant="outline"
            className="justify-start text-left h-auto py-3"
            onClick={() => onQuestionSelect(question)}
          >
            {question}
          </Button>
        ))}
      </div>
    </Card>
  );
}