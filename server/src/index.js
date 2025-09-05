import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import dotenv from 'dotenv';
import { nanoid } from 'nanoid';
import jwt from 'jsonwebtoken';

dotenv.config();

const app = express();
app.use(helmet());
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret';

// In-memory OTP store (replace with Redis for production)
const otpStore = new Map(); // sessionId -> { phone, code, exp }

function isE164(phone) {
  return /^\+[1-9]\d{6,14}$/.test(phone);
}

function randomCode() {
  return (Math.floor(Math.random() * 900000) + 100000).toString();
}

app.get('/health', (req, res) => res.json({ ok: true }));

app.post('/auth/send-otp', async (req, res) => {
  try {
    const { phone } = req.body || {};
    if (!phone || !isE164(phone)) {
      return res.status(400).json({ error: 'Invalid phone (E.164 required, e.g., +91xxxxxxxxxx)' });
    }
    const code = randomCode();
    const sessionId = nanoid();
    const exp = Date.now() + 2 * 60 * 1000; // 2 minutes
    otpStore.set(sessionId, { phone, code, exp });

    // TODO: integrate SMS provider (Twilio/msg91/etc.)
    // If provider not set, log for testing
    if (process.env.TWILIO_ACCOUNT_SID) {
      // send via twilio here
      // skipped to keep template minimal
    } else {
      console.log(`[DEV] OTP for ${phone}: ${code} (session ${sessionId})`);
    }

    return res.json({ sessionId, debug: process.env.NODE_ENV === 'production' ? undefined : code });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: 'Server error' });
  }
});

app.post('/auth/verify-otp', async (req, res) => {
  try {
    const { sessionId, code } = req.body || {};
    if (!sessionId || !code) return res.status(400).json({ error: 'Missing sessionId/code' });
    const rec = otpStore.get(sessionId);
    if (!rec) return res.status(400).json({ error: 'Invalid session' });
    if (Date.now() > rec.exp) return res.status(400).json({ error: 'OTP expired' });
    if (rec.code !== code) return res.status(400).json({ error: 'Invalid code' });

    otpStore.delete(sessionId);
    const userId = Buffer.from(rec.phone).toString('base64url');
    const token = jwt.sign({ sub: userId, phone: rec.phone }, JWT_SECRET, { expiresIn: '7d' });
    return res.json({ token, user: { id: userId, phone: rec.phone } });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: 'Server error' });
  }
});

app.listen(PORT, () => {
  console.log(`Auth server listening on http://localhost:${PORT}`);
});

