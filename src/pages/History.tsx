import { MobileNav } from '@/components/MobileNav';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

export default function History() {
  return (
    <div className="min-h-screen bg-surface pb-20">
      <div className="max-w-2xl mx-auto p-4 space-y-4">
        <h1 className="text-2xl font-bold">History</h1>
        
        <Card>
          <CardHeader>
            <CardTitle>Coming Soon</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-muted-foreground">
              View past events, summaries, and share reports with your doctor.
            </p>
          </CardContent>
        </Card>
      </div>

      <MobileNav />
    </div>
  );
}
