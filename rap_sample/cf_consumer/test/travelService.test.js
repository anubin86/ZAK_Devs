'use strict';

// Mock the SAP Cloud SDK so unit tests don't need a real backend
jest.mock('@sap-cloud-sdk/http-client', () => ({
  executeHttpRequest: jest.fn()
}));

const { executeHttpRequest } = require('@sap-cloud-sdk/http-client');
const { getTravels, getTravelById, createTravel, acceptTravel, rejectTravel } = require('../src/travelService');

const MOCK_TOKEN_RESPONSE = {
  headers: { 'x-csrf-token': 'mock-token', 'set-cookie': ['session=abc'] },
  data: {}
};

const MOCK_TRAVEL = {
  TravelUUID: 'AAAABBBBCCCCDDDD',
  TravelID: '00000001',
  AgencyID: '70001',
  CustomerID: '00001',
  BeginDate: '2024-07-01',
  EndDate: '2024-07-15',
  BookingFee: '20.00',
  TotalPrice: '20.00',
  CurrencyCode: 'EUR',
  Description: 'Test travel',
  OverallStatus: 'O'
};

beforeEach(() => {
  jest.clearAllMocks();
});

describe('getTravels', () => {
  it('returns an array of travel records', async () => {
    executeHttpRequest.mockResolvedValueOnce({ data: { value: [MOCK_TRAVEL] } });
    const result = await getTravels();
    expect(result).toEqual([MOCK_TRAVEL]);
    expect(executeHttpRequest).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ method: 'GET', url: expect.stringContaining('/Travel') })
    );
  });
});

describe('getTravelById', () => {
  it('returns a single travel record', async () => {
    executeHttpRequest.mockResolvedValueOnce({ data: MOCK_TRAVEL });
    const result = await getTravelById('AAAABBBBCCCCDDDD');
    expect(result).toEqual(MOCK_TRAVEL);
    expect(executeHttpRequest).toHaveBeenCalledWith(
      expect.anything(),
      expect.objectContaining({ method: 'GET', url: expect.stringContaining('AAAABBBBCCCCDDDD') })
    );
  });
});

describe('createTravel', () => {
  it('posts new travel and returns created entity', async () => {
    executeHttpRequest
      .mockResolvedValueOnce(MOCK_TOKEN_RESPONSE) // CSRF fetch
      .mockResolvedValueOnce({ data: MOCK_TRAVEL }); // POST
    const result = await createTravel({ AgencyID: '70001', CustomerID: '00001' });
    expect(result).toEqual(MOCK_TRAVEL);
    expect(executeHttpRequest).toHaveBeenCalledTimes(2);
  });
});

describe('acceptTravel', () => {
  it('triggers acceptTravel action', async () => {
    executeHttpRequest
      .mockResolvedValueOnce(MOCK_TOKEN_RESPONSE)
      .mockResolvedValueOnce({ data: { ...MOCK_TRAVEL, OverallStatus: 'A' } });
    const result = await acceptTravel('AAAABBBBCCCCDDDD');
    expect(result.OverallStatus).toBe('A');
  });
});

describe('rejectTravel', () => {
  it('triggers rejectTravel action', async () => {
    executeHttpRequest
      .mockResolvedValueOnce(MOCK_TOKEN_RESPONSE)
      .mockResolvedValueOnce({ data: { ...MOCK_TRAVEL, OverallStatus: 'X' } });
    const result = await rejectTravel('AAAABBBBCCCCDDDD');
    expect(result.OverallStatus).toBe('X');
  });
});
