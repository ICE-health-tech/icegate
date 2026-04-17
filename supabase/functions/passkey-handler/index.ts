import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { 
  generateRegistrationOptions, 
  verifyRegistrationResponse,
  generateAuthenticationOptions,
  verifyAuthenticationResponse,
} from 'https://esm.sh/@simplewebauthn/server@9.0.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

/**
 * Helper to return uniform JSON error responses with CORS headers
 */
const errorResponse = (message: string, status = 400, internalError?: any) => {
  console.error(`[Passkey Error] ${message}`, internalError || '');
  return new Response(JSON.stringify({ error: message }), { 
    status, 
    headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
  });
};

/**
 * Utility to convert Base64/Base64URL strings to Uint8Array safely
 */
function base64ToUint8Array(base64: string): Uint8Array {
  // Convert Base64URL to Base64
  const normalized = base64.replace(/-/g, '+').replace(/_/g, '/');
  // Add padding if missing
  const padding = normalized.length % 4 === 0 ? '' : '='.repeat(4 - (normalized.length % 4));
  const binaryString = atob(normalized + padding);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes;
}

/**
 * Normalizes a base64url string to standard base64 for database lookups
 */
function toStandardBase64(input: string): string {
  const normalized = input.replace(/-/g, '+').replace(/_/g, '/');
  const padding = normalized.length % 4 === 0 ? '' : '='.repeat(4 - (normalized.length % 4));
  return normalized + padding;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const supabase = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
  )

  // Configuration from Environment Variables with defaults
  const RP_ID = Deno.env.get('RP_ID') || 'ice-shield.com'
  const ORIGIN = Deno.env.get('RP_ORIGIN') || `https://${RP_ID}`

  try {
    const body = await req.json()
    const { action, email, data } = body

    if (!email) return errorResponse('Email is required');

    // --- REGISTRATION ---
    if (action === 'get-registration-options') {
      const options = await generateRegistrationOptions({
        rpName: 'Ice Shield',
        rpID: RP_ID,
        userID: crypto.randomUUID(),
        userName: email,
        attestationType: 'none',
        authenticatorSelection: {
          residentKey: 'required',
          userVerification: 'preferred',
        },
      })
      
      const { error: dbError } = await supabase
        .from('webauthn_challenges')
        .insert({
          challenge: options.challenge,
          email: email,
          expires_at: new Date(Date.now() + 5 * 60 * 1000).toISOString(),
        })

      if (dbError) throw dbError
      return new Response(JSON.stringify(options), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    if (action === 'verify-registration') {
      const { data: challengeData, error: challengeError } = await supabase
        .from('webauthn_challenges')
        .select('challenge')
        .eq('email', email)
        .gt('expires_at', new Date().toISOString())
        .order('created_at', { ascending: false })
        .limit(1)
        .single()

      if (challengeError || !challengeData) {
        return errorResponse('Challenge not found or has expired', 400, challengeError);
      }

      const verification = await verifyRegistrationResponse({
        response: data,
        expectedChallenge: challengeData.challenge,
        expectedOrigin: ORIGIN,
        expectedRPID: RP_ID,
      })

      if (verification.verified && verification.registrationInfo) {
        const { credentialPublicKey, credentialID } = verification.registrationInfo

        // Attempt to link to existing Auth user
        const { data: userData } = await supabase.auth.admin.getUserByEmail(email)

        const { error: insertError } = await supabase.from('user_passkeys').insert({
          user_id: userData?.user?.id || null,
          email: email,
          credential_id: toStandardBase64(btoa(String.fromCharCode(...credentialID))),
          public_key: btoa(String.fromCharCode(...credentialPublicKey)),
        })

        if (insertError) throw insertError
        await supabase.from('webauthn_challenges').delete().eq('email', email)
        return new Response(JSON.stringify({ success: true }), { headers: corsHeaders })
      }
      return errorResponse('Registration verification failed', 400, verification);
    }

    // --- AUTHENTICATION (SIGN-IN) ---
    if (action === 'get-authentication-options') {
      const { data: credentials, error: credError } = await supabase
        .from('user_passkeys')
        .select('credential_id')
        .eq('email', email)

      if (credError) throw credError;

      const options = await generateAuthenticationOptions({
        rpID: RP_ID,
        allowCredentials: credentials?.map((c: any) => ({
          id: base64ToUint8Array(c.credential_id),
          type: 'public-key',
        })),
        userVerification: 'preferred',
      })

      await supabase.from('webauthn_challenges').insert({
        challenge: options.challenge,
        email: email,
        expires_at: new Date(Date.now() + 5 * 60 * 1000).toISOString(),
      })

      return new Response(JSON.stringify(options), { headers: { ...corsHeaders, 'Content-Type': 'application/json' } })
    }

    if (action === 'verify-authentication') {
      const { data: challengeData } = await supabase
        .from('webauthn_challenges')
        .select('challenge')
        .eq('email', email)
        .gt('expires_at', new Date().toISOString())
        .order('created_at', { ascending: false })
        .limit(1)
        .single()

      if (!challengeData) return errorResponse('Active challenge not found for this email');

      // Normalize the ID from the client (Base64URL) to match our DB format (Base64)
      const normalizedId = toStandardBase64(data.id);

      const { data: passkey, error: passkeyError } = await supabase
        .from('user_passkeys')
        .select('*')
        .eq('credential_id', normalizedId)
        .single()

      if (passkeyError || !passkey) {
        return errorResponse('Passkey not found in system', 404, passkeyError);
      }

      const verification = await verifyAuthenticationResponse({
        response: data,
        expectedChallenge: challengeData.challenge,
        expectedOrigin: ORIGIN,
        expectedRPID: RP_ID,
        authenticator: {
          credentialID: base64ToUint8Array(passkey.credential_id),
          credentialPublicKey: base64ToUint8Array(passkey.public_key),
          counter: 0,
        },
      })

      if (verification.verified) {
        await supabase.from('webauthn_challenges').delete().eq('email', email)
        return new Response(JSON.stringify({ success: true, verified: true }), { headers: corsHeaders })
      }
      return errorResponse('Security verification failed. Invalid assertion.', 401, verification);
    }

    return errorResponse('Action not supported', 404);
  } catch (error) {
    return errorResponse(error.message, 500, error);
  }
})
