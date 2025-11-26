import { Module } from '@nestjs/common';
import { GalleryController } from './galleryController';
import { GalleryService } from './galleryService';
import { SupabaseService } from '../Supabase/supabaseService';
import { UserModule } from '../User/user.module';
import { GroupsModule } from '../Groups/groups.module';

@Module({
  imports: [UserModule, GroupsModule],
  controllers: [GalleryController],
  providers: [GalleryService, SupabaseService],
  exports: [GalleryService],
})
export class GalleryModule { }