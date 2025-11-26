import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { SupabaseService } from '../Supabase/supabaseService';
import { CreateGalleryDto } from './dto/create-gallery.dto';
import { Gallery } from './galleryModel';
import { v4 as uuidv4 } from 'uuid';

@Injectable()
export class GalleryService {
  constructor(private readonly supabaseService: SupabaseService) { }

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

    const eventNameSanitized = event_name.toLowerCase().replace(/[^a-z0-9]/g, '_');
    const imageUrls: string[] = [];

    for (const image of images) {
      const fileExtension = image.originalname.split('.').pop();
      const fileName = `${uuidv4()}.${fileExtension}`;
      const filePath = `${group_id}/${eventNameSanitized}/${fileName}`;

      const { data: uploadData, error: uploadError } = await client
        .storage
        .from('gallery')
        .upload(filePath, image.buffer, {
          contentType: image.mimetype,
          upsert: false,
        });

      if (uploadError) {
        for (const url of imageUrls) {
          const path = url.split('/gallery/')[1];
          await client.storage.from('gallery').remove([path]);
        }
        throw new BadRequestException(`Failed to upload image: ${uploadError.message}`);
      }

      const { data: publicUrlData } = client
        .storage
        .from('gallery')
        .getPublicUrl(filePath);

      imageUrls.push(publicUrlData.publicUrl);
    }

    const { data: gallery, error: galleryError } = await client
      .from('galleries')
      .insert({
        group_id,
        event_name,
        location,
        date,
        images: imageUrls,
      })
      .select()
      .single();

    if (galleryError) {
      for (const url of imageUrls) {
        const path = url.split('/gallery/')[1];
        await client.storage.from('gallery').remove([path]);
      }
      throw new BadRequestException(`Failed to create gallery: ${galleryError.message}`);
    }

    return gallery;
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
    return galleries;
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
    return gallery;
  }
}
