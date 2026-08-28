'use strict';

const { executeHttpRequest } = require('@sap-cloud-sdk/http-client');

/**
 * Helper: returns the destination config used by SAP Cloud SDK.
 * In CF, bind an instance of SAP Destination service and configure
 * a destination named RAP_TRAVEL_BACKEND pointing to your S/4HANA system.
 * Locally, set the following env vars in .env:
 *   RAP_BASE_URL  – e.g. https://<s4host>
 *   RAP_USERNAME  – basic auth user
 *   RAP_PASSWORD  – basic auth password
 */
function getDestination() {
  if (process.env.RAP_BASE_URL) {
    return {
      url: process.env.RAP_BASE_URL,
      authentication: 'BasicAuthentication',
      username: process.env.RAP_USERNAME,
      password: process.env.RAP_PASSWORD
    };
  }
  // In CF: resolve by destination name (requires VCAP_SERVICES / Destination service binding)
  return { destinationName: 'RAP_TRAVEL_BACKEND' };
}

const SERVICE_PATH = '/sap/opu/odata4/sap/zui_travel_m_o4/srvd/sap/zui_travel_m_o4/0001';

/**
 * Fetch all travel entities.
 * @returns {Promise<Array>} Array of travel objects.
 */
async function getTravels() {
  const response = await executeHttpRequest(getDestination(), {
    method: 'GET',
    url: `${SERVICE_PATH}/Travel`,
    headers: { Accept: 'application/json' }
  });
  return response.data.value;
}

/**
 * Fetch a single travel entity by UUID.
 * @param {string} travelUuid
 * @returns {Promise<Object>}
 */
async function getTravelById(travelUuid) {
  const response = await executeHttpRequest(getDestination(), {
    method: 'GET',
    url: `${SERVICE_PATH}/Travel(TravelUUID=${encodeURIComponent(travelUuid)})`,
    headers: { Accept: 'application/json' }
  });
  return response.data;
}

/**
 * Create a new travel entity.
 * @param {Object} travelData - fields: AgencyID, CustomerID, BeginDate, EndDate, BookingFee, CurrencyCode, Description
 * @returns {Promise<Object>} The created entity.
 */
async function createTravel(travelData) {
  const csrfToken = await fetchCsrfToken();
  const response = await executeHttpRequest(getDestination(), {
    method: 'POST',
    url: `${SERVICE_PATH}/Travel`,
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'x-csrf-token': csrfToken.token,
      Cookie: csrfToken.cookie
    },
    data: travelData
  });
  return response.data;
}

/**
 * Trigger the acceptTravel action for a given travel UUID.
 * @param {string} travelUuid
 * @returns {Promise<Object>}
 */
async function acceptTravel(travelUuid) {
  const csrfToken = await fetchCsrfToken();
  const response = await executeHttpRequest(getDestination(), {
    method: 'POST',
    url: `${SERVICE_PATH}/Travel(TravelUUID=${encodeURIComponent(travelUuid)})/com.sap.gateway.srvd.zui_travel_m_o4.v0001.acceptTravel`,
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'x-csrf-token': csrfToken.token,
      Cookie: csrfToken.cookie
    },
    data: {}
  });
  return response.data;
}

/**
 * Trigger the rejectTravel action for a given travel UUID.
 * @param {string} travelUuid
 * @returns {Promise<Object>}
 */
async function rejectTravel(travelUuid) {
  const csrfToken = await fetchCsrfToken();
  const response = await executeHttpRequest(getDestination(), {
    method: 'POST',
    url: `${SERVICE_PATH}/Travel(TravelUUID=${encodeURIComponent(travelUuid)})/com.sap.gateway.srvd.zui_travel_m_o4.v0001.rejectTravel`,
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      'x-csrf-token': csrfToken.token,
      Cookie: csrfToken.cookie
    },
    data: {}
  });
  return response.data;
}

/**
 * Fetch a CSRF token required for modifying operations.
 * @returns {Promise<{token: string, cookie: string}>}
 */
async function fetchCsrfToken() {
  const response = await executeHttpRequest(getDestination(), {
    method: 'GET',
    url: `${SERVICE_PATH}/`,
    headers: { 'x-csrf-token': 'Fetch' }
  });
  const token = response.headers['x-csrf-token'];
  const cookie = (response.headers['set-cookie'] || []).join('; ');
  if (!token) {
    throw new Error('Failed to fetch CSRF token from RAP backend');
  }
  return { token, cookie };
}

module.exports = { getTravels, getTravelById, createTravel, acceptTravel, rejectTravel };
