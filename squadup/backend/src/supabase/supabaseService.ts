import { Injectable } from '@nestjs/common';
import { createClient, SupabaseClient, User } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService {
  public readonly client: SupabaseClient;
  private readonly adminClient: SupabaseClient;

  constructor() {
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_KEY;
    const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!supabaseUrl || !supabaseKey) {
      throw new Error('SUPABASE_URL and SUPABASE_KEY must be defined in environment variables');
    }

    if (!supabaseServiceRoleKey) {
      throw new Error('SUPABASE_SERVICE_ROLE_KEY must be defined in environment variables');
    }

    this.client = createClient(supabaseUrl, supabaseKey);
    this.adminClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    });
  }

  getClient(): SupabaseClient {
    return this.client;
  }

  getAdminClient(): SupabaseClient {
    return this.adminClient;
  }

  async adminGetUserById(userId: string) {
    const { data, error } = await this.adminClient.auth.admin.getUserById(userId);
    if (error) throw error;
    return data;
  }

  async adminDeleteUser(userId: string) {
    const { data, error } = await this.adminClient.auth.admin.deleteUser(userId);
    if (error) throw error;
    return data;
  }

  async verifyToken(token: string): Promise<User> {
    const { data: { user }, error } = await this.client.auth.getUser(token);
    if (error || !user) throw error || new Error('User not found');
    return user;
  }
}