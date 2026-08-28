# ZAK_Devs
Repositories for all developments

## SAP UI5 Application

This repository contains a SAP UI5 application located in the `webapp/` folder.

### Project Structure

```
webapp/
├── index.html              # Application entry point
├── manifest.json           # App descriptor
├── Component.js            # UI5 Component
├── controller/
│   ├── App.controller.js   # App controller
│   └── Main.controller.js  # Main view controller
├── view/
│   ├── App.view.xml        # App view
│   └── Main.view.xml       # Main view
└── i18n/
    └── i18n.properties     # Internationalization texts
```

### Getting Started

Open `webapp/index.html` in a web server to run the application, or use the [SAP Fiori tools](https://marketplace.visualstudio.com/items?itemName=SAPSE.sap-ux-fiori-tools-extension-pack) extension with `npm start`.
