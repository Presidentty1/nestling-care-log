import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Baby, Zap, Brain, Users, Shield, ArrowRight, Check, Star, Quote } from 'lucide-react';
import { useState } from 'react';
import { InteractiveLandingDemo } from '@/components/InteractiveLandingDemo';

export default function Landing() {
  const navigate = useNavigate();
  const [animationPhase, setAnimationPhase] = useState(0);

  // Simple animation cycle for the demo
  useState(() => {
    const interval = setInterval(() => {
      setAnimationPhase((prev) => (prev + 1) % 3);
    }, 2000);
    return () => clearInterval(interval);
  });

  const features = [
    {
      icon: Zap,
      title: 'Ultra-Fast Logging',
      description: 'Track feeds, diapers, and sleep in just 2 taps. Designed for tired parents at 3 AM.',
      color: 'text-event-feed',
      bgColor: 'bg-event-feed/10',
    },
    {
      icon: Brain,
      title: 'AI-Powered Insights',
      description: 'Get smart nap predictions, pattern detection, and personalized recommendations.',
      color: 'text-primary',
      bgColor: 'bg-primary/10',
    },
    {
      icon: Users,
      title: 'Multi-Caregiver Sync',
      description: 'Share with your partner, grandparents, or nanny. Everyone stays in sync, instantly.',
      color: 'text-secondary',
      bgColor: 'bg-secondary/10',
    },
  ];

  const benefits = [
    'Works completely offline',
    'No ads, ever',
    'Privacy-first design',
    'Export data for doctor visits',
    'Smart reminders',
    'Beautiful dark mode',
  ];

  const testimonials = [
    {
      quote: "Finally, a baby tracker that doesn't make me feel more overwhelmed! The 2-tap logging is a lifesaver at 3 AM.",
      author: "Sarah M.",
      role: "Mom of 3-month-old",
      rating: 5,
    },
    {
      quote: "The AI nap predictions actually work. It learned my baby's patterns in just 3 days and now I can plan my day around naps.",
      author: "Mike T.",
      role: "Dad of 5-month-old",
      rating: 5,
    },
    {
      quote: "Syncing with my partner changed everything. No more texting 'when did baby last eat?' every handoff.",
      author: "Jessica L.",
      role: "Mom of twins",
      rating: 5,
    },
  ];

  return (
    <div className="min-h-screen bg-gradient-to-b from-background via-background to-primary/5">
      {/* Hero Section */}
      <div className="max-w-6xl mx-auto px-4 pt-8 pb-16">
        {/* Header */}
        <div className="flex items-center justify-between mb-12">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-primary rounded-xl flex items-center justify-center shadow-md">
              <Baby className="h-6 w-6 text-primary-foreground" />
            </div>
            <span className="font-display text-xl">Nestling</span>
          </div>
          <Button
            variant="ghost"
            onClick={() => navigate('/auth')}
            className="text-base"
          >
            Sign In
          </Button>
        </div>

        {/* Hero Content */}
        <div className="text-center max-w-3xl mx-auto mb-16">
          <div className="inline-flex items-center gap-2 bg-primary/10 text-primary px-4 py-2 rounded-full text-sm font-medium mb-6 animate-fade-in">
            <Zap className="h-4 w-4" />
            The fastest baby tracker
          </div>
          
          <h1 className="text-4xl md:text-5xl lg:text-6xl font-bold leading-tight mb-6 animate-fade-in">
            Stop guessing.
            <br />
            Start <span className="text-primary">knowing</span>.
          </h1>

          <p className="text-lg md:text-xl text-muted-foreground mb-8 animate-fade-in max-w-2xl mx-auto">
            Track baby care in 2 taps. Get AI predictions for naps and feeds. 
            Sync instantly with your partner. Built for 3 AM.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center animate-fade-in mb-8">
            <Button
              size="lg"
              onClick={() => navigate('/auth')}
              className="text-lg h-14 px-8 shadow-lg hover:shadow-xl transition-shadow"
            >
              Get Started Free
              <ArrowRight className="ml-2 h-5 w-5" />
            </Button>
            <p className="text-sm text-muted-foreground">
              No credit card required • Free forever
            </p>
          </div>

          {/* Pain points - emotional connection */}
          <div className="grid sm:grid-cols-3 gap-4 max-w-3xl mx-auto text-sm">
            <div className="p-4 rounded-lg bg-surface border border-border">
              <p className="text-muted-foreground">
                "When did baby last eat?" 
                <br />
                <span className="text-primary font-medium">→ Always in sync</span>
              </p>
            </div>
            <div className="p-4 rounded-lg bg-surface border border-border">
              <p className="text-muted-foreground">
                "When's the next nap?"
                <br />
                <span className="text-primary font-medium">→ AI predicts it</span>
              </p>
            </div>
            <div className="p-4 rounded-lg bg-surface border border-border">
              <p className="text-muted-foreground">
                "Too tired to remember"
                <br />
                <span className="text-primary font-medium">→ Just 2 taps</span>
              </p>
            </div>
          </div>

          {/* Social Proof */}
          <div className="mt-8 flex flex-col items-center justify-center gap-3">
            <div className="flex items-center gap-2 text-sm text-muted-foreground">
              <div className="flex -space-x-2">
                {[1, 2, 3, 4, 5].map((i) => (
                  <div
                    key={i}
                    className="w-8 h-8 rounded-full bg-gradient-to-br from-primary/20 to-primary/40 border-2 border-background flex items-center justify-center"
                  >
                    <Baby className="h-4 w-4 text-primary" />
                  </div>
                ))}
              </div>
              <span className="font-medium">5,000+ happy parents</span>
            </div>
            <div className="flex items-center gap-1">
              {[1, 2, 3, 4, 5].map((i) => (
                <Star key={i} className="h-4 w-4 fill-primary text-primary" />
              ))}
              <span className="ml-2 text-sm text-muted-foreground">4.9/5.0 rating</span>
            </div>
          </div>
        </div>

        {/* Interactive Demo */}
        <div className="max-w-2xl mx-auto mb-20">
          <InteractiveLandingDemo />
        </div>

        {/* Key Features */}
        <div className="mb-20">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-4">
            Built for real parents
          </h2>
          <p className="text-center text-lg text-muted-foreground mb-12 max-w-2xl mx-auto">
            We know you're tired. We know you're overwhelmed. That's why we made this ridiculously simple.
          </p>
          <div className="grid md:grid-cols-3 gap-8">
            {features.map((feature) => (
              <Card
                key={feature.title}
                variant="elevated"
                className="text-center hover:shadow-xl transition-shadow"
              >
                <CardContent className="p-8">
                  <div
                    className={`w-16 h-16 rounded-2xl ${feature.bgColor} flex items-center justify-center mx-auto mb-4`}
                  >
                    <feature.icon className={`h-8 w-8 ${feature.color}`} />
                  </div>
                  <h3 className="text-xl font-semibold mb-3">{feature.title}</h3>
                  <p className="text-muted-foreground">{feature.description}</p>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>

        {/* Benefits Grid */}
        <div className="mb-20">
          <Card variant="emphasis" className="border-2 border-primary/20">
            <CardContent className="p-8 md:p-12">
              <h2 className="text-2xl md:text-3xl font-bold text-center mb-8">
                Everything you need, nothing you don't
              </h2>
              <div className="grid sm:grid-cols-2 md:grid-cols-3 gap-4">
                {benefits.map((benefit) => (
                  <div key={benefit} className="flex items-center gap-3">
                    <div className="w-6 h-6 rounded-full bg-primary flex items-center justify-center shrink-0">
                      <Check className="h-4 w-4 text-primary-foreground" />
                    </div>
                    <span className="text-base">{benefit}</span>
                  </div>
                ))}
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Before/After Section */}
        <div className="mb-20">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-12">
            From chaos to clarity
          </h2>
          <div className="grid md:grid-cols-2 gap-8 max-w-4xl mx-auto">
            {/* Before */}
            <Card className="border-2 border-destructive/20 bg-destructive/5">
              <CardContent className="p-6">
                <h3 className="text-xl font-bold mb-4 text-center">Without Nestling</h3>
                <div className="space-y-3">
                  {[
                    '❌ "When did baby last eat?"',
                    '❌ Constant texting with partner',
                    '❌ Forgetting to track at 3 AM',
                    '❌ Guessing nap times',
                    '❌ Scrambling before doctor visits',
                  ].map((item, i) => (
                    <p key={i} className="text-sm text-muted-foreground">{item}</p>
                  ))}
                </div>
              </CardContent>
            </Card>

            {/* After */}
            <Card className="border-2 border-primary/30 bg-primary/10 shadow-lg">
              <CardContent className="p-6">
                <h3 className="text-xl font-bold mb-4 text-center">With Nestling</h3>
                <div className="space-y-3">
                  {[
                    '✅ Everything logged in 2 taps',
                    '✅ Partner always in sync',
                    '✅ Fast enough for 3 AM',
                    '✅ AI predicts nap times',
                    '✅ Export ready for doctors',
                  ].map((item, i) => (
                    <p key={i} className="text-sm font-medium">{item}</p>
                  ))}
                </div>
              </CardContent>
            </Card>
          </div>
        </div>

        {/* Testimonials Section */}
        <div className="mb-20">
          <h2 className="text-3xl md:text-4xl font-bold text-center mb-4">
            Loved by tired parents everywhere
          </h2>
          <p className="text-center text-muted-foreground mb-12 max-w-2xl mx-auto">
            Real stories from parents who found their sanity with Nestling
          </p>
          <div className="grid md:grid-cols-3 gap-6">
            {testimonials.map((testimonial, index) => (
              <Card key={index} variant="elevated" className="hover:shadow-xl transition-shadow">
                <CardContent className="p-6">
                  <div className="flex gap-1 mb-4">
                    {[...Array(testimonial.rating)].map((_, i) => (
                      <Star key={i} className="h-4 w-4 fill-primary text-primary" />
                    ))}
                  </div>
                  <Quote className="h-8 w-8 text-primary/20 mb-3" />
                  <p className="text-sm leading-relaxed mb-4 italic">
                    "{testimonial.quote}"
                  </p>
                  <div className="border-t border-border pt-4">
                    <p className="font-semibold text-sm">{testimonial.author}</p>
                    <p className="text-xs text-muted-foreground">{testimonial.role}</p>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>

        {/* Privacy Section */}
        <div className="mb-20">
          <Card className="border-2 border-primary/20 bg-gradient-to-br from-background to-primary/5">
            <CardContent className="p-8 md:p-12 text-center">
              <div className="w-16 h-16 rounded-full bg-primary/20 flex items-center justify-center mx-auto mb-6">
                <Shield className="h-8 w-8 text-primary" />
              </div>
              <h2 className="text-2xl md:text-3xl font-bold mb-4">
                Your data stays yours
              </h2>
              <p className="text-lg text-muted-foreground max-w-2xl mx-auto mb-6">
                No ads. No tracking. No data mining. Your baby's information is encrypted 
                and only accessible by caregivers you explicitly invite.
              </p>
              <p className="text-sm text-muted-foreground">
                Privacy-first design • GDPR compliant • Export anytime
              </p>
            </CardContent>
          </Card>
        </div>

        {/* Final CTA */}
        <div className="text-center max-w-2xl mx-auto">
          <h2 className="text-3xl md:text-4xl font-bold mb-6">
            Ready to simplify baby tracking?
          </h2>
          <p className="text-lg text-muted-foreground mb-8">
            Join thousands of parents who trust Nestling to track their baby's care.
          </p>
          <Button
            size="lg"
            onClick={() => navigate('/auth')}
            className="text-lg h-14 px-8 shadow-lg hover:shadow-xl transition-shadow"
          >
            Get Started Free
            <ArrowRight className="ml-2 h-5 w-5" />
          </Button>
          <p className="mt-4 text-sm text-muted-foreground">
            Free forever • No credit card required
          </p>
        </div>

        {/* Footer */}
        <div className="mt-20 pt-8 border-t border-border text-center text-sm text-muted-foreground">
          <p>© 2025 Nestling. Made with ❤️ for parents.</p>
        </div>
      </div>
    </div>
  );
}



