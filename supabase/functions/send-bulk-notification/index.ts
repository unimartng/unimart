import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface BulkNotificationRequest {
  user_ids: string[]
  title: string
  body: string
  data?: Record<string, any>
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    // Parse request body
    const { user_ids, title, body, data = {} }: BulkNotificationRequest = await req.json()

    if (!user_ids || !Array.isArray(user_ids) || user_ids.length === 0 || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: user_ids (array), title, body' }),
        { 
          status: 400, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Get FCM tokens for all users
    const { data: tokenData, error: tokenError } = await supabaseClient
      .from('user_tokens')
      .select('user_id, fcm_token, platform')
      .in('user_id', user_ids)

    if (tokenError) {
      return new Response(
        JSON.stringify({ error: 'Failed to fetch FCM tokens' }),
        { 
          status: 500, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    if (!tokenData || tokenData.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No FCM tokens found for the specified users' }),
        { 
          status: 404, 
          headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
        }
      )
    }

    // Send notifications to all users
    const results = await Promise.allSettled(
      tokenData.map(async (token) => {
        try {
          const fcmResponse = await fetch('https://fcm.googleapis.com/fcm/send', {
            method: 'POST',
            headers: {
              'Authorization': `key=${Deno.env.get('FCM_SERVER_KEY')}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              to: token.fcm_token,
              notification: {
                title,
                body,
                sound: 'default',
              },
              data: {
                ...data,
                type: data.type || 'general',
                timestamp: new Date().toISOString(),
              },
              android: {
                priority: 'high',
                notification: {
                  sound: 'default',
                  priority: 'high',
                },
              },
              apns: {
                payload: {
                  aps: {
                    sound: 'default',
                    badge: 1,
                  },
                },
              },
            }),
          })

          if (!fcmResponse.ok) {
            const errorText = await fcmResponse.text()
            console.error(`FCM Error for user ${token.user_id}:`, errorText)
            return { user_id: token.user_id, success: false, error: errorText }
          }

          return { user_id: token.user_id, success: true, response: await fcmResponse.json() }
        } catch (error) {
          console.error(`Error sending notification to user ${token.user_id}:`, error)
          return { user_id: token.user_id, success: false, error: error.message }
        }
      })
    )

    // Store notifications in database
    const notifications = tokenData.map(token => ({
      user_id: token.user_id,
      title,
      body,
      data,
      type: data.type || 'general',
    }))

    const { error: dbError } = await supabaseClient
      .from('notifications')
      .insert(notifications)

    if (dbError) {
      console.error('Database Error:', dbError)
      // Don't fail the request if we can't store the notifications
    }

    // Process results
    const successful = results.filter(r => r.status === 'fulfilled' && r.value.success).length
    const failed = results.length - successful

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: `Bulk notification sent: ${successful} successful, ${failed} failed`,
        results: results.map(r => r.status === 'fulfilled' ? r.value : { success: false, error: 'Promise rejected' }),
        summary: {
          total: results.length,
          successful,
          failed
        }
      }),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      { 
        status: 500, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )
  }
})
