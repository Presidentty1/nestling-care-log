import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { Baby, Utensils, Moon, Thermometer, Wind, AlertCircle } from 'lucide-react';
import { toast } from 'sonner';

interface CryAnalysisResultProps {
  result: {
    category: string;
    confidence: number;
    reasoning: string;
    suggestions: string[];
    contextInfo?: {
      lastFeed?: string;
      lastNap?: string;
      lastDiaper?: string;
    };
  };
  onFeedback: (helpful: boolean) => void;
}

export function CryAnalysisResult({ result, onFeedback }: CryAnalysisResultProps) {
  const getCategoryIcon = (category: string) => {
    const icons: { [key: string]: any } = {
      hungry: Utensils,
      tired: Moon,
      discomfort: AlertCircle,
      pain: Thermometer,
      gas: Wind,
    };
    const Icon = icons[category.toLowerCase()] || Baby;
    return <Icon className="h-8 w-8" />;
  };

  const getCategoryColor = (category: string) => {
    const colors: { [key: string]: string } = {
      hungry: 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-200',
      tired: 'bg-purple-100 text-purple-700 dark:bg-purple-900 dark:text-purple-200',
      discomfort: 'bg-yellow-100 text-yellow-700 dark:bg-yellow-900 dark:text-yellow-200',
      pain: 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-200',
      gas: 'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-200',
    };
    return colors[category.toLowerCase()] || 'bg-gray-100 text-gray-700 dark:bg-gray-800 dark:text-gray-200';
  };

  return (
    <div className="space-y-4">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-3">
            <div className={`p-3 rounded-full ${getCategoryColor(result.category)}`}>
              {getCategoryIcon(result.category)}
            </div>
            <div>
              <div className="capitalize">{result.category}</div>
              <Badge variant="secondary" className="mt-1">
                {result.confidence}% confident
              </Badge>
            </div>
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <h4 className="font-semibold mb-2">Analysis</h4>
            <p className="text-sm text-muted-foreground">{result.reasoning}</p>
          </div>

          {result.suggestions && result.suggestions.length > 0 && (
            <div>
              <h4 className="font-semibold mb-2">Suggestions</h4>
              <ul className="space-y-2">
                {result.suggestions.map((suggestion, idx) => (
                  <li key={idx} className="text-sm text-muted-foreground flex items-start gap-2">
                    <span className="text-primary">•</span>
                    <span>{suggestion}</span>
                  </li>
                ))}
              </ul>
            </div>
          )}

          {result.contextInfo && (
            <div className="p-3 bg-muted rounded-lg text-sm">
              <h4 className="font-semibold mb-2">Recent Activity</h4>
              {result.contextInfo.lastFeed && (
                <p className="text-muted-foreground">Last feed: {result.contextInfo.lastFeed}</p>
              )}
              {result.contextInfo.lastNap && (
                <p className="text-muted-foreground">Last nap: {result.contextInfo.lastNap}</p>
              )}
              {result.contextInfo.lastDiaper && (
                <p className="text-muted-foreground">Last diaper: {result.contextInfo.lastDiaper}</p>
              )}
            </div>
          )}
        </CardContent>
      </Card>

      <Card className="p-4">
        <h4 className="font-semibold mb-3">Was this helpful?</h4>
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => onFeedback(true)} className="flex-1">
            👍 Yes, helpful
          </Button>
          <Button variant="outline" onClick={() => onFeedback(false)} className="flex-1">
            👎 Not helpful
          </Button>
        </div>
      </Card>

      <Alert>
        <AlertCircle className="h-4 w-4" />
        <AlertDescription>
          This is AI-powered guidance only, not medical advice. Contact your pediatrician if you have concerns about your baby's health.
        </AlertDescription>
      </Alert>
    </div>
  );
}
