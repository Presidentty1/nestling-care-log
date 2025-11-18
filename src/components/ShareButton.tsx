import { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Share2, Loader2 } from 'lucide-react';
import { useToast } from '@/hooks/use-toast';
import { exportElementAsImage, shareImage } from '@/lib/imageExport';

interface ShareButtonProps {
  elementId: string;
  title: string;
  variant?: 'default' | 'outline' | 'ghost';
  className?: string;
}

export function ShareButton({ elementId, title, variant = 'default', className }: ShareButtonProps) {
  const [isExporting, setIsExporting] = useState(false);
  const { toast } = useToast();

  const handleShare = async () => {
    setIsExporting(true);
    
    try {
      const blob = await exportElementAsImage(elementId, title);
      if (!blob) throw new Error('Failed to generate image');
      
      await shareImage(blob, title);
      
      toast({
        title: 'Shared successfully!',
        description: 'Your card has been shared.',
      });
    } catch (error) {
      console.error('Share error:', error);
      toast({
        title: 'Share failed',
        description: 'Could not share the image. Please try again.',
        variant: 'destructive',
      });
    } finally {
      setIsExporting(false);
    }
  };

  return (
    <Button 
      onClick={handleShare} 
      disabled={isExporting} 
      variant={variant}
      className={className}
    >
      {isExporting ? (
        <>
          <Loader2 className="w-4 h-4 mr-2 animate-spin" />
          Generating...
        </>
      ) : (
        <>
          <Share2 className="w-4 h-4 mr-2" />
          Share
        </>
      )}
    </Button>
  );
}
