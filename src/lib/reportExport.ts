import { jsPDF } from 'jspdf';
import type { Baby } from './types';
import { supabase } from '@/integrations/supabase/client';

export async function exportWeeklyReport(baby: Baby) {
  const pdf = new jsPDF();
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

  // Fetch data
  const { data: events } = await supabase
    .from('events')
    .select('*')
    .eq('baby_id', baby.id)
    .gte('start_time', sevenDaysAgo.toISOString())
    .order('start_time', { ascending: false });

  // Title
  pdf.setFontSize(20);
  pdf.text(`Weekly Report: ${baby.name}`, 20, 20);

  pdf.setFontSize(12);
  pdf.text(
    `Period: ${sevenDaysAgo.toLocaleDateString()} - ${new Date().toLocaleDateString()}`,
    20,
    30
  );

  let yPos = 45;

  // Summary stats
  const feeds = events?.filter(e => e.type === 'feed') || [];
  const sleeps = events?.filter(e => e.type === 'sleep' && e.end_time) || [];
  const diapers = events?.filter(e => e.type === 'diaper') || [];

  pdf.setFontSize(14);
  pdf.text('Summary Statistics', 20, yPos);
  yPos += 10;

  pdf.setFontSize(11);
  pdf.text(`Total Feeds: ${feeds.length}`, 30, yPos);
  yPos += 7;
  pdf.text(`Total Sleep Sessions: ${sleeps.length}`, 30, yPos);
  yPos += 7;
  pdf.text(`Total Diaper Changes: ${diapers.length}`, 30, yPos);
  yPos += 15;

  // Sleep analysis
  const totalSleepHours = sleeps.reduce((acc, s) => {
    const duration =
      (new Date(s.end_time).getTime() - new Date(s.start_time).getTime()) / (1000 * 60 * 60);
    return acc + duration;
  }, 0);

  pdf.setFontSize(14);
  pdf.text('Sleep Analysis', 20, yPos);
  yPos += 10;

  pdf.setFontSize(11);
  pdf.text(`Total Sleep Time: ${totalSleepHours.toFixed(1)} hours`, 30, yPos);
  yPos += 7;
  pdf.text(`Average per Day: ${(totalSleepHours / 7).toFixed(1)} hours`, 30, yPos);
  yPos += 15;

  // Feeding analysis
  const feedsWithAmount = feeds.filter(f => f.amount);
  const totalFeedAmount = feedsWithAmount.reduce((acc, f) => acc + (f.amount || 0), 0);

  pdf.setFontSize(14);
  pdf.text('Feeding Analysis', 20, yPos);
  yPos += 10;

  pdf.setFontSize(11);
  pdf.text(`Average Feeds per Day: ${(feeds.length / 7).toFixed(1)}`, 30, yPos);
  yPos += 7;
  if (feedsWithAmount.length > 0) {
    pdf.text(
      `Average Amount: ${(totalFeedAmount / feedsWithAmount.length).toFixed(0)} ml`,
      30,
      yPos
    );
    yPos += 7;
  }

  // Save
  pdf.save(`${baby.name}_weekly_report_${new Date().toISOString().split('T')[0]}.pdf`);
}
