import {
  Controller,
  Post,
  Body,
  UseGuards,
  UseInterceptors,
  UploadedFiles,
  BadRequestException,
  Get,
  Param,
} from '@nestjs/common';
import { FilesInterceptor } from '@nestjs/platform-express';
import { GalleryService } from './galleryService';
import { CreateGalleryDto } from './dto/create-gallery.dto';
import { AuthGuard } from '../User/userToken';
import { CurrentUser, GetToken } from '../common/decorators';

@Controller('gallery')
@UseGuards(AuthGuard)
export class GalleryController {
  constructor(private readonly galleryService: GalleryService) { }

  @Post()
  @UseInterceptors(FilesInterceptor('images', 20))
  async createGallery(
    @Body() createGalleryDto: CreateGalleryDto,
    @UploadedFiles() images: Express.Multer.File[],
    @CurrentUser() user: any,
    @GetToken() token: string,
  ) {

    try {
      if (!images || images.length === 0) {
        throw new BadRequestException('At least one image is required');
      }

      const gallery = await this.galleryService.createGallery(createGalleryDto, images, user.id, token);

      return {
        success: true,
        message: 'Gallery created successfully',
        data: gallery,
      };
    } catch (error) {
      throw error;
    }
  }

  @Get('group/:groupId')
  async getGalleriesByGroup(@Param('groupId') groupId: string, @GetToken() token: string) {
    const galleries = await this.galleryService.getGalleriesByGroup(groupId, token);
    return {
      success: true,
      data: galleries,
    };
  }

  @Get(':galleryId')
  async getGalleryById(@Param('galleryId') galleryId: string, @GetToken() token: string) {
    const gallery = await this.galleryService.getGalleryById(galleryId, token);
    return {
      success: true,
      data: gallery,
    };
  }
}