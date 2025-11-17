import { useState } from 'react';
import { Navigate, useNavigate } from 'react-router-dom';
import { useAuth } from '@/hooks/useAuth';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { toast } from 'sonner';
import { Baby, Loader2 } from 'lucide-react';
import { useAppStore } from '@/store/appStore';

export default function Auth() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [name, setName] = useState('');
  const [loading, setLoading] = useState(false);
  const { signIn, signUp, user, loading: authLoading } = useAuth();
  const navigate = useNavigate();
  const { setActiveBabyId } = useAppStore();

  // Show spinner while auth is initializing
  if (authLoading) {
    return (
      <div className="min-h-screen bg-background flex items-center justify-center">
        <Loader2 className="h-8 w-8 animate-spin text-primary" />
      </div>
    );
  }

  // Redirect if already logged in
  if (user) {
    return <Navigate to="/home" replace />;
  }

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    const { error } = await signIn(email, password);

    if (error) {
      toast.error(error.message);
    } else {
      // Reset any stale local state tied to previous users
      setActiveBabyId(null);
      localStorage.removeItem('activeBabyId');
      toast.success('Welcome back!');
      navigate('/home');
    }

    setLoading(false);
  };

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    if (!name.trim()) {
      toast.error('Please enter your name');
      setLoading(false);
      return;
    }

    const { error } = await signUp(email, password, name);

    if (error) {
      toast.error(error.message);
    } else {
      // Clear previous user's state and go to onboarding/home flow
      setActiveBabyId(null);
      localStorage.removeItem('activeBabyId');
      toast.success('Account created! Setting up your profile...');
      navigate('/home');
    }

    setLoading(false);
  };

  const handleSkipLogin = async () => {
    setLoading(true);
    
    // Create/sign in with dev account
    const devEmail = 'dev@nestling.app';
    const devPassword = 'devpass123';
    
    try {
      // Try signing in first
      let { error } = await signIn(devEmail, devPassword);
      
      // If account doesn't exist, create it
      if (error?.message?.includes('Invalid login credentials')) {
        const signUpResult = await signUp(devEmail, devPassword, 'Dev User');
        error = signUpResult.error;
      }
      
      if (error) {
        toast.error('Skip login failed: ' + error.message);
      } else {
        // Clear any stale baby selection so Home can route correctly
        setActiveBabyId(null);
        localStorage.removeItem('activeBabyId');
        toast.success('Signed in as dev user');
        navigate('/home');
      }
    } catch (err) {
      console.error('Skip login error:', err);
      toast.error('Failed to skip login');
    }
    
    setLoading(false);
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4">
      <Card className="w-full max-w-md shadow-soft">
        <CardHeader className="text-center space-y-4">
          <div className="mx-auto w-16 h-16 bg-primary rounded-2xl flex items-center justify-center shadow-soft">
            <Baby className="h-8 w-8 text-primary-foreground" />
          </div>
          <div>
            <CardTitle className="text-[28px] leading-[34px]">Nestling</CardTitle>
            <CardDescription className="text-secondary">The fastest shared baby logger</CardDescription>
          </div>
        </CardHeader>
        <CardContent>
          <Tabs defaultValue="signin" className="w-full">
            <TabsList className="grid w-full grid-cols-2 mb-6">
              <TabsTrigger value="signin">Sign In</TabsTrigger>
              <TabsTrigger value="signup">Sign Up</TabsTrigger>
            </TabsList>

            <TabsContent value="signin">
              <form onSubmit={handleSignIn} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="signin-email">Email</Label>
                  <Input
                    id="signin-email"
                    type="email"
                    placeholder="you@example.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="signin-password">Password</Label>
                  <Input
                    id="signin-password"
                    type="password"
                    placeholder="••••••••"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                  />
                </div>
                <Button type="submit" className="w-full" disabled={loading}>
                  {loading ? 'Signing in...' : 'Sign In'}
                </Button>
              </form>
            </TabsContent>

            <TabsContent value="signup">
              <form onSubmit={handleSignUp} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="signup-name">Name</Label>
                  <Input
                    id="signup-name"
                    type="text"
                    placeholder="Your name"
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="signup-email">Email</Label>
                  <Input
                    id="signup-email"
                    type="email"
                    placeholder="you@example.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="signup-password">Password</Label>
                  <Input
                    id="signup-password"
                    type="password"
                    placeholder="••••••••"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    minLength={6}
                  />
                </div>
                <Button type="submit" className="w-full" disabled={loading}>
                  {loading ? 'Creating account...' : 'Create Account'}
                </Button>
              </form>
            </TabsContent>
          </Tabs>

          {/* TEMP: Development skip button */}
          <div className="mt-4 pt-4 border-t">
            <Button 
              variant="ghost" 
              className="w-full text-muted-foreground hover:text-foreground"
              onClick={handleSkipLogin}
              disabled={loading}
            >
              {loading ? 'Signing in...' : 'Skip Login (Dev Only)'}
            </Button>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
