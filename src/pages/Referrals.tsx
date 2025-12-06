import { useQuery } from '@tanstack/react-query';
import { Card } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { useToast } from '@/hooks/use-toast';
import { Share2, Copy, Users } from 'lucide-react';
import { referralsService } from '@/services/referralsService';

export default function Referrals() {
  const { toast } = useToast();

  const { data: referralCode } = useQuery({
    queryKey: ['referral-code'],
    queryFn: async () => {
      return await referralsService.getOrCreateReferralCode();
    },
  });

  const copyToClipboard = () => {
    if (referralCode?.code) {
      navigator.clipboard.writeText(referralCode.code);
      toast({ title: 'Referral code copied!' });
    }
  };

  const shareReferral = async () => {
    if (!referralCode?.code) return;

    const shareData = {
      title: 'Join Nestling',
      text: `Use my referral code ${referralCode.code} to get started with Nestling - the best baby tracking app!`,
      url: window.location.origin,
    };

    if (navigator.share) {
      try {
        await navigator.share(shareData);
      } catch (err) {
        copyToClipboard();
      }
    } else {
      copyToClipboard();
    }
  };

  return (
    <div className="min-h-screen bg-background p-4">
      <div className="max-w-2xl mx-auto space-y-6">
        <h1 className="text-3xl font-bold">Refer Friends</h1>

        <Card className="p-6 text-center space-y-4">
          <Users className="w-16 h-16 mx-auto text-primary" />
          <h2 className="text-2xl font-bold">Share Nestling</h2>
          <p className="text-muted-foreground">
            Invite your friends to join Nestling and help them track their baby's milestones!
          </p>
        </Card>

        <Card className="p-6 space-y-4">
          <div>
            <h3 className="font-semibold mb-2">Your Referral Code</h3>
            <div className="flex gap-2">
              <Input
                value={referralCode?.code || 'Loading...'}
                readOnly
                className="font-mono text-lg"
              />
              <Button onClick={copyToClipboard} variant="outline">
                <Copy className="w-4 h-4" />
              </Button>
            </div>
          </div>

          <div className="flex gap-2">
            <Button className="flex-1" onClick={shareReferral}>
              <Share2 className="w-4 h-4 mr-2" />
              Share Code
            </Button>
          </div>

          <div className="pt-4 border-t">
            <div className="flex items-center justify-between">
              <span className="text-sm text-muted-foreground">Times used</span>
              <span className="text-2xl font-bold">{referralCode?.uses_count || 0}</span>
            </div>
          </div>
        </Card>

        <Card className="p-6">
          <h3 className="font-semibold mb-4">How it works</h3>
          <ol className="space-y-2 text-sm text-muted-foreground">
            <li>1. Share your unique referral code with friends</li>
            <li>2. They sign up using your code</li>
            <li>3. Both of you get benefits!</li>
          </ol>
        </Card>
      </div>
    </div>
  );
}