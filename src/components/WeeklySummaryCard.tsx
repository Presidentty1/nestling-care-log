import { format } from 'date-fns';
import { Card } from '@/components/ui/card';

interface Baby {
  name: string;
}

interface WeeklySummaryStats {
  totalSleepHours: number;
  totalFeeds: number;
  totalDiapers: number;
  avgNapsPerDay: number;
}

interface WeeklySummaryCardProps {
  baby: Baby;
  weekStart: Date;
  stats: WeeklySummaryStats;
  cardId: string;
}

function StatBox({ icon, label, value }: { icon: string; label: string; value: string | number }) {
  return (
    <div className="text-center p-4 rounded-xl bg-gradient-to-br from-background to-accent/20">
      <div className="text-5xl mb-3">{icon}</div>
      <div className="text-3xl font-bold mb-1">{value}</div>
      <div className="text-sm text-muted-foreground uppercase tracking-wide">{label}</div>
    </div>
  );
}

export function WeeklySummaryCard({ baby, weekStart, stats, cardId }: WeeklySummaryCardProps) {
  const weekEnd = new Date(weekStart.getTime() + 6 * 24 * 60 * 60 * 1000);

  return (
    <div 
      id={cardId}
      className="w-[600px] h-[600px] bg-gradient-to-br from-blue-50 to-purple-50 p-12 flex items-center justify-center"
      style={{ fontFamily: 'system-ui, -apple-system, sans-serif' }}
    >
      <Card className="w-full h-full p-8 border-none shadow-2xl bg-white">
        <div className="text-center mb-8">
          <h2 className="text-3xl font-bold mb-2">{baby.name}'s Week</h2>
          <p className="text-lg text-muted-foreground">
            {format(weekStart, 'MMM d')} - {format(weekEnd, 'MMM d, yyyy')}
          </p>
        </div>
        
        <div className="grid grid-cols-2 gap-6">
          <StatBox icon="😴" label="Sleep" value={`${stats.totalSleepHours}h`} />
          <StatBox icon="🍼" label="Feeds" value={stats.totalFeeds} />
          <StatBox icon="🧷" label="Diapers" value={stats.totalDiapers} />
          <StatBox icon="☀️" label="Avg Naps" value={stats.avgNapsPerDay.toFixed(1)} />
        </div>
        
        <div className="pt-6 mt-8 border-t text-center">
          <p className="text-sm text-muted-foreground font-medium">
            Tracked with Nestling
          </p>
        </div>
      </Card>
    </div>
  );
}
