import { supabase } from '@/integrations/supabase/client';
import { format } from 'date-fns';

export async function exportToJSON(familyId: string, startDate: Date, endDate: Date) {
  const { data: events } = await supabase
    .from('events')
    .select('*')
    .eq('family_id', familyId)
    .gte('start_time', startDate.toISOString())
    .lte('start_time', endDate.toISOString())
    .order('start_time', { ascending: false });

  const { data: babies } = await supabase
    .from('babies')
    .select('*')
    .eq('family_id', familyId);

  const exportData = {
    exported_at: new Date().toISOString(),
    app_version: '1.0.0',
    date_range: {
      start: startDate.toISOString(),
      end: endDate.toISOString(),
    },
    babies,
    events,
  };

  const blob = new Blob([JSON.stringify(exportData, null, 2)], {
    type: 'application/json',
  });
  
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = `nestling-export-${format(new Date(), 'yyyy-MM-dd')}.json`;
  link.click();
  URL.revokeObjectURL(url);
}

export async function exportToCSV(familyId: string, startDate: Date, endDate: Date) {
  const { data: events } = await supabase
    .from('events')
    .select('*, babies(name)')
    .eq('family_id', familyId)
    .gte('start_time', startDate.toISOString())
    .lte('start_time', endDate.toISOString())
    .order('start_time', { ascending: false });

  if (!events) return;

  const headers = ['Date', 'Time', 'Baby', 'Type', 'Subtype', 'Duration/Amount', 'Unit', 'Notes'];
  const rows = events.map(event => {
    const duration = event.end_time 
      ? Math.round((new Date(event.end_time).getTime() - new Date(event.start_time).getTime()) / 60000)
      : event.amount || '';
    
    return [
      format(new Date(event.start_time), 'yyyy-MM-dd'),
      format(new Date(event.start_time), 'HH:mm'),
      (event.babies as any)?.name || '',
      event.type,
      event.subtype || '',
      duration,
      event.unit || '',
      event.note || '',
    ];
  });

  const csv = [headers, ...rows]
    .map(row => row.map(cell => `"${cell}"`).join(','))
    .join('\n');

  const blob = new Blob([csv], { type: 'text/csv' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url;
  link.download = `nestling-events-${format(new Date(), 'yyyy-MM-dd')}.csv`;
  link.click();
  URL.revokeObjectURL(url);
}

export async function generateDoctorSummary(babyId: string, startDate: Date, endDate: Date): Promise<string> {
  const { data: baby } = await supabase
    .from('babies')
    .select('*')
    .eq('id', babyId)
    .single();

  const { data: events } = await supabase
    .from('events')
    .select('*')
    .eq('baby_id', babyId)
    .gte('start_time', startDate.toISOString())
    .lte('start_time', endDate.toISOString());

  if (!baby || !events) return '';

  const feeds = events.filter(e => e.type === 'feed');
  const sleeps = events.filter(e => e.type === 'sleep');
  const diapers = events.filter(e => e.type === 'diaper');

  const dayCount = Math.ceil((endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24));
  const avgFeedsPerDay = (feeds.length / dayCount).toFixed(1);
  
  const totalSleepMinutes = sleeps.reduce((acc, s) => {
    if (s.end_time) {
      return acc + (new Date(s.end_time).getTime() - new Date(s.start_time).getTime()) / 60000;
    }
    return acc;
  }, 0);
  const avgSleepHoursPerDay = (totalSleepMinutes / 60 / dayCount).toFixed(1);

  return `Baby Care Report for ${baby.name}
Date Range: ${format(startDate, 'MMM dd, yyyy')} - ${format(endDate, 'MMM dd, yyyy')}
Generated: ${format(new Date(), 'MMM dd, yyyy')}

FEEDING SUMMARY
- Total feeds: ${feeds.length}
- Average per day: ${avgFeedsPerDay}
- Bottle feeds: ${feeds.filter(f => f.subtype === 'bottle').length}
- Breastfeeding sessions: ${feeds.filter(f => f.subtype === 'breast').length}

SLEEP SUMMARY
- Total sleep events: ${sleeps.length}
- Average sleep per day: ${avgSleepHoursPerDay} hours
- Number of naps per day: ${(sleeps.length / dayCount).toFixed(1)}

DIAPER SUMMARY
- Total diapers: ${diapers.length}
- Wet: ${diapers.filter(d => d.subtype === 'wet').length}
- Dirty: ${diapers.filter(d => d.subtype === 'dirty').length}
- Average per day: ${(diapers.length / dayCount).toFixed(1)}

NOTES
${events.filter(e => e.note && (e.note.toLowerCase().includes('doctor') || e.note.toLowerCase().includes('concern')))
  .map(e => `- ${format(new Date(e.start_time), 'MMM dd')}: ${e.note}`)
  .join('\n') || '- No flagged notes'}
`;
}
