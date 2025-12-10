import { ArrowLeft } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';

export default function Privacy() {
  const navigate = useNavigate();

  return (
    <div className='min-h-screen bg-background pb-20'>
      <div className='sticky top-0 z-10 bg-background/95 backdrop-blur border-b'>
        <div className='container mx-auto p-4'>
          <div className='flex items-center gap-4'>
            <Button onClick={() => navigate(-1)} variant='ghost' size='sm'>
              <ArrowLeft className='h-4 w-4' />
            </Button>
            <h1 className='text-2xl font-bold'>Privacy Policy</h1>
          </div>
        </div>
      </div>

      <div className='container mx-auto p-4 max-w-3xl space-y-6'>
        <Card>
          <CardHeader>
            <CardTitle>Privacy Policy for Nestling</CardTitle>
            <p className='text-sm text-muted-foreground'>Effective Date: January 2025</p>
          </CardHeader>
          <CardContent className='space-y-6 text-sm'>
            <section>
              <h2 className='font-semibold text-lg mb-2'>1. Introduction</h2>
              <p className='text-muted-foreground leading-relaxed'>
                Nestling is a baby tracking app designed to help parents log and track their baby's
                daily activities, including feeding, sleeping, and diaper changes. We are committed
                to protecting your privacy and being transparent about how we handle your data.
              </p>
            </section>

            <section>
              <h2 className='font-semibold text-lg mb-2'>2. Data We Collect</h2>
              <p className='text-muted-foreground leading-relaxed mb-2'>
                We collect the following information to provide you with our services:
              </p>
              <ul className='list-disc list-inside space-y-1 text-muted-foreground ml-4'>
                <li>
                  <strong>Baby Information:</strong> Name, date of birth, feeding preferences
                </li>
                <li>
                  <strong>Activity Logs:</strong> Feeding times/amounts, sleep durations, diaper
                  changes
                </li>
                <li>
                  <strong>Account Information:</strong> Email address (optional for multi-device
                  sync)
                </li>
                <li>
                  <strong>Device Information:</strong> Device ID for sync purposes
                </li>
              </ul>
            </section>

            <section>
              <h2 className='font-semibold text-lg mb-2'>3. How We Use Your Data</h2>
              <p className='text-muted-foreground leading-relaxed mb-2'>
                Your data is used exclusively to:
              </p>
              <ul className='list-disc list-inside space-y-1 text-muted-foreground ml-4'>
                <li>Display your baby's activity logs and timeline</li>
                <li>Provide AI-powered insights and nap predictions</li>
                <li>Sync data across your devices (if you enable cloud sync)</li>
                <li>Allow sharing with caregivers you explicitly invite</li>
              </ul>
              <p className='text-muted-foreground leading-relaxed mt-2'>
                <strong>We do not:</strong> Sell your data, show ads, or share your information with
                third parties for marketing purposes.
              </p>
            </section>

            <section>
              <h2 className='font-semibold text-lg mb-2'>4. Data Storage</h2>
              <p className='text-muted-foreground leading-relaxed'>
                Your data is stored using a <strong>local-first approach</strong>. All logs are
                saved on your device first. If you enable cloud sync, data is securely stored using
                Supabase (PostgreSQL database with encryption). Data is encrypted in transit (HTTPS)
                and at rest.
              </p>
            </section>

            <section>
              <h2 className='font-semibold text-lg mb-2'>5. Third-Party Services</h2>
              <p className='text-muted-foreground leading-relaxed mb-2'>
                We use the following third-party services:
              </p>
              <ul className='list-disc list-inside space-y-1 text-muted-foreground ml-4'>
                <li>
                  <strong>Supabase:</strong> Backend database and authentication (stores your baby
                  logs)
                </li>
                <li>
                  <strong>Lovable AI:</strong> Powers AI assistant and cry analysis features
                </li>
              </ul>
              <p className='text-muted-foreground leading-relaxed mt-2'>
                These services have their own privacy policies. We only share the minimum data
                necessary for functionality.
              </p>
            </section>

            <section>
              <h2 className='font-semibold text-lg mb-2'>6. Data Retention</h2>
              <p className='text-muted-foreground leading-relaxed'>
                Your data is retained until you delete it. You can export all your data as CSV or
                delete your account entirely at any time from Settings → Privacy & Data.
              </p>
            </section>

            <section>
              <h2 className='font-semibold text-lg mb-2'>7. Your Rights</h2>
              <p className='text-muted-foreground leading-relaxed mb-2'>You have the right to:</p>
              <ul className='list-disc list-inside space-y-1 text-muted-foreground ml-4'>
                <li>
                  <strong>Access:</strong> View all your data at any time in the app
                </li>
                <li>
                  <strong>Export:</strong> Download your data as CSV (Settings → Privacy & Data)
                </li>
                <li>
                  <strong>Delete:</strong> Permanently delete your account and all data
                </li>
                <li>
                  <strong>Control Sharing:</strong> Manage who has access to your baby's logs
                </li>
              </ul>
            </section>

            <section>
              <h2 className='font-semibold text-lg mb-2'>8. Children's Privacy</h2>
              <p className='text-muted-foreground leading-relaxed'>
                Nestling is designed for parents and caregivers (18+). We do not knowingly collect
                personal information from children. The app stores information <em>about</em>{' '}
                babies, but this data is controlled by the parent/caregiver account holder.
              </p>
            </section>

            <section>
              <h2 className='font-semibold text-lg mb-2'>9. Security</h2>
              <p className='text-muted-foreground leading-relaxed'>
                We use industry-standard security measures including HTTPS encryption, secure
                authentication, and row-level security policies in our database. However, no system
                is 100% secure. We recommend using a strong password and enabling device-level
                security (passcode/biometrics).
              </p>
            </section>

            <section>
              <h2 className='font-semibold text-lg mb-2'>10. Changes to This Policy</h2>
              <p className='text-muted-foreground leading-relaxed'>
                We may update this privacy policy from time to time. We will notify you of
                significant changes via email or in-app notification. Continued use of the app after
                changes constitutes acceptance.
              </p>
            </section>

            <section>
              <h2 className='font-semibold text-lg mb-2'>11. Contact Us</h2>
              <p className='text-muted-foreground leading-relaxed'>
                If you have questions about this Privacy Policy or your data, please contact us at:
              </p>
              <p className='text-muted-foreground mt-2'>
                <strong>Email:</strong> privacy@nestling.app
              </p>
            </section>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
