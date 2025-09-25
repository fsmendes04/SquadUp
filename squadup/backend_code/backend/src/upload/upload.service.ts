import { Injectable, BadRequestException, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';

@Injectable()
export class UploadService {
  private readonly bucketName = 'avatars';
  private readonly maxFileSize = 5 * 1024 * 1024; // 5MB
  private readonly allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

  constructor(private readonly supabase: SupabaseService) { }

  /**
   * Faz upload de uma imagem de avatar para o Supabase Storage
   */
  async uploadAvatar(userId: string, file: Express.Multer.File): Promise<{ url: string; path: string }> {
    // Validar arquivo
    this.validateFile(file);

    // Criar caminho único para o arquivo - formato simples para RLS
    const fileExtension = this.getFileExtension(file.originalname);
    const fileName = `${userId}_avatar_${Date.now()}${fileExtension}`;

    try {
      // Fazer upload para o Supabase Storage usando cliente administrativo
      const { data, error } = await this.supabase.adminClient.storage
        .from(this.bucketName)
        .upload(fileName, file.buffer, {
          contentType: file.mimetype,
          cacheControl: '3600',
          upsert: false, // Não sobrescrever arquivos existentes
        });

      if (error) {
        console.error('❌ Error uploading to Supabase Storage:', error);
        throw new BadRequestException(`Error uploading file: ${error.message}`);
      }

      console.log('✅ File uploaded successfully:', data.path);

      // Obter URL pública
      const { data: publicUrlData } = this.supabase.adminClient.storage
        .from(this.bucketName)
        .getPublicUrl(data.path);

      return {
        url: publicUrlData.publicUrl,
        path: data.path,
      };
    } catch (error) {
      console.error('❌ Unexpected error uploading file:', error);
      throw new BadRequestException(`Failed to upload file: ${error.message}`);
    }
  }

  /**
   * Obtém a URL pública de um avatar
   */
  async getAvatarUrl(filePath: string): Promise<string> {
    if (!filePath) {
      throw new NotFoundException('Avatar not found');
    }

    const { data } = this.supabase.adminClient.storage
      .from(this.bucketName)
      .getPublicUrl(filePath);

    return data.publicUrl;
  }

  /**
   * Remove um avatar do storage
   */
  async deleteAvatar(filePath: string): Promise<void> {
    if (!filePath) {
      return; // Não há arquivo para deletar
    }

    try {
      const { error } = await this.supabase.adminClient.storage
        .from(this.bucketName)
        .remove([filePath]);

      if (error) {
        console.error('❌ Error deleting file from storage:', error);
        // Não lançar erro aqui, pois o arquivo pode já ter sido deletado
      } else {
        console.log('✅ File deleted successfully:', filePath);
      }
    } catch (error) {
      console.error('❌ Unexpected error deleting file:', error);
      // Log apenas, não impedir a operação
    }
  }

  /**
   * Remove todos os avatares antigos de um usuário (mantém apenas o mais recente)
   */
  async cleanupOldAvatars(userId: string, currentFilePath?: string): Promise<void> {
    try {
      // Listar todos os arquivos do bucket
      const { data: files, error } = await this.supabase.adminClient.storage
        .from(this.bucketName)
        .list('', {
          limit: 1000,
          sortBy: { column: 'created_at', order: 'desc' }
        });

      if (error || !files) {
        console.log('No files to cleanup for user:', userId);
        return;
      }

      // Filtrar apenas os arquivos do usuário atual
      const userFiles = files.filter(file =>
        file.name.startsWith(`${userId}_avatar_`)
      );

      // Filtrar arquivos para deletar (todos exceto o atual)
      const filesToDelete = userFiles
        .filter(file => {
          return currentFilePath ? file.name !== currentFilePath : true;
        })
        .map(file => file.name);

      if (filesToDelete.length > 0) {
        const { error: deleteError } = await this.supabase.adminClient.storage
          .from(this.bucketName)
          .remove(filesToDelete);

        if (deleteError) {
          console.error('❌ Error cleaning up old avatars:', deleteError);
        } else {
          console.log(`✅ Cleaned up ${filesToDelete.length} old avatar(s) for user ${userId}`);
        }
      }
    } catch (error) {
      console.error('❌ Unexpected error cleaning up old avatars:', error);
    }
  }

  /**
   * Valida o arquivo enviado
   */
  private validateFile(file: Express.Multer.File): void {
    if (!file) {
      throw new BadRequestException('No file provided');
    }

    if (file.size > this.maxFileSize) {
      throw new BadRequestException(`File size too large. Maximum size is ${this.maxFileSize / 1024 / 1024}MB`);
    }

    if (!this.allowedMimeTypes.includes(file.mimetype)) {
      throw new BadRequestException(`Invalid file type. Allowed types: ${this.allowedMimeTypes.join(', ')}`);
    }
  }

  /**
   * Extrai a extensão do arquivo
   */
  private getFileExtension(filename: string): string {
    const lastDotIndex = filename.lastIndexOf('.');
    return lastDotIndex !== -1 ? filename.substring(lastDotIndex) : '';
  }
}