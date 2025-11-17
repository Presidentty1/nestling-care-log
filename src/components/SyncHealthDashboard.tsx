import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Progress } from '@/components/ui/progress';
import { Badge } from '@/components/ui/badge';
import { Cloud, CloudOff, RefreshCw, CheckCircle2, AlertCircle, Clock } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';

interface SyncHealthDashboardProps {
  isOnline: boolean;
  isSyncing: boolean;
  pendingCount: number;
  lastSyncTime?: string;
  failedCount: number;
  pendingByType: Record<string, number>;
  syncHistory: Array<{ timestamp: string; count: number; success: boolean }>;
  onSyncNow: () => void;
}

export function SyncHealthDashboard({
  isOnline,
  isSyncing,
  pendingCount,
  lastSyncTime,
  failedCount,
  pendingByType,
  syncHistory,
  onSyncNow,
}: SyncHealthDashboardProps) {
  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <div>
            <CardTitle className="flex items-center gap-2">
              {isOnline ? (
                <Cloud className="h-5 w-5 text-green-500" />
              ) : (
                <CloudOff className="h-5 w-5 text-muted-foreground" />
              )}
              Sync Status
            </CardTitle>
            <CardDescription>
              {isOnline ? 'Connected to cloud' : 'Working offline'}
            </CardDescription>
          </div>
          <Badge variant={pendingCount > 0 ? 'secondary' : 'outline'}>
            {pendingCount} pending
          </Badge>
        </div>
      </CardHeader>
      <CardContent className="space-y-4">
        {/* Sync Status */}
        <div className="space-y-2">
          <div className="flex items-center justify-between text-sm">
            <span className="text-muted-foreground">Last sync</span>
            <span className="font-medium">
              {lastSyncTime ? formatDistanceToNow(new Date(lastSyncTime), { addSuffix: true }) : 'Never'}
            </span>
          </div>
          
          {pendingCount > 0 && (
            <div className="space-y-1">
              <div className="flex items-center justify-between text-sm">
                <span className="text-muted-foreground">Progress</span>
                <span className="font-medium">
                  {isSyncing ? 'Syncing...' : 'Pending'}
                </span>
              </div>
              {isSyncing && <Progress value={50} className="h-2" />}
            </div>
          )}
        </div>

        {/* Pending by Type */}
        {pendingCount > 0 && (
          <div className="space-y-2">
            <p className="text-sm font-medium">Pending Events</p>
            <div className="grid grid-cols-2 gap-2">
              {Object.entries(pendingByType).map(([type, count]) => (
                count > 0 && (
                  <div key={type} className="flex items-center justify-between text-sm bg-muted/50 rounded-md px-3 py-2">
                    <span className="capitalize">{type}</span>
                    <Badge variant="secondary" className="h-5 text-xs">{count}</Badge>
                  </div>
                )
              ))}
            </div>
          </div>
        )}

        {/* Failed Count */}
        {failedCount > 0 && (
          <div className="flex items-center gap-2 text-sm text-destructive bg-destructive/10 rounded-md p-3">
            <AlertCircle className="h-4 w-4" />
            <span>{failedCount} events failed to sync</span>
          </div>
        )}

        {/* Sync Now Button */}
        <Button
          onClick={onSyncNow}
          disabled={!isOnline || isSyncing || pendingCount === 0}
          className="w-full"
        >
          {isSyncing ? (
            <>
              <RefreshCw className="mr-2 h-4 w-4 animate-spin" />
              Syncing...
            </>
          ) : (
            <>
              <RefreshCw className="mr-2 h-4 w-4" />
              Sync Now
            </>
          )}
        </Button>

        {/* Sync History */}
        {syncHistory.length > 0 && (
          <div className="space-y-2">
            <p className="text-sm font-medium">Recent Syncs</p>
            <div className="space-y-1">
              {syncHistory.slice(0, 5).map((sync, index) => (
                <div key={index} className="flex items-center justify-between text-xs text-muted-foreground">
                  <div className="flex items-center gap-2">
                    {sync.success ? (
                      <CheckCircle2 className="h-3 w-3 text-green-500" />
                    ) : (
                      <AlertCircle className="h-3 w-3 text-destructive" />
                    )}
                    <span>{sync.count} events</span>
                  </div>
                  <span className="flex items-center gap-1">
                    <Clock className="h-3 w-3" />
                    {formatDistanceToNow(new Date(sync.timestamp), { addSuffix: true })}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}
      </CardContent>
    </Card>
  );
}
