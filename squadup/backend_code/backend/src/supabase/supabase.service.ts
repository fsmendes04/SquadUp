import { Injectable } from '@nestjs/common';
import { createClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService {
  public client;
  public adminClient;

  constructor() {
    const supabaseUrl = process.env.SUPABASE_URL;
    const supabaseKey = process.env.SUPABASE_KEY;
    const supabaseServiceRole = process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!supabaseUrl || !supabaseKey) {
      throw new Error('SUPABASE_URL and SUPABASE_KEY must be defined in environment variables');
    }

    // Cliente regular (anon key)
    this.client = createClient(supabaseUrl, supabaseKey);

    // Cliente administrativo (service role key) - para operações que precisam de permissões especiais
    if (supabaseServiceRole) {
      this.adminClient = createClient(supabaseUrl, supabaseServiceRole, {
        auth: {
          autoRefreshToken: false,
          persistSession: false
        }
      });
    } else {
      console.warn('⚠️  SUPABASE_SERVICE_ROLE_KEY not defined. Some operations may fail due to RLS policies.');
      this.adminClient = this.client; // Fallback para o cliente regular
    }
  }
}