// scripts/web_smoke_test.mjs

import { chromium } from 'playwright';

const url = process.argv[2];
if (!url) {
  console.error('Uso: node web_smoke_test.mjs <url>');
  process.exit(2);
}

const expectFailure = process.env.EXPECT_FAILURE === 'true';
const timeoutMs = Number(process.env.SMOKE_TIMEOUT_MS ?? 45000);

const consoleErrors = [];
const pageErrors = [];

const browser = await chromium.launch();
const page = await browser.newPage();

page.on('console', (msg) => {
  if (msg.type() === 'error') {
    consoleErrors.push(msg.text());
  }
});

page.on('pageerror', (err) => {
  pageErrors.push(err.message);
});

await page.addInitScript(() => {
  window.__flutterFirstFrameSeen = false;
  window.addEventListener('flutter-first-frame', () => {
    window.__flutterFirstFrameSeen = true;
  });
});

let firstFrameReached = false;
try {
  await page.goto(url, { waitUntil: 'networkidle', timeout: timeoutMs });
  await page.waitForFunction(() => window.__flutterFirstFrameSeen === true, {
    timeout: timeoutMs,
  });
  firstFrameReached = true;
} catch (_err) {
  firstFrameReached = false;
}

await browser.close();

const hasErrors = consoleErrors.length > 0 || pageErrors.length > 0;
const bootedCleanly = firstFrameReached && !hasErrors;

console.log(`flutter-first-frame recibido: ${firstFrameReached}`);
console.log(`Errores de consola: ${consoleErrors.length}`);
consoleErrors.forEach((e) => console.log(`  [console] ${e}`));
console.log(`Excepciones de página (uncaught): ${pageErrors.length}`);
pageErrors.forEach((e) => console.log(`  [pageerror] ${e}`));

if (expectFailure) {
  const hasHttpsGuardError = pageErrors.some((e) =>
    e.includes('API_BASE_URL must use HTTPS')
  );

  if (bootedCleanly) {
    console.error(
      '\nFALLO: se esperaba que la app NO arrancara con una API_BASE_URL ' +
        'HTTP en release (guard de AppEnv.apiBaseUrl), pero arrancó limpia. ' +
        'El guard se rompió, se removió, o dejó de ejecutarse en el flujo ' +
        'de arranque. Esto debe tratarse como una regresión de seguridad.'
    );
    process.exit(1);
  }

  if (!hasHttpsGuardError) {
    console.error(
      '\nFALLO: la app falló al arrancar, pero NO debido al guard de HTTPS ' +
        'esperado ("API_BASE_URL must use HTTPS"). Ocurrió un error no relacionado.'
    );
    process.exit(1);
  }

  console.log(
    '\nOK: la app falló al arrancar debido al guard de HTTPS, ' +
      'tal como se esperaba.'
  );
  process.exit(0);
} else {
  if (!bootedCleanly) {
    console.error('\nFALLO: el artefacto Web no arrancó limpio.');
    process.exit(1);
  }
  console.log('\nOK: el artefacto Web arrancó sin errores de consola/página.');
  process.exit(0);
}