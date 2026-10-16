import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { SupabaseService } from '../Supabase/supabaseService';
import { CreateGalleryDto } from './dto/create-gallery.dto';
import { Gallery } from './galleryModel';
import { v4 as uuidv4 } from 'uuid';

export const ALLOWED_IMAGE_MIMES = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
const MIME_EXTENSIONS: Record<string, string> = {
  'image/jpeg': 'jpg',
  'image/jpg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
};
const BUCKET = 'gallery';
const SIGNED_URL_TTL_SECONDS = 60 * 60;

@Injectable()
export class GalleryService {
  constructor(private readonly supabaseService: SupabaseService) { }

  // O bucket é privado: guardamos o caminho do objeto e devolvemos URLs assinadas.
  // Registos antigos guardam o URL público completo, por isso aceitamos ambos.
  private toStoragePath(image: string): string {
    const marker = `/${BUCKET}/`;
    const index = image.indexOf(marker);
    return index >= 0 ? decodeURIComponent(image.substring(index + marker.length)) : image;
  }

  private async withSignedUrls(client: any, gallery: Gallery): Promise<Gallery> {
    const paths = (gallery.images || []).map(image => this.toStoragePath(image));
    if (paths.length === 0) {
      return gallery;
    }

    const { data, error } = await client.storage
      .from(BUCKET)
      .createSignedUrls(paths, SIGNED_URL_TTL_SECONDS);

    if (error || !data) {
      throw new BadRequestException('Failed to load gallery images');
    }

    return {
      ...gallery,
      images: data.filter((item: any) => item.signedUrl).map((item: any) => item.signedUrl),
    };
  }

  private validateImage(image: Express.Multer.File): void {
    if (!ALLOWED_IMAGE_MIMES.includes(image.mimetype)) {
      throw new BadRequestException('Invalid file type. Only JPEG, PNG and WEBP are allowed.');
    }

    const signature = image.buffer.subarray(0, 4).toString('hex');
    const isJpeg = signature.startsWith('ffd8ff');
    const isPng = signature === '89504e47';
    const isWebp = signature === '52494646' && image.buffer.subarray(8, 12).toString('ascii') === 'WEBP';

    if (!isJpeg && !isPng && !isWebp) {
      throw new BadRequestException('File content does not match an allowed image type');
    }
  }

  async createGallery(
    createGalleryDto: CreateGalleryDto,
    images: Express.Multer.File[],
    userId: string,
    token: string,
  ): Promise<Gallery> {
    const { group_id, event_name, location, date } = createGalleryDto;

    const client = this.supabaseService.getClientWithToken(token);

    const { data: membership, error: membershipError } = await client
      .from('group_members')
      .select('*')
      .eq('group_id', group_id)
      .eq('user_id', userId)
      .single();

    if (membershipError || !membership) {
      throw new ForbiddenException('You are not a member of this group');
    }

    const { data: group, error: groupError } = await client
      .from('groups')
      .select('*')
      .eq('id', group_id)
      .single();

    if (groupError || !group) {
      throw new NotFoundException('Group not found');
    }

    if (!images || images.length === 0) {
      throw new BadRequestException('At least one image is required');
    }

    for (const image of images) {
      this.validateImage(image);
    }

    const eventNameSanitized = event_name.toLowerCase().replace(/[^a-z0-9]/g, '_');
    const imagePaths: string[] = [];

    for (const image of images) {
      const fileName = `${uuidv4()}.${MIME_EXTENSIONS[image.mimetype]}`;
      const filePath = `${group_id}/${eventNameSanitized}/${fileName}`;

      const { error: uploadError } = await client
        .storage
        .from(BUCKET)
        .upload(filePath, image.buffer, {
          contentType: image.mimetype,
          upsert: false,
        });

      if (uploadError) {
        if (imagePaths.length > 0) {
          await client.storage.from(BUCKET).remove(imagePaths);
        }
        throw new BadRequestException(`Failed to upload image: ${uploadError.message}`);
      }

      imagePaths.push(filePath);
    }

    const { data: gallery, error: galleryError } = await client
      .from('galleries')
      .insert({
        group_id,
        event_name,
        location,
        date,
        images: imagePaths,
      })
      .select()
      .single();

    if (galleryError) {
      await client.storage.from(BUCKET).remove(imagePaths);
      throw new BadRequestException(`Failed to create gallery: ${galleryError.message}`);
    }

    return this.withSignedUrls(client, gallery);
  }

  async getGalleriesByGroup(groupId: string, token: string): Promise<Gallery[]> {
    const client = this.supabaseService.getClientWithToken(token);
    const { data: galleries, error } = await client
      .from('galleries')
      .select('*')
      .eq('group_id', groupId)
      .order('date', { ascending: false });
    if (error) {
      throw new BadRequestException(`Failed to fetch galleries: ${error.message}`);
    }
    return Promise.all((galleries || []).map(gallery => this.withSignedUrls(client, gallery)));
  }

  async getGalleryById(galleryId: string, token: string): Promise<Gallery> {
    const client = this.supabaseService.getClientWithToken(token);
    const { data: gallery, error } = await client
      .from('galleries')
      .select('*')
      .eq('id', galleryId)
      .single();
    if (error) {
      throw new NotFoundException(`Gallery not found: ${error.message}`);
    }
    return this.withSignedUrls(client, gallery);
  }
}
