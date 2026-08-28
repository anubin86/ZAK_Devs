'use strict';

require('dotenv').config();
const express = require('express');
const { getTravels, getTravelById, createTravel, acceptTravel, rejectTravel } = require('./src/travelService');

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 3000;

/**
 * GET /health
 * Lightweight liveness probe — does not contact the backend.
 */
app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});
/**
 * GET /travels
 * Returns all travel records from the RAP backend.
 */
app.get('/travels', async (req, res) => {
  try {
    const travels = await getTravels();
    res.json(travels);
  } catch (err) {
    console.error('GET /travels failed:', err.message);
    res.status(502).json({ error: err.message });
  }
});

/**
 * GET /travels/:travelUuid
 * Returns a single travel record by its UUID key.
 */
app.get('/travels/:travelUuid', async (req, res) => {
  try {
    const travel = await getTravelById(req.params.travelUuid);
    res.json(travel);
  } catch (err) {
    console.error('GET /travels/:travelUuid failed:', req.params.travelUuid, err.message);
    res.status(502).json({ error: err.message });
  }
});

/**
 * POST /travels
 * Creates a new travel record.
 * Body: { AgencyID, CustomerID, BeginDate, EndDate, BookingFee, CurrencyCode, Description }
 */
app.post('/travels', async (req, res) => {
  try {
    const created = await createTravel(req.body);
    res.status(201).json(created);
  } catch (err) {
    console.error('POST /travels failed:', err.message);
    res.status(502).json({ error: err.message });
  }
});

/**
 * POST /travels/:travelUuid/accept
 * Triggers the acceptTravel action on the RAP backend.
 */
app.post('/travels/:travelUuid/accept', async (req, res) => {
  try {
    const result = await acceptTravel(req.params.travelUuid);
    res.json(result);
  } catch (err) {
    console.error('POST /travels/:travelUuid/accept failed:', req.params.travelUuid, err.message);
    res.status(502).json({ error: err.message });
  }
});

/**
 * POST /travels/:travelUuid/reject
 * Triggers the rejectTravel action on the RAP backend.
 */
app.post('/travels/:travelUuid/reject', async (req, res) => {
  try {
    const result = await rejectTravel(req.params.travelUuid);
    res.json(result);
  } catch (err) {
    console.error('POST /travels/:travelUuid/reject failed:', req.params.travelUuid, err.message);
    res.status(502).json({ error: err.message });
  }
});

app.listen(PORT, () => {
  console.log(`Travel CF consumer listening on port ${PORT}`);
});

module.exports = app;
