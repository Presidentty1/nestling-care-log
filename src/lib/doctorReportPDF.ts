import jsPDF from 'jspdf';
import { format } from 'date-fns';
import { Baby } from './types';

export async function generateDoctorReport(
  baby: Baby,
  growthRecords: any[],
  events: any[],
  healthRecords: any[],
  dateRange: [Date, Date]
) {
  const doc = new jsPDF();
  let yPos = 20;

  // Header
  doc.setFontSize(20);
  doc.text('Baby Health Summary', 20, yPos);
  yPos += 10;

  doc.setFontSize(10);
  doc.setTextColor(128, 128, 128);
  doc.text(`Generated: ${format(new Date(), 'MMM dd, yyyy')}`, 20, yPos);
  yPos += 15;

  // Baby Info
  doc.setFontSize(14);
  doc.setTextColor(0, 0, 0);
  doc.text('Baby Information', 20, yPos);
  yPos += 8;

  doc.setFontSize(10);
  doc.text(`Name: ${baby.name}`, 20, yPos);
  yPos += 6;
  doc.text(`Date of Birth: ${format(new Date(baby.date_of_birth), 'MMM dd, yyyy')}`, 20, yPos);
  yPos += 6;
  const ageMonths = Math.floor((Date.now() - new Date(baby.date_of_birth).getTime()) / (1000 * 60 * 60 * 24 * 30));
  doc.text(`Age: ${ageMonths} months`, 20, yPos);
  yPos += 10;

  // Growth Measurements
  if (growthRecords.length > 0) {
    doc.setFontSize(14);
    doc.text('Recent Growth Measurements', 20, yPos);
    yPos += 8;

    doc.setFontSize(9);
    const latestGrowth = growthRecords[0];
    doc.text(`Latest measurement (${format(new Date(latestGrowth.recorded_at), 'MMM dd, yyyy')}):`, 25, yPos);
    yPos += 6;
    
    if (latestGrowth.weight) {
      doc.text(`Weight: ${latestGrowth.weight} kg (${latestGrowth.percentile_weight}th percentile)`, 30, yPos);
      yPos += 5;
    }
    if (latestGrowth.length) {
      doc.text(`Length: ${latestGrowth.length} cm (${latestGrowth.percentile_length}th percentile)`, 30, yPos);
      yPos += 5;
    }
    if (latestGrowth.head_circumference) {
      doc.text(`Head: ${latestGrowth.head_circumference} cm (${latestGrowth.percentile_head}th percentile)`, 30, yPos);
      yPos += 5;
    }
    yPos += 10;
  }

  // Daily Activity Summary
  if (events.length > 0) {
    doc.setFontSize(14);
    doc.text('Activity Summary (Last 7 Days)', 20, yPos);
    yPos += 8;

    doc.setFontSize(9);
    const feedCount = events.filter(e => e.type === 'feed').length;
    const sleepCount = events.filter(e => e.type === 'sleep').length;
    const diaperCount = events.filter(e => e.type === 'diaper').length;

    doc.text(`Feeds: ${feedCount}`, 25, yPos);
    yPos += 5;
    doc.text(`Sleep sessions: ${sleepCount}`, 25, yPos);
    yPos += 5;
    doc.text(`Diaper changes: ${diaperCount}`, 25, yPos);
    yPos += 10;
  }

  // Health Records
  if (healthRecords.length > 0) {
    doc.setFontSize(14);
    doc.text('Recent Health Records', 20, yPos);
    yPos += 8;

    doc.setFontSize(9);
    healthRecords.slice(0, 5).forEach((record) => {
      if (yPos > 270) {
        doc.addPage();
        yPos = 20;
      }

      const dateStr = format(new Date(record.recorded_at), 'MMM dd, yyyy');
      doc.text(`${dateStr} - ${record.title}`, 25, yPos);
      yPos += 5;

      if (record.temperature) {
        doc.text(`  Temperature: ${record.temperature}°C`, 30, yPos);
        yPos += 5;
      }
      if (record.diagnosis) {
        doc.text(`  Diagnosis: ${record.diagnosis}`, 30, yPos);
        yPos += 5;
      }
      yPos += 3;
    });
    yPos += 10;
  }

  // Notes Section
  if (yPos > 240) {
    doc.addPage();
    yPos = 20;
  }

  doc.setFontSize(14);
  doc.text('Notes & Questions', 20, yPos);
  yPos += 8;

  doc.setFontSize(9);
  doc.setTextColor(128, 128, 128);
  doc.text('(Space for doctor to write notes)', 25, yPos);

  // Footer
  doc.setFontSize(8);
  doc.setTextColor(128, 128, 128);
  const pageCount = (doc as any).internal.pages.length - 1;
  for (let i = 1; i <= pageCount; i++) {
    doc.setPage(i);
    doc.text(`Page ${i} of ${pageCount}`, 105, 290, { align: 'center' });
  }

  return doc;
}

export function downloadDoctorReport(doc: jsPDF, babyName: string) {
  doc.save(`${babyName}-health-report-${format(new Date(), 'yyyy-MM-dd')}.pdf`);
}
