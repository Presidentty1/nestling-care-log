import { Card, CardContent } from '@/components/ui/card';
import { Zap, Brain, Users, Shield } from 'lucide-react';
import { MESSAGING } from '@/lib/messaging';

export function ValuePreview() {
  const benefits = [
    {
      icon: Zap,
      title: MESSAGING.valueProp.speed.title,
      description: MESSAGING.valueProp.speed.long,
      color: 'text-event-feed',
      bgColor: 'bg-event-feed/10',
    },
    {
      icon: Brain,
      title: MESSAGING.valueProp.ai.title,
      description: MESSAGING.valueProp.ai.long,
      color: 'text-primary',
      bgColor: 'bg-primary/10',
    },
    {
      icon: Users,
      title: MESSAGING.valueProp.sync.title,
      description: MESSAGING.valueProp.sync.long,
      color: 'text-secondary',
      bgColor: 'bg-secondary/10',
    },
  ];

  return (
    <div className='space-y-6 animate-fade-in'>
      {/* Visual demo animation */}
      <div className='relative'>
        <Card className='border-2 border-primary/20 overflow-hidden'>
          <CardContent className='p-6 bg-gradient-to-br from-background to-primary/5'>
            <div className='text-center mb-4'>
              <p className='text-sm font-medium text-muted-foreground'>Quick logging in action</p>
            </div>
            <div className='grid grid-cols-2 gap-3'>
              {['Feed', 'Sleep', 'Diaper', 'Tummy'].map((label, index) => (
                <div
                  key={label}
                  className='h-20 rounded-lg border-2 border-border bg-surface flex items-center justify-center font-medium transition-all duration-300 hover:border-primary/50'
                  style={{
                    animationDelay: `${index * 0.1}s`,
                  }}
                >
                  {label}
                </div>
              ))}
            </div>
            <div className='mt-4 text-center'>
              <p className='text-xs text-primary font-medium'>Just tap and go - that's it!</p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Key benefits */}
      <div className='space-y-4'>
        {benefits.map((benefit, index) => (
          <Card
            key={benefit.title}
            className='border-2 border-border hover:border-primary/30 transition-all duration-300'
            style={{
              animationDelay: `${(index + 1) * 0.15}s`,
            }}
          >
            <CardContent className='p-4'>
              <div className='flex items-start gap-4'>
                <div
                  className={`w-12 h-12 rounded-xl ${benefit.bgColor} flex items-center justify-center shrink-0`}
                >
                  <benefit.icon className={`h-6 w-6 ${benefit.color}`} />
                </div>
                <div className='flex-1 min-w-0'>
                  <h3 className='font-semibold text-base mb-1'>{benefit.title}</h3>
                  <p className='text-sm text-muted-foreground leading-relaxed'>
                    {benefit.description}
                  </p>
                </div>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Privacy assurance */}
      <Card className='bg-primary/5 border-primary/20'>
        <CardContent className='p-4'>
          <div className='flex items-start gap-3'>
            <Shield className='h-5 w-5 text-primary shrink-0 mt-0.5' />
            <div className='flex-1'>
              <p className='text-sm font-medium mb-1'>{MESSAGING.privacy.short}</p>
              <p className='text-xs text-muted-foreground'>{MESSAGING.privacy.long}</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
