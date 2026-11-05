const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

function copyDirSync(src, dest) {
  if (!fs.existsSync(dest)) {
    fs.mkdirSync(dest, { recursive: true });
  }
  const entries = fs.readdirSync(src, { withFileTypes: true });
  for (const entry of entries) {
    const srcPath = path.join(src, entry.name);
    const destPath = path.join(dest, entry.name);
    if (entry.isDirectory()) {
      copyDirSync(srcPath, destPath);
    } else {
      fs.copyFileSync(srcPath, destPath);
    }
  }
}

async function buildWebOS() {
  console.log('=== Building PrismTV for LG webOS TV ===');

  const rootDir = path.resolve(__dirname, '..');
  const webBuildDir = path.join(rootDir, 'build', 'web');
  const webosPkgDir = path.join(rootDir, 'build', 'webos_pkg');
  const distDir = path.join(rootDir, 'dist');
  const webosSrcDir = path.join(rootDir, 'webos');

  // 1. Ensure Flutter Web build exists
  if (!fs.existsSync(path.join(webBuildDir, 'index.html')) || !fs.existsSync(path.join(webBuildDir, 'main.dart.js'))) {
    console.log('[1/4] Running flutter build web --release...');
    execSync('flutter build web --release', { stdio: 'inherit', cwd: rootDir });
  } else {
    console.log('[1/4] Found existing Flutter web release build in build/web.');
  }

  // 2. Prepare webOS staging directory
  console.log('[2/4] Preparing webOS staging package in build/webos_pkg...');
  if (fs.existsSync(webosPkgDir)) {
    fs.rmSync(webosPkgDir, { recursive: true, force: true });
  }
  copyDirSync(webBuildDir, webosPkgDir);

  // 3. Inject webOS manifest and assets
  console.log('[3/4] Copying appinfo.json and webOS TV assets...');
  fs.copyFileSync(path.join(webosSrcDir, 'appinfo.json'), path.join(webosPkgDir, 'appinfo.json'));
  fs.copyFileSync(path.join(webosSrcDir, 'icon.png'), path.join(webosPkgDir, 'icon.png'));
  fs.copyFileSync(path.join(webosSrcDir, 'largeIcon.png'), path.join(webosPkgDir, 'largeIcon.png'));
  fs.copyFileSync(path.join(webosSrcDir, 'splash.png'), path.join(webosPkgDir, 'splash.png'));

  // Ensure base href is relative in staging index.html for local webOS file:// execution
  const indexPath = path.join(webosPkgDir, 'index.html');
  let indexHtml = fs.readFileSync(indexPath, 'utf8');
  indexHtml = indexHtml.replace(/<base href="[^"]*">/, '<base href="./">');
  fs.writeFileSync(indexPath, indexHtml, 'utf8');

  // 4. Package .ipk using ares-package
  console.log('[4/4] Packaging .ipk via ares-package...');
  if (!fs.existsSync(distDir)) {
    fs.mkdirSync(distDir, { recursive: true });
  }

  execSync(`ares-package -n "${webosPkgDir}" -o "${distDir}"`, { stdio: 'inherit', cwd: rootDir });

  // Standardize filename to match other platforms: PrismTV-webOS.ipk
  const generatedIpk = fs.readdirSync(distDir).find(f => f.startsWith('com.thegandabherunda.prismtv') && f.endsWith('.ipk'));
  if (generatedIpk) {
    const standardIpkPath = path.join(distDir, 'PrismTV-webOS.ipk');
    fs.copyFileSync(path.join(distDir, generatedIpk), standardIpkPath);
    console.log(`Created standardized package: PrismTV-webOS.ipk`);
  }

  const ipkFiles = fs.readdirSync(distDir).filter(f => f.endsWith('.ipk'));
  console.log('\n==================================================');
  console.log('  SUCCESSFULLY GENERATED LG webOS TV PACKAGE');
  console.log('==================================================');
  ipkFiles.forEach(f => {
    const fPath = path.join(distDir, f);
    const stats = fs.statSync(fPath);
    console.log(`Package: ${f} (${(stats.size / 1024 / 1024).toFixed(2)} MB)`);
    console.log(`Location: ${fPath}`);
  });
  console.log('==================================================\n');
}

buildWebOS().catch(err => {
  console.error('[BUILD ERROR]', err);
  process.exit(1);
});
