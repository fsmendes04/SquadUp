import { Injectable } from '@nestjs/common';
import { createClient, SupabaseClient, User } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService {
  public readonly client: SupabaseClient;
  private readonly adminClient: SupabaseClient;

  constructor() {
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseAnonKey = process.env.SUPABASE_ANON_KEY; // ✅ Anon key
    const supabaseServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY; // ✅ Admin key

    if (!supabaseUrl || !supabaseAnonKey) {
      throw new Error('SUPABASE_URL and SUPABASE_ANON_KEY must be defined');
    }

    if (!supabaseServiceRoleKey) {
      throw new Error('SUPABASE_SERVICE_ROLE_KEY must be defined');
    }

    this.client = createClient(supabaseUrl, supabaseAnonKey);

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

  getClientWithToken(accessToken: string): SupabaseClient {
    const supabaseUrl = process.env.SUPABASE_URL!;
    const anonKey = process.env.SUPABASE_ANON_KEY!;


    const client = createClient(supabaseUrl, anonKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
        detectSessionInUrl: false,
      },
      global: {
        headers: {
          Authorization: `Bearer ${accessToken}`,
          apikey: anonKey,
        },
      },
    });

    // Set the session explicitly
    client.auth.setSession({
      access_token: accessToken,
      refresh_token: '',
    });

    return client;
  }
}