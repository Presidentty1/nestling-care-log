import html2canvas from 'html2canvas';

export async function exportElementAsImage(
  elementId: string,
  filename: string
): Promise<Blob | null> {
  const element = document.getElementById(elementId);
  if (!element) {
    console.error('Element not found:', elementId);
    return null;
  }

  try {
    const canvas = await html2canvas(element, {
      backgroundColor: '#ffffff',
      scale: 2,
      logging: false,
      useCORS: true,
      windowWidth: 600,
      windowHeight: 600,
    });

    return new Promise((resolve) => {
      canvas.toBlob((blob) => resolve(blob), 'image/png');
    });
  } catch (error) {
    console.error('Failed to export image:', error);
    return null;
  }
}

export async function shareImage(blob: Blob, title: string): Promise<boolean> {
  // Try native share API (mobile)
  if (navigator.share && navigator.canShare) {
    const file = new File([blob], `${title}.png`, { type: 'image/png' });
    if (navigator.canShare({ files: [file] })) {
      try {
        await navigator.share({
          files: [file],
          title: title,
          text: 'Check out this milestone from Nestling!',
        });
        return true;
      } catch (error: any) {
        if (error.name !== 'AbortError') {
          console.error('Share failed:', error);
        }
      }
    }
  }

  // Fallback: Download
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `${title}.png`;
  a.click();
  URL.revokeObjectURL(url);
  return true;
}
