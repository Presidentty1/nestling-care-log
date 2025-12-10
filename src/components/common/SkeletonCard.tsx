import { Card, CardContent } from '@/components/ui/card';

interface SkeletonCardProps {
  height?: string;
  showIcon?: boolean;
}

export function SkeletonCard({ height = 'h-20', showIcon = false }: SkeletonCardProps) {
  return (
    <Card className='animate-pulse'>
      <CardContent className={`p-4 ${height}`}>
        <div className='flex items-center gap-3'>
          {showIcon && <div className='flex-shrink-0 w-5 h-5 bg-muted rounded-full' />}
          <div className='flex-1 space-y-2'>
            <div className='h-4 bg-muted rounded w-3/4' />
            <div className='h-3 bg-muted rounded w-1/2' />
          </div>
        </div>
      </CardContent>
    </Card>
  );
}

export function SkeletonSummaryChips() {
  return (
    <div className='grid grid-cols-3 gap-3'>
      {[1, 2, 3].map(i => (
        <Card key={i} className='animate-pulse'>
          <CardContent className='p-3 text-center'>
            <div className='h-5 w-5 mx-auto mb-1 bg-muted rounded-full' />
            <div className='h-3 bg-muted rounded w-12 mx-auto mb-1' />
            <div className='h-5 bg-muted rounded w-8 mx-auto' />
          </CardContent>
        </Card>
      ))}
    </div>
  );
}

export function SkeletonTimeline() {
  return (
    <div className='space-y-2'>
      {[1, 2, 3].map(i => (
        <SkeletonCard key={i} showIcon />
      ))}
    </div>
  );
}
