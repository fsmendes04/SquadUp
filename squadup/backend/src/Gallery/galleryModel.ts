export interface Gallery {
  id: string;
  group_id: string;
  event_name: string;
  location: string;
  date: string;
  images: string[];
  created_at: string;
  updated_at?: string;
}

export interface GalleryWithGroup extends Gallery {
  group_name?: string;
  group_avatar?: string;
}
