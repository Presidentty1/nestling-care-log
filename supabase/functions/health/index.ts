import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? ''
    );

    const health = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      version: '1.0.0',
      checks: {} as Record<string, any>
    };

    // Check database connectivity
    try {
      const { data, error } = await supabase
        .from('families')
        .select('count', { count: 'exact', head: true });

      health.checks.database = {
        status: error ? 'unhealthy' : 'healthy',
        message: error ? `Database error: ${error.message}` : 'Database connection successful',
        response_time_ms: Date.now() - Date.parse(health.timestamp)
      };
    } catch (error) {
      health.checks.database = {
        status: 'unhealthy',
        message: `Database check failed: ${error.message}`,
        error: error.message
      };
    }

    // Check authentication
    try {
      const { data, error } = await supabase.auth.getSession();

      health.checks.auth = {
        status: error ? 'unhealthy' : 'healthy',
        message: error ? `Auth error: ${error.message}` : 'Authentication service available'
      };
    } catch (error) {
      health.checks.auth = {
        status: 'unhealthy',
        message: `Auth check failed: ${error.message}`,
        error: error.message
      };
    }

    // Check storage
    try {
      const { data, error } = await supabase.storage.listBuckets();

      health.checks.storage = {
        status: error ? 'unhealthy' : 'healthy',
        message: error ? `Storage error: ${error.message}` : 'Storage service available',
        buckets_count: data?.length ?? 0
      };
    } catch (error) {
      health.checks.storage = {
        status: 'unhealthy',
        message: `Storage check failed: ${error.message}`,
        error: error.message
      };
    }

    // Determine overall health
    const allHealthy = Object.values(health.checks).every(check => check.status === 'healthy');
    health.status = allHealthy ? 'healthy' : 'degraded';

    const statusCode = allHealthy ? 200 : 503; // 503 Service Unavailable for degraded health

    return new Response(
      JSON.stringify(health, null, 2),
      {
        status: statusCode,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      }
    );

  } catch (error) {
    return new Response(
      JSON.stringify({
        status: 'unhealthy',
        timestamp: new Date().toISOString(),
        error: error.message,
        message: 'Health check failed completely'
      }),
      {
        status: 503,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json'
        }
      }
    );
  }
});