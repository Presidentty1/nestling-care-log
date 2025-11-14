import { supabase } from '@/integrations/supabase/client';

export async function compressImage(
  file: File,
  maxWidth: number = 1200,
  quality: number = 0.8
): Promise<Blob> {
  return new Promise((resolve, reject) => {
    const img = new Image();
    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');

    img.onload = () => {
      let width = img.width;
      let height = img.height;

      if (width > maxWidth) {
        height = (height * maxWidth) / width;
        width = maxWidth;
      }

      canvas.width = width;
      canvas.height = height;

      ctx?.drawImage(img, 0, 0, width, height);

      canvas.toBlob(
        (blob) => {
          if (blob) {
            resolve(blob);
          } else {
            reject(new Error('Failed to compress image'));
          }
        },
        'image/jpeg',
        quality
      );
    };

    img.onerror = reject;
    img.src = URL.createObjectURL(file);
  });
}

export async function uploadPhoto(
  babyId: string,
  category: string,
  file: File
): Promise<string> {
  // Compress image
  const compressed = await compressImage(file);

  // Generate unique filename
  const fileExt = 'jpg';
  const fileName = `${crypto.randomUUID()}.${fileExt}`;
  const filePath = `${babyId}/${category}/${fileName}`;

  // Upload to Supabase Storage
  const { error } = await supabase.storage
    .from('baby-photos')
    .upload(filePath, compressed, {
      contentType: 'image/jpeg',
      upsert: false,
    });

  if (error) throw error;

  // Get public URL
  const { data } = supabase.storage
    .from('baby-photos')
    .getPublicUrl(filePath);

  return data.publicUrl;
}

export async function deletePhoto(url: string): Promise<void> {
  // Extract path from URL
  const urlParts = url.split('/baby-photos/');
  if (urlParts.length < 2) return;

  const path = urlParts[1];

  const { error } = await supabase.storage
    .from('baby-photos')
    .remove([path]);

  if (error) throw error;
}

export function getPhotoUrl(path: string): string {
  const { data } = supabase.storage
    .from('baby-photos')
    .getPublicUrl(path);

  return data.publicUrl;
}
