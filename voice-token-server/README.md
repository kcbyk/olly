# Olly voice token server

Deploy this folder as a **Render Web Service**. Set these environment variables in Render:

- `LIVEKIT_API_KEY`
- `LIVEKIT_API_SECRET`

Render settings:

- Root directory: `voice-token-server`
- Build command: `npm install`
- Start command: `npm start`

After Render assigns a public URL, add it to the Flutter app's local `.env` file:

```env
VOICE_TOKEN_SERVER_URL=https://your-render-service.onrender.com
```

The app calls `POST /token`. Do not add the LiveKit secret to the Flutter `.env` file or ship it in a mobile build.
