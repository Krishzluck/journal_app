import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from "https://esm.sh/@supabase/supabase-js";
import { encode } from "https://deno.land/std@0.168.0/encoding/base64.ts";
import { crypto } from "https://deno.land/std@0.168.0/crypto/mod.ts";
import { JWT } from 'npm:google-auth-library@9'
import serviceAccount from '../send-notification/journal-app-d8161-firebase-adminsdk-fbsvc-61ec93e833.json' with { type: 'json' }

const GOOGLE_APPLICATION_CREDENTIALS = Deno.env.get('GOOGLE_APPLICATION_CREDENTIALS');
const PROJECT_ID = Deno.env.get('FIREBASE_PROJECT_ID');
const SUPABASE_URL = Deno.env.get('SUPABASE_URL');
const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// Helper function to convert PEM to DER
// function pemToDer(pem: string): Uint8Array {
//   const pemContents = pem
//     .replace(/-----BEGIN PRIVATE KEY-----/, '')
//     .replace(/-----END PRIVATE KEY-----/, '')
//     .replace(/\s+/g, ''); // Remove all whitespace

//   return new Uint8Array(
//     atob(pemContents)
//     .split('')
//     .map((c) => c.charCodeAt(0))
//   );
// }

// async function createJWT(credentials: any) {
//   const header = {
//     alg: "RS256",
//     typ: "JWT",
//   };

//   const now = Math.floor(Date.now() / 1000);
//   const payload = {
//     iss: credentials.client_email,
//     scope: "https://www.googleapis.com/auth/firebase.messaging",
//     aud: "https://oauth2.googleapis.com/token",
//     exp: now + 3600,
//     iat: now,
//   };

//   const encodedHeader = encode(JSON.stringify(header));
//   const encodedPayload = encode(JSON.stringify(payload));

//   const data = `${encodedHeader}.${encodedPayload}`;

//   // Convert PEM to DER
//   const derKey = pemToDer(credentials.private_key);

//   // Import the key
//   const key = await crypto.subtle.importKey(
//     "pkcs8",
//     derKey,
//     { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
//     false,
//     ["sign"]
//   );

//   // Sign the JWT
//   const signature = await crypto.subtle.sign(
//     { name: "RSASSA-PKCS1-v1_5" },
//     key,
//     new TextEncoder().encode(data)
//   );

//   const encodedSignature = encode(new Uint8Array(signature));
//   return `${data}.${encodedSignature}`;
// }

// async function getAccessToken() {
//   const credentials = JSON.parse(GOOGLE_APPLICATION_CREDENTIALS!);
//   const jwt = await createJWT(credentials);
//   const response = await fetch(
//     'https://oauth2.googleapis.com/token',
//     {
//       method: 'POST',
//       headers: {
//         'Content-Type': 'application/x-www-form-urlencoded',
//       },
//       body: new URLSearchParams({
//         grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
//         assertion: jwt,
//       }),
//     }
//   );
//   const { access_token } = await response.json();
//   return access_token;
// }

const getAccessToken = ({
  clientEmail,
  privateKey,
}: {
  clientEmail: string
  privateKey: string
}): Promise<string> => {
  return new Promise((resolve, reject) => {
    const jwtClient = new JWT({
      email: clientEmail,
      key: privateKey,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    })
    jwtClient.authorize((err, tokens) => {
      if (err) {
        reject(err)
        return
      }
      resolve(tokens!.access_token!)
    })
  })
}

async function sendFCM(tokens: string[], title: string, body: string, data: any) {
  // const accessToken = await getAccessToken();
  const accessToken = await getAccessToken({
    clientEmail: serviceAccount.client_email,
    privateKey: serviceAccount.private_key,
  })

  const message = {
    message: {
      token: tokens[0], // Send to single device
      notification: {
        "title": title,
        "body": body,
      },
      "data": data,
    },
  };

  console.log(message);

  const response = await fetch(
    `https://fcm.googleapis.com/v1/projects/${PROJECT_ID}/messages:send`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(message),
    }
  );
  return response.json();
}

serve(async (req) => {
  const { type, userId, referenceId, actorName } = await req.json();

  // Get user's device tokens
  const { data: tokens } = await supabase
    .from('device_tokens')
    .select('device_token')
    .eq('user_id', userId);

  const deviceTokens = tokens.map(t => t.device_token);

  let title, body, data;

  switch (type) {
    case 'comment':
      title = 'New Comment';
      body = `@${actorName} commented on your post`;
      data = { type, reference_id: referenceId };
      break;
    case 'new_journal':
      title = 'New Journal';
      body = `@${actorName} created a new journal`;
      data = { type, reference_id: referenceId };
      break;
    case 'follow':
      title = 'New Follower';
      body = `@${actorName} followed you`;
      data = { type, reference_id: referenceId };
      break;
    case 'month_mood':
      title = 'Monthly Mood Check';
      body = 'Check your mood summary for this month!';
      data = { type };
      break;
  }

  const result = await sendFCM(deviceTokens, title, body, data);
  return new Response(JSON.stringify(result), { headers: { 'Content-Type': 'application/json' } });
});