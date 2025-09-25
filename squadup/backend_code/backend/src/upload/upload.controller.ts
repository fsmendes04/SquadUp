import {
  Controller,
  Post,
  Get,
  Param,
  UploadedFile,
  UseInterceptors,
  HttpException,
  HttpStatus,
  ParseUUIDPipe,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { UploadService } from './upload.service';

@Controller('upload')
export class UploadController {
  constructor(private readonly uploadService: UploadService) { }

  /**
   * Upload de avatar para um usuário (endpoint interno/utilitário)
   * POST /upload/:id/avatar
   */
  @Post(':id/avatar')
  @UseInterceptors(FileInterceptor('avatar'))
  async uploadAvatar(
    @Param('id', ParseUUIDPipe) userId: string,
    @UploadedFile() file: Express.Multer.File,
  ) {
    try {
      // Fazer upload do novo avatar
      const result = await this.uploadService.uploadAvatar(userId, file);

      // Limpar avatares antigos (opcional, para economizar espaço)
      await this.uploadService.cleanupOldAvatars(userId, result.path);

      return {
        success: true,
        message: 'Avatar uploaded successfully',
        data: {
          url: result.url,
          path: result.path,
        },
      };
    } catch (error) {
      throw new HttpException(
        {
          success: false,
          message: 'Error uploading avatar',
          error: error.message || error,
        },
        error.status || HttpStatus.BAD_REQUEST,
      );
    }
  }

  /**
   * Obter informações do serviço de upload
   * GET /upload/info
   */
  @Get('info')
  async getUploadInfo() {
    return {
      success: true,
      message: 'Upload service is active',
      data: {
        maxFileSize: '5MB',
        allowedTypes: ['image/jpeg', 'image/png', 'image/webp', 'image/gif'],
        info: 'Use /auth/avatar endpoints for authenticated avatar management'
      },
    };
  }
}