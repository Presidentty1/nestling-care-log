import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { supabase } from '@/integrations/supabase/client';
import { Baby } from '@/lib/types';
import { Tabs, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Dialog, DialogContent } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Download, Share2, Trash2 } from 'lucide-react';
import { format } from 'date-fns';
import { toast } from 'sonner';

interface PhotoItem {
  url: string;
  date: string;
  category: 'milestone' | 'health' | 'event';
  title: string;
  id: string;
}

export default function PhotoGallery() {
  const [selectedBaby, setSelectedBaby] = useState<Baby | null>(null);
  const [activeCategory, setActiveCategory] = useState('all');
  const [selectedPhoto, setSelectedPhoto] = useState<PhotoItem | null>(null);

  const { data: babies } = useQuery({
    queryKey: ['babies'],
    queryFn: async () => {
      const { data, error } = await supabase.from('babies').select('*');
      if (error) throw error;
      if (data && data.length > 0 && !selectedBaby) {
        setSelectedBaby(data[0]);
      }
      return data as Baby[];
    },
  });

  const { data: photos = [] } = useQuery({
    queryKey: ['photos', selectedBaby?.id, activeCategory],
    queryFn: async () => {
      if (!selectedBaby) return [];
      
      const allPhotos: PhotoItem[] = [];

      // Get milestone photos
      const { data: milestones } = await supabase
        .from('milestones')
        .select('*')
        .eq('baby_id', selectedBaby.id)
        .not('photo_url', 'is', null);
      
      if (milestones) {
        allPhotos.push(...milestones.map(m => ({
          url: m.photo_url!,
          date: m.achieved_date,
          category: 'milestone' as const,
          title: m.title,
          id: m.id,
        })));
      }

      // Get health record photos
      const { data: healthRecords } = await supabase
        .from('health_records')
        .select('*')
        .eq('baby_id', selectedBaby.id)
        .not('attachments', 'is', null);
      
      if (healthRecords) {
        healthRecords.forEach(record => {
          if (record.attachments && Array.isArray(record.attachments)) {
            record.attachments.forEach((url: string) => {
              allPhotos.push({
                url,
                date: record.recorded_at,
                category: 'health' as const,
                title: record.title,
                id: record.id,
              });
            });
          }
        });
      }

      // Filter by category
      const filtered = activeCategory === 'all' 
        ? allPhotos 
        : allPhotos.filter(p => p.category === activeCategory);

      // Sort by date
      return filtered.sort((a, b) => 
        new Date(b.date).getTime() - new Date(a.date).getTime()
      );
    },
    enabled: !!selectedBaby,
  });

  const handleDownload = async (photo: PhotoItem) => {
    try {
      const response = await fetch(photo.url);
      const blob = await response.blob();
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `${photo.title}-${photo.date}.jpg`;
      a.click();
      window.URL.revokeObjectURL(url);
      toast.success('Photo downloaded');
    } catch (error) {
      toast.error('Failed to download photo');
    }
  };

  const handleShare = async (photo: PhotoItem) => {
    if (navigator.share) {
      try {
        await navigator.share({
          title: photo.title,
          text: `${photo.title} - ${format(new Date(photo.date), 'MMM d, yyyy')}`,
          url: photo.url,
        });
      } catch (error) {
        // User cancelled share
      }
    } else {
      toast.info('Sharing not supported on this device');
    }
  };

  if (!selectedBaby) {
    return (
      <div className="container max-w-4xl mx-auto p-4">
        <p className="text-muted-foreground text-center py-8">
          No babies found. Add a baby to start a photo gallery.
        </p>
      </div>
    );
  }

  return (
    <div className="container max-w-4xl mx-auto p-4 pb-20">
      <div className="mb-6">
        <h1 className="text-3xl font-bold mb-2">Photo Gallery</h1>
        <p className="text-muted-foreground">{selectedBaby.name}</p>
      </div>

      <Tabs value={activeCategory} onValueChange={setActiveCategory} className="mb-6">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="all">All</TabsTrigger>
          <TabsTrigger value="milestone">Milestones</TabsTrigger>
          <TabsTrigger value="health">Health</TabsTrigger>
          <TabsTrigger value="event">Events</TabsTrigger>
        </TabsList>
      </Tabs>

      {photos.length === 0 ? (
        <p className="text-muted-foreground text-center py-12">
          No photos yet. Add photos to milestones or health records!
        </p>
      ) : (
        <div className="grid grid-cols-3 gap-2">
          {photos.map((photo, idx) => (
            <div
              key={`${photo.id}-${idx}`}
              className="aspect-square cursor-pointer overflow-hidden rounded-lg bg-muted"
              onClick={() => setSelectedPhoto(photo)}
            >
              <img
                src={photo.url}
                alt={photo.title}
                className="w-full h-full object-cover hover:scale-105 transition-transform"
              />
            </div>
          ))}
        </div>
      )}

      <Dialog open={!!selectedPhoto} onOpenChange={() => setSelectedPhoto(null)}>
        <DialogContent className="max-w-3xl">
          {selectedPhoto && (
            <div className="space-y-4">
              <img
                src={selectedPhoto.url}
                alt={selectedPhoto.title}
                className="w-full rounded-lg"
              />
              <div className="space-y-2">
                <h3 className="text-lg font-semibold">{selectedPhoto.title}</h3>
                <p className="text-sm text-muted-foreground">
                  {format(new Date(selectedPhoto.date), 'MMMM d, yyyy')}
                </p>
              </div>
              <div className="flex gap-2">
                <Button
                  variant="outline"
                  onClick={() => handleDownload(selectedPhoto)}
                >
                  <Download className="h-4 w-4 mr-2" />
                  Download
                </Button>
                <Button
                  variant="outline"
                  onClick={() => handleShare(selectedPhoto)}
                >
                  <Share2 className="h-4 w-4 mr-2" />
                  Share
                </Button>
              </div>
            </div>
          )}
        </DialogContent>
      </Dialog>
    </div>
  );
}
