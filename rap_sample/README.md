# Sample SAP RAP Project — Travel App

This folder contains a complete sample **RESTful Application Programming (RAP)** project for SAP ABAP, plus a **Cloud Foundry (CF) consumer app** that pulls data from the RAP OData V4 service.

---

## Repository Layout

```
rap_sample/
├── src/
│   ├── db/                  ABAP Dictionary objects
│   │   ├── ZTRAVELDB.ddls.asddls       Database table
│   │   └── ZI_TRAVEL_M.ddls.asddls    Root CDS interface view
│   ├── behaviors/           Behavior definitions & handler class
│   │   ├── ZI_TRAVEL_M.bdef.asbdef    Managed behavior definition (with draft)
│   │   └── ZBP_I_TRAVEL_M.clas.abap   Behavior handler (validations, actions, determinations)
│   ├── projections/         OData projection layer
│   │   ├── ZC_TRAVEL_M.ddls.asddls    Projection/consumer view
│   │   └── ZC_TRAVEL_M.bdef.asbdef    Projection behavior definition
│   ├── services/            Service exposure
│   │   ├── ZUI_TRAVEL_M_O4.srvd.asrvd Service definition
│   │   └── ZUI_TRAVEL_M_O4.srvb.asrvb Service binding notes (OData V4 UI)
│   └── extensions/          UI annotations
│       └── ZC_TRAVEL_M.ddlx.asddlx    Metadata extension (Fiori Elements UI)
└── cf_consumer/             Cloud Foundry Node.js consumer app
    ├── src/
    │   └── travelService.js  SAP Cloud SDK wrapper for the RAP OData V4 API
    ├── test/
    │   └── travelService.test.js  Unit tests (Jest)
    ├── server.js             Express REST API
    ├── manifest.yml          CF push manifest
    ├── package.json
    ├── .env.example          Local dev env template
    └── .gitignore
```

---

## ABAP Side — RAP Objects

### What gets deployed to S/4HANA / BTP ABAP

| Object | Type | Purpose |
|---|---|---|
| `ZTRAVELDB` | Database Table | Persists travel data with administrative fields |
| `ZI_TRAVEL_M` | Root CDS View | Interface/BO view — maps table to typed business object |
| `ZI_TRAVEL_M` (bdef) | Behavior Definition | Managed behavior with draft, validations, actions, determinations |
| `ZBP_I_TRAVEL_M` | Behavior Handler Class | ABAP class implementing validations, actions, and determinations |
| `ZC_TRAVEL_M` | Projection CDS View | Consumer/transactional query view exposed via OData |
| `ZC_TRAVEL_M` (bdef) | Projection Behavior | Forwards actions from projection to BO |
| `ZUI_TRAVEL_M_O4` (srvd) | Service Definition | Binds projection view to an OData service |
| `ZUI_TRAVEL_M_O4` (srvb) | Service Binding | OData V4 UI binding — publishes the endpoint |
| `ZC_TRAVEL_M` (ddlx) | Metadata Extension | Fiori Elements UI annotations (list, object page) |

### Deployment Steps (ADT / gCTS)

1. Import the `src/` folder into your ABAP package via **ABAP Development Tools (ADT)** or **gCTS**.
2. Activate all objects in dependency order:
   - `ZTRAVELDB` → `ZI_TRAVEL_M` (view) → behavior + handler → projection + projection bdef → service definition → service binding → metadata extension
3. In the **Service Binding** editor (`ZUI_TRAVEL_M_O4`), click **Publish** to make the endpoint live.
4. The OData V4 endpoint will be available at:
   ```
   /sap/opu/odata4/sap/zui_travel_m_o4/srvd/sap/zui_travel_m_o4/0001/
   ```

### Business Logic Summary

| Feature | Detail |
|---|---|
| **Draft** | Full draft workflow (Edit / Activate / Discard / Resume / Prepare) |
| **Validations** | `validateCustomer` — checks customer exists in `/DMO/CUSTOMER`; `validateDates` — end ≥ begin, begin not in the past; `validateStatus` — status must be O/A/X |
| **Actions** | `acceptTravel` (sets status → A); `rejectTravel` (sets status → X); `copyTravel` (clones record) |
| **Determinations** | `setInitialStatus` — defaults OverallStatus to `O` on create; `calculateTotalPrice` — seeds TotalPrice from BookingFee |

---

## CF Side — Node.js Consumer App

The `cf_consumer/` folder is a **Node.js / Express** app that wraps the RAP OData V4 service and exposes a simple REST API.  It uses the **SAP Cloud SDK** for Node.js to handle destination resolution and CSRF token management automatically.

### REST Endpoints

| Method | Path | Description |
|---|---|---|
| `GET` | `/travels` | List all travel records |
| `GET` | `/travels/:travelUuid` | Get a single travel record |
| `POST` | `/travels` | Create a new travel record |
| `POST` | `/travels/:travelUuid/accept` | Accept a travel (triggers RAP action) |
| `POST` | `/travels/:travelUuid/reject` | Reject a travel (triggers RAP action) |

### Running Locally

```bash
cd cf_consumer
cp .env.example .env
# Edit .env with your S/4HANA credentials
npm install
npm start          # http://localhost:3000
npm test           # run unit tests
```

### Deploying to Cloud Foundry

1. **Create required CF services:**
   ```bash
   cf create-service destination lite travel-destination-service
   cf create-service xsuaa application travel-xsuaa-service
   ```

2. **Create a Destination** in BTP Cockpit or via CLI:
   - Name: `RAP_TRAVEL_BACKEND`
   - URL: `https://<your-s4-system>`
   - Authentication: `BasicAuthentication` (or `OAuth2SAMLBearerAssertion` for SSO)
   - ProxyType: `OnPremise` (if behind Cloud Connector) or `Internet`

3. **Push the app:**
   ```bash
   cd cf_consumer
   cf push
   ```

4. **Call the service:**
   ```bash
   curl https://travel-cf-consumer.<your-cf-domain>/travels
   ```

### Authentication & Security

- In CF, the app resolves the `RAP_TRAVEL_BACKEND` destination from the bound **SAP Destination service**.
- For principal propagation (user identity forwarded to S/4HANA), configure the destination with `OAuth2SAMLBearerAssertion` and bind an XSUAA instance.
- Locally, basic auth credentials are read from `.env` (never commit `.env` to source control).

---

## Key SAP Resources

- [RAP Getting Started (SAP Help)](https://help.sap.com/docs/abap-cloud/abap-rap/restful-abap-programming-model)
- [SAP Cloud SDK for Node.js](https://sap.github.io/cloud-sdk/docs/js/overview)
- [SAP BTP Destination Service](https://help.sap.com/docs/connectivity/sap-btp-connectivity-cf/connectivity-service)
