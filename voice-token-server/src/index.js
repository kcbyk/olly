import cors from 'cors';
import express from 'express';
import { AccessToken } from 'livekit-server-sdk';

const requiredVariables = ['LIVEKIT_API_KEY', 'LIVEKIT_API_SECRET'];
const missing = requiredVariables.filter((key) => !process.env[key]);
if (missing.length > 0) {
  throw new Error(`Missing required environment variables: ${missing.join(', ')}`);
}

const app = express();
app.disable('x-powered-by');
app.use(cors({ origin: true }));
app.use(express.json({ limit: '8kb' }));

const safeValue = (value, maxLength) =>
  typeof value === 'string' && value.trim().length > 0 && value.trim().length <= maxLength
    ? value.trim()
    : null;

app.get('/health', (_request, response) => {
  response.json({ ok: true });
});

app.post('/token', async (request, response) => {
  const roomName = safeValue(request.body?.roomName, 128);
  const identity = safeValue(request.body?.identity, 128);
  const name = safeValue(request.body?.name, 128);

  if (!roomName || !identity || !name) {
    return response.status(400).json({ error: 'roomName, identity and name are required.' });
  }

  // Identity and room name must be opaque app identifiers, never email or phone data.
  const token = new AccessToken(
    process.env.LIVEKIT_API_KEY,
    process.env.LIVEKIT_API_SECRET,
    { identity, name, ttl: '1h' },
  );
  token.addGrant({
    room: roomName,
    roomJoin: true,
    canPublish: true,
    canPublishData: true,
    canSubscribe: true,
  });

  return response.json({ token: await token.toJwt() });
});

app.use((_request, response) => response.status(404).json({ error: 'Not found.' }));

const port = Number(process.env.PORT || 3000);
app.listen(port, '0.0.0.0', () => {
  console.log(`Olly token server listening on ${port}`);
});
