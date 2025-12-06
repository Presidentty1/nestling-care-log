import { supabase } from '@/integrations/supabase/client';
import { milestonesService } from './milestonesService';
import { healthRecordsService } from './healthRecordsService';

export interface PhotoItem {
  url: string;
  date: string;
  category: 'milestone' | 'health' | 'event';
  title: string;
  id: string;
}

class PhotoService {
  async getPhotos(babyId: string, category?: 'milestone' | 'health' | 'event' | 'all'): Promise<PhotoItem[]> {
    const allPhotos: PhotoItem[] = [];

    // Get milestone photos
    if (!category || category === 'all' || category === 'milestone') {
      const milestones = await milestonesService.getMilestones(babyId);
      milestones
        .filter(m => m.photo_url)
        .forEach(m => {
          allPhotos.push({
            url: m.photo_url!,
            date: m.achieved_date,
            category: 'milestone',
            title: m.title,
            id: m.id,
          });
        });
    }

    // Get health record photos
    if (!category || category === 'all' || category === 'health') {
      const healthRecords = await healthRecordsService.getHealthRecords(babyId);
      healthRecords.forEach(record => {
        if (record.attachments && typeof record.attachments === 'object') {
          const attachments = Array.isArray(record.attachments) 
            ? record.attachments 
            : Object.values(record.attachments);
          
          attachments.forEach((url: any) => {
            if (typeof url === 'string') {
              allPhotos.push({
                url,
                date: record.recorded_at,
                category: 'health',
                title: record.title,
                id: record.id,
              });
            }
          });
        }
      });
    }

    // Get event photos (from events table if they have photo attachments)
    if (!category || category === 'all' || category === 'event') {
      const { data: events } = await supabase
        .from('events')
        .select('id, start_time, note')
        .eq('baby_id', babyId)
        .not('note', 'is', null);
      
      if (events) {
        events.forEach(event => {
          // Parse note for photo URLs (if stored in note field)
          const note = event.note || '';
          const photoUrlMatch = note.match(/https?:\/\/[^\s]+\.(jpg|jpeg|png|gif|webp)/i);
          if (photoUrlMatch) {
            allPhotos.push({
              url: photoUrlMatch[0],
              date: event.start_time,
              category: 'event',
              title: 'Event Photo',
              id: event.id,
            });
          }
        });
      }
    }

    // Sort by date descending
    return allPhotos.sort((a, b) => 
      new Date(b.date).getTime() - new Date(a.date).getTime()
    );
  }
}

export const photoService = new PhotoService();
